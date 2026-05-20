using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// ATDD RED tests for ProvinceBenchmarkCalculator (Slice 2, Phase B1).
/// Workflow: /tdd
/// </summary>
public class ProvinceBenchmarkCalculatorTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly string _provinceHcm = $"HCM_{Guid.NewGuid():N}";
    private readonly string _provinceHn = $"HN_{Guid.NewGuid():N}";

    public ProvinceBenchmarkCalculatorTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task SeedTestDataAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // -- Province: Hồ Chí Minh (5 audits) --
        var storeHcm1 = Guid.NewGuid();
        var storeHcm2 = Guid.NewGuid();
        var storeHcm3 = Guid.NewGuid();
        
        db.Stores.AddRange(
            new Store { Id = storeHcm1, Name = "Store HCM 1", Address2 = new StoreAddress { Province = _provinceHcm }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeHcm2, Name = "Store HCM 2", Address2 = new StoreAddress { Province = _provinceHcm }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeHcm3, Name = "Store HCM 3", Address2 = new StoreAddress { Province = _provinceHcm }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.StoreAnalyticsSnapshots.AddRange(
            new StoreAnalyticsSnapshot { StoreId = storeHcm1, AvgScore30d = 82.5m, TotalAudits30d = 2, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeHcm2, AvgScore30d = 72.5m, TotalAudits30d = 2, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeHcm3, AvgScore30d = 90.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow }
        );

        // Submissions for HCM (Total = 5)
        var subHcm1_1 = AddSubmissionsToStore(db, storeHcm1, 1).First();
        var subHcm1_2 = AddSubmissionsToStore(db, storeHcm1, 1).First();
        AddSubmissionsToStore(db, storeHcm2, 2);
        AddSubmissionsToStore(db, storeHcm3, 1);

        // Section Scores for HCM
        db.SubmissionSectionScores.AddRange(
            new SubmissionSectionScore { Id = Guid.NewGuid(), SubmissionId = subHcm1_1.Id, StoreId = storeHcm1, SectionTitle = "Section A", Score = 82.5m, MaxScore = 100m, CreatedAt = DateTimeOffset.UtcNow },
            new SubmissionSectionScore { Id = Guid.NewGuid(), SubmissionId = subHcm1_2.Id, StoreId = storeHcm1, SectionTitle = "Section B", Score = 76.2m, MaxScore = 100m, CreatedAt = DateTimeOffset.UtcNow }
        );

        // -- Province: Hà Nội (2 audits) -- Should skip (threshold = 3)
        var storeHn1 = Guid.NewGuid();
        var storeHn2 = Guid.NewGuid();
        db.Stores.AddRange(
            new Store { Id = storeHn1, Name = "Store HN 1", Address2 = new StoreAddress { Province = _provinceHn }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeHn2, Name = "Store HN 2", Address2 = new StoreAddress { Province = _provinceHn }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.StoreAnalyticsSnapshots.AddRange(
            new StoreAnalyticsSnapshot { StoreId = storeHn1, AvgScore30d = 90.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeHn2, AvgScore30d = 60.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow }
        );

        AddSubmissionsToStore(db, storeHn1, 1);
        AddSubmissionsToStore(db, storeHn2, 1);

        // -- Province: NULL (5 audits) -- Should skip (Null check)
        var storeNull1 = Guid.NewGuid();
        var storeNull2 = Guid.NewGuid();
        db.Stores.AddRange(
            new Store { Id = storeNull1, Name = "Store Null 1", Address2 = new StoreAddress { Province = null }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeNull2, Name = "Store Null 2", Address2 = null, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.StoreAnalyticsSnapshots.AddRange(
            new StoreAnalyticsSnapshot { StoreId = storeNull1, AvgScore30d = 90.0m, TotalAudits30d = 3, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeNull2, AvgScore30d = 60.0m, TotalAudits30d = 2, UpdatedAt = DateTimeOffset.UtcNow }
        );

        AddSubmissionsToStore(db, storeNull1, 3);
        AddSubmissionsToStore(db, storeNull2, 2);

        await db.SaveChangesAsync();
    }

    private List<Submission> AddSubmissionsToStore(AppDbContext db, Guid storeId, int count)
    {
        var list = new List<Submission>();
        for (int i = 0; i < count; i++)
        {
            var sub = new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = storeId,
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            };
            db.Submissions.Add(sub);
            list.Add(sub);
        }
        return list;
    }

    [Fact]
    public async Task ProvinceBenchmarkCalculator_ProvinceWithMinAudits_ComputesAndUpsertsBenchmark()
    {
        // Arrange
        await SeedTestDataAsync();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act - this class and method do not exist yet (RED)
        // Expected signature: ProvinceBenchmarkCalculator.RunForAllProvincesAsync(AppDbContext db, ILogger logger, CancellationToken ct)
        var logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<ProvinceBenchmarkCalculatorTests>>();
        await Checkly.Api.Features.Analytics.ProvinceBenchmarkCalculator.RunForAllProvincesAsync(db, logger, CancellationToken.None);

        // Assert (TC-SL2-01)
        var snapshot = await db.ProvinceBenchmarkSnapshots.FirstOrDefaultAsync(x => x.Province == _provinceHcm);
        
        Assert.NotNull(snapshot);
        Assert.Equal(5, snapshot.TotalAuditCount);
        
        // Assert math
        // Store HCM 1 (82.5), Store HCM 2 (72.5), Store HCM 3 (90)
        // Mean = (82.5 + 72.5 + 90) / 3 = 81.66...
        Assert.True(snapshot.OverallAvgScore > 0);
        Assert.True(snapshot.StdDeviation > 0); 
        
        // Assert JSON mapping
        Assert.False(string.IsNullOrEmpty(snapshot.CategoryAverages));
        var dict = JsonSerializer.Deserialize<Dictionary<string, double>>(snapshot.CategoryAverages);
        Assert.NotNull(dict);
        Assert.True(dict.ContainsKey("Section A"));
    }

    [Fact]
    public async Task ProvinceBenchmarkCalculator_ProvinceUnderMinAudits_SkipsBenchmark()
    {
        // Arrange
        await SeedTestDataAsync();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<ProvinceBenchmarkCalculatorTests>>();
        await Checkly.Api.Features.Analytics.ProvinceBenchmarkCalculator.RunForAllProvincesAsync(db, logger, CancellationToken.None);

        // Assert (TC-SL2-03)
        var snapshot = await db.ProvinceBenchmarkSnapshots.FirstOrDefaultAsync(x => x.Province == _provinceHn);
        Assert.Null(snapshot); // Hà Nội only had 2 audits, should be skipped
    }

    [Fact]
    public async Task ProvinceBenchmarkCalculator_NullProvince_SkipsBenchmark()
    {
        // Arrange
        await SeedTestDataAsync();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<ProvinceBenchmarkCalculatorTests>>();
        await Checkly.Api.Features.Analytics.ProvinceBenchmarkCalculator.RunForAllProvincesAsync(db, logger, CancellationToken.None);

        // Assert (TC-SL2-02)
        var snapshot = await db.ProvinceBenchmarkSnapshots.FirstOrDefaultAsync(x => string.IsNullOrEmpty(x.Province));
        Assert.Null(snapshot); // Null provinces should be skipped regardless of audits count
    }
}
