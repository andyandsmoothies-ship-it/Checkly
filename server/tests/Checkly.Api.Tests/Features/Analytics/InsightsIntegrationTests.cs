using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// Integration tests for the Insights + RadarData fields on GET /api/analytics (Slice 2, TDD RED phase).
/// Tests: IG-01, IG-04, IG-05, IG-06, IG-07.
/// Workflow: /tdd
///
/// Test Plan:
///   - IG-01: Store with 2 audits → 1 "info" insight, RadarData=null, InsightsStale=false
///   - IG-04: Stale benchmark (LastCalculatedAt=3h ago) → InsightsStale=true
///   - IG-05: No AreaBenchmarkSnapshot row → insights=[], radarData=null, insightsStale=false
///   - IG-06: Full benchmark exists → RadarData.StoreAverages and AreaAverages both populated
///   - IG-07: Existing kpis, trend, sectionBreakdown still present (backward compat)
/// 
/// All fail in RED because AnalyticsResponse does not yet have Insights/RadarData/InsightsStale fields.
/// </summary>
public class InsightsIntegrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public InsightsIntegrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ─── Seed Helpers ─────────────────────────────────────────────────────────

    /// <summary>
    /// Seeds:
    ///   Store → N Submissions (last 30d) → SubmissionSectionScores → StoreAnalyticsSnapshot → AreaBenchmarkSnapshot
    /// Returns the seeded storeId.
    /// </summary>
    private async Task<(Guid _, Guid StoreId)> SeedFullScenarioAsync(
        int submissionCount,
        double storeAvgScore,
        double areaAvgScore,
        double stdDev,
        int totalAuditCount,
        DateTimeOffset benchmarkCalculatedAt,
        string categoryName = "Safety",
        double storeCategoryScore = 60.0,
        double areaCategoryScore = 80.0)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = $"Test Store {storeId:N}",
            Address2 = new StoreAddress { Province = $"Test Province {storeId:N}" },
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Submissions
        for (int i = 0; i < submissionCount; i++)
        {
            db.Submissions.Add(new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = storeId,
                Status = "completed",
                TotalScore = (decimal)storeAvgScore,
                CreatedAt = DateTimeOffset.UtcNow.AddDays(-i),
                UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        // StoreAnalyticsSnapshot (drives KPI avgScore)
        db.StoreAnalyticsSnapshots.Add(new StoreAnalyticsSnapshot
        {
            StoreId = storeId,
            AvgScore30d = (decimal)storeAvgScore,
            TotalAudits30d = submissionCount,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // AreaBenchmarkSnapshot
        var categoryAveragesJson = System.Text.Json.JsonSerializer.Serialize(
            new Dictionary<string, double> { [categoryName] = areaCategoryScore });

        db.ProvinceBenchmarkSnapshots.Add(new ProvinceBenchmarkSnapshot
        {
            Province = $"Test Province {storeId:N}",
            OverallAvgScore = (decimal)areaAvgScore,
            StdDeviation = (decimal)stdDev,
            TotalAuditCount = totalAuditCount,
            CategoryAverages = categoryAveragesJson,
            LastCalculatedAt = benchmarkCalculatedAt,
            CreatedAt = DateTimeOffset.UtcNow
        });

        // SubmissionSectionScore — drives RadarData StoreAverages
        var submissionId = db.Submissions.Local
            .FirstOrDefault(s => s.StoreId == storeId)?.Id ?? Guid.NewGuid();
        db.SubmissionSectionScores.Add(new SubmissionSectionScore
        {
            Id = Guid.NewGuid(),
            SubmissionId = submissionId,
            StoreId = storeId,
            SectionTitle = categoryName,
            Score = (decimal)storeCategoryScore,
            MaxScore = 100m,
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        return (Guid.Empty, storeId);
    }

    private async Task<HttpClient> CreateStoreManagerClientAsync(Guid storeId)
    {
        var client = _factory.CreateClient();
        var email = $"sm-{Guid.NewGuid():N}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Sm12345!@", "Test SM", "store_manager");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null)
        {
            profile.StoreId = storeId;
            await db.SaveChangesAsync();
        }

        return _factory.CreateAuthenticatedClient(token);
    }

    // ─── IG-01: Sparse store (< 3 audits) ─────────────────────────────────────
    [Fact]
    public async Task GetAnalytics_SparseStore_ReturnsSingleInfoInsightAndNullRadarData()
    {
        // Arrange — 2 submissions, benchmark exists but totalAuditCount=2 (below threshold)
        var (_, storeId) = await SeedFullScenarioAsync(
            submissionCount: 2,
            storeAvgScore: 75.0,
            areaAvgScore: 80.0,
            stdDev: 10.0,
            totalAuditCount: 10,
            benchmarkCalculatedAt: DateTimeOffset.UtcNow);

        var client = await CreateStoreManagerClientAsync(storeId);

        // Act
        var response = await client.GetAsync("/api/analytics");

        // Assert
        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // IG-01: Must have exactly 1 "info" insight
        var insights = body.GetProperty("insights");
        Assert.Equal(JsonValueKind.Array, insights.ValueKind);
        Assert.Equal(1, insights.GetArrayLength());
        Assert.Equal("info", insights[0].GetProperty("type").GetString());

        // IG-01: RadarData must be null
        Assert.True(
            body.GetProperty("radarData").ValueKind == JsonValueKind.Null,
            "Expected radarData to be null for sparse store"
        );

        // IG-01: InsightsStale=false (fresh benchmark)
        Assert.False(body.GetProperty("insightsStale").GetBoolean());
    }

    // ─── IG-04: Stale benchmark ────────────────────────────────────────────────
    [Fact]
    public async Task GetAnalytics_StaleBenchmark_ReturnsInsightsStaleTrue()
    {
        // Arrange — benchmark calculated 3 hours ago (threshold is 2h)
        var (_, storeId) = await SeedFullScenarioAsync(
            submissionCount: 5,
            storeAvgScore: 55.0,
            areaAvgScore: 80.0,
            stdDev: 10.0,
            totalAuditCount: 8,
            benchmarkCalculatedAt: DateTimeOffset.UtcNow.AddHours(-3));

        var client = await CreateStoreManagerClientAsync(storeId);

        // Act
        var response = await client.GetAsync("/api/analytics");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // IG-04: InsightsStale must be true
        Assert.True(
            body.GetProperty("insightsStale").GetBoolean(),
            "Expected insightsStale=true when benchmark is 3h old"
        );
    }

    // ─── IG-05: No benchmark row ───────────────────────────────────────────────
    [Fact]
    public async Task GetAnalytics_NoBenchmarkRow_ReturnsEmptyInsightsAndNullRadarData()
    {
        // Arrange — store with audits but NO AreaBenchmarkSnapshot
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store { Id = storeId, Name = $"No-Bench Store {storeId:N}", Address2 = new StoreAddress { Province = $"No-Bench Province {storeId:N}" }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        for (int i = 0; i < 5; i++)
        {
            db.Submissions.Add(new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = storeId,
                Status = "completed",
                TotalScore = 75m,
                CreatedAt = DateTimeOffset.UtcNow.AddDays(-i),
                UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        await db.SaveChangesAsync();

        var client = await CreateStoreManagerClientAsync(storeId);

        // Act
        var response = await client.GetAsync("/api/analytics");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // IG-05: insights must be null
        var insights = body.GetProperty("insights");
        Assert.Equal(JsonValueKind.Null, insights.ValueKind);

        // IG-05: radarData must be null
        Assert.True(
            body.GetProperty("radarData").ValueKind == JsonValueKind.Null,
            "Expected radarData to be null when no benchmark exists"
        );

        // IG-05: insightsStale = false (no benchmark → not stale, just missing)
        Assert.False(body.GetProperty("insightsStale").GetBoolean());
    }

    // ─── IG-06: RadarData populated ────────────────────────────────────────────
    [Fact]
    public async Task GetAnalytics_FullBenchmarkExists_ReturnsPopulatedRadarData()
    {
        // Arrange — full benchmark with 3 categories so RadarData is not suppressed
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store { Id = storeId, Name = $"Radar Store {storeId:N}", Address2 = new StoreAddress { Province = $"Radar Province {storeId:N}" }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        // 5 submissions
        var subIds = new List<Guid>();
        for (int i = 0; i < 5; i++)
        {
            var subId = Guid.NewGuid();
            subIds.Add(subId);
            db.Submissions.Add(new Submission
            {
                Id = subId,
                StoreId = storeId,
                Status = "completed",
                TotalScore = 75m,
                CreatedAt = DateTimeOffset.UtcNow.AddDays(-i),
                UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        // Section scores for 3 categories (so RadarData is NOT suppressed)
        var categories = new[] { ("Safety", 60.0), ("Hygiene", 70.0), ("Service", 80.0) };
        foreach (var (cat, score) in categories)
        {
            db.SubmissionSectionScores.Add(new SubmissionSectionScore
            {
                Id = Guid.NewGuid(),
                SubmissionId = subIds[0],
                StoreId = storeId,
                SectionTitle = cat,
                Score = (decimal)score,
                MaxScore = 100m,
                CreatedAt = DateTimeOffset.UtcNow
            });
        }

        db.StoreAnalyticsSnapshots.Add(new StoreAnalyticsSnapshot
        {
            StoreId = storeId,
            AvgScore30d = 75m,
            TotalAudits30d = 5,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var areaCategoryAverages = JsonSerializer.Serialize(new Dictionary<string, double>
        {
            ["Safety"] = 80.0,
            ["Hygiene"] = 78.0,
            ["Service"] = 85.0
        });

        db.ProvinceBenchmarkSnapshots.Add(new ProvinceBenchmarkSnapshot
        {
            Province = $"Radar Province {storeId:N}",
            OverallAvgScore = 80m,
            StdDeviation = 10m,
            TotalAuditCount = 12,
            CategoryAverages = areaCategoryAverages,
            LastCalculatedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var client = await CreateStoreManagerClientAsync(storeId);

        // Act
        var response = await client.GetAsync("/api/analytics");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // IG-06: radarData must be populated
        var radarData = body.GetProperty("radarData");
        Assert.NotEqual(JsonValueKind.Null, radarData.ValueKind);

        var categoriesArray = radarData.GetProperty("categories");
        var storeScores = radarData.GetProperty("storeScores");
        var areaScores = radarData.GetProperty("areaScores");

        Assert.True(categoriesArray.EnumerateArray().Any(), "categories must not be empty");
        Assert.True(storeScores.EnumerateArray().Any(), "storeScores must not be empty");
        Assert.True(areaScores.EnumerateArray().Any(), "areaScores must not be empty");
    }

    // ─── IG-07: Backward compatibility ────────────────────────────────────────
    [Fact]
    public async Task GetAnalytics_AfterSlice2Extension_StillReturnsKpisTrendSectionBreakdown()
    {
        // Arrange — use admin client (no store scope needed for backward compat check)
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.GetAsync("/api/analytics");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // IG-07: All pre-Slice-2 fields must still be present
        Assert.True(body.TryGetProperty("kpis", out var kpis), "kpis field must be present");
        Assert.True(body.TryGetProperty("trend", out var trend), "trend field must be present");
        Assert.True(body.TryGetProperty("sectionBreakdown", out var sectionBreakdown), "sectionBreakdown field must be present");

        Assert.Equal(JsonValueKind.Object, kpis.ValueKind);
        Assert.Equal(JsonValueKind.Array, trend.ValueKind);
        Assert.Equal(JsonValueKind.Array, sectionBreakdown.ValueKind);

        // Also confirm the new fields exist (IG-07 proves backward compat, not regression)
        Assert.True(body.TryGetProperty("insights", out _), "insights field must be present after Slice 2");
        Assert.True(body.TryGetProperty("insightsStale", out _), "insightsStale field must be present after Slice 2");
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }
}
