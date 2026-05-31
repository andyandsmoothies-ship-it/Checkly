using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// ATDD RED tests for Scoring Redesign - Slice 5 (Analytics Dashboard Filter).
/// Workflow: /atdd (SDET Execution)
/// </summary>
public class ScoringRedesignSlice5Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ScoringRedesignSlice5Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task SeedTestDataAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Clear existing submissions to prevent analytics pollution
        db.Submissions.RemoveRange(db.Submissions);
        await db.SaveChangesAsync();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store { Id = storeId, Name = "Slice 5 Store", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        var t1 = new Template { Id = Guid.NewGuid(), Title = "Compliance Checklist", Type = "QC", Version = 1, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        var t2 = new Template { Id = Guid.NewGuid(), Title = "Routine Checklist", Type = "QC", Version = 1, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        var t3 = new Template { Id = Guid.NewGuid(), Title = "Compliance Survey Check", Type = "QC", Version = 1, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        var t4 = new Template { Id = Guid.NewGuid(), Title = "Legacy Survey", Type = "QC", Version = 1, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        db.Templates.AddRange(t1, t2, t3, t4);
        await db.SaveChangesAsync();

        // Fixture A: compliance submission (scored, down, total_score = 85.0)
        db.Submissions.Add(new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = storeId,
            TemplateId = t1.Id,
            TemplateTitle = "Compliance Checklist",
            ScoreDirection = "down",
            IsWeighted = true,
            TotalScore = 85.0m,
            Status = "completed",
            CompletedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Fixture B: routine submission (scored, down, total_score = 60.0)
        db.Submissions.Add(new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = storeId,
            TemplateId = t2.Id,
            TemplateTitle = "Routine Checklist",
            ScoreDirection = "down",
            IsWeighted = false,
            TotalScore = 60.0m,
            Status = "completed",
            CompletedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Fixture C: survey (no score, score_direction = none)
        db.Submissions.Add(new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = storeId,
            TemplateId = t3.Id,
            TemplateTitle = "Compliance Survey Check",
            ScoreDirection = "none",
            IsWeighted = false,
            TotalScore = null,
            Status = "completed",
            CompletedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Fixture D: null/empty category tag submission
        db.Submissions.Add(new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = storeId,
            TemplateId = t4.Id,
            TemplateTitle = "Legacy Survey",
            ScoreDirection = "none",
            IsWeighted = false,
            TotalScore = null,
            Status = "completed",
            CompletedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task EnsureSuccessAsync(HttpResponseMessage response)
    {
        if (!response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            Assert.Fail($"HTTP {response.StatusCode} failed. Body: {content}");
        }
    }

    [Fact]
    public async Task TC02_LegacyScoringModeQueryParam_IsIgnoredOrRejected()
    {
        // Arrange
        await SeedTestDataAsync();
        var client = await CreateAdminClientAsync();

        // Act
        var response = await client.GetAsync("/api/analytics?scoringMode=penalty");
        await EnsureSuccessAsync(response);

        // Assert
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = body.GetProperty("kpis");
        var totalAudits = kpis.GetProperty("totalAudits").GetInt32();

        // Should ignore scoringMode entirely and return global count (Fixture A + B + C + D = 4)
        Assert.Equal(4, totalAudits);
    }

    [Fact]
    public async Task TC03_ScoreDirection_ReplacesScoringMode_InScoredCheck()
    {
        // Arrange
        await SeedTestDataAsync();
        var client = await CreateAdminClientAsync();

        // Act
        var response = await client.GetAsync("/api/analytics");
        await EnsureSuccessAsync(response);

        // Assert
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = body.GetProperty("kpis");
        var totalScored = kpis.GetProperty("totalScored").GetInt32();
        var totalSurveys = kpis.GetProperty("totalSurveys").GetInt32();

        // Expected:
        // Scored: Fixture A (compliance, scoreDirection = down), Fixture B (routine, scoreDirection = down) -> 2
        // Surveys: Fixture C (compliance, scoreDirection = none), Fixture D (null category, scoreDirection = none) -> 2
        Assert.Equal(2, totalScored);
        Assert.Equal(2, totalSurveys);
    }
}
