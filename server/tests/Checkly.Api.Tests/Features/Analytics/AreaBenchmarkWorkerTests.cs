using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// ATDD RED tests for AreaBenchmarkWorker (Slice 1, Phase B2).
/// Workflow: /tdd
/// </summary>
public class AreaBenchmarkWorkerTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AreaBenchmarkWorkerTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<(Guid AreaAId, Guid AreaBId)> SeedTestDataAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var areaAId = Guid.NewGuid(); // Should compute benchmark (5 audits)
        var areaBId = Guid.NewGuid(); // Should SKIP benchmark (2 audits)

        db.Areas.Add(new Area { Id = areaAId, Name = "Area A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Areas.Add(new Area { Id = areaBId, Name = "Area B", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        // -- Area A --
        var storeA1 = Guid.NewGuid();
        var storeA2 = Guid.NewGuid();
        var storeA3 = Guid.NewGuid();
        db.Stores.AddRange(
            new Store { Id = storeA1, AreaId = areaAId, Name = "Store A1", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeA2, AreaId = areaAId, Name = "Store A2", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeA3, AreaId = areaAId, Name = "Store A3", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.StoreAnalyticsSnapshots.AddRange(
            new StoreAnalyticsSnapshot { StoreId = storeA1, AvgScore30d = 82.5m, TotalAudits30d = 2, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeA2, AvgScore30d = 72.5m, TotalAudits30d = 2, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeA3, AvgScore30d = 90.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow }
        );

        // Submissions for Area A (Total = 5)
        var subA1_1 = AddSubmissionsToStore(db, storeA1, 1).First();
        var subA1_2 = AddSubmissionsToStore(db, storeA1, 1).First();
        AddSubmissionsToStore(db, storeA2, 2);
        AddSubmissionsToStore(db, storeA3, 1);

        // Section Scores for Area A
        db.SubmissionSectionScores.AddRange(
            new SubmissionSectionScore { Id = Guid.NewGuid(), SubmissionId = subA1_1.Id, StoreId = storeA1, SectionTitle = "Section A", Score = 82.5m, MaxScore = 100m, CreatedAt = DateTimeOffset.UtcNow },
            new SubmissionSectionScore { Id = Guid.NewGuid(), SubmissionId = subA1_2.Id, StoreId = storeA1, SectionTitle = "Section B", Score = 76.2m, MaxScore = 100m, CreatedAt = DateTimeOffset.UtcNow }
        );

        // -- Area B --
        var storeB1 = Guid.NewGuid();
        var storeB2 = Guid.NewGuid();
        db.Stores.AddRange(
            new Store { Id = storeB1, AreaId = areaBId, Name = "Store B1", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeB2, AreaId = areaBId, Name = "Store B2", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.StoreAnalyticsSnapshots.AddRange(
            new StoreAnalyticsSnapshot { StoreId = storeB1, AvgScore30d = 90.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow },
            new StoreAnalyticsSnapshot { StoreId = storeB2, AvgScore30d = 60.0m, TotalAudits30d = 1, UpdatedAt = DateTimeOffset.UtcNow }
        );

        // Submissions for Area B (Total = 2) - should be skipped
        AddSubmissionsToStore(db, storeB1, 1);
        AddSubmissionsToStore(db, storeB2, 1);

        await db.SaveChangesAsync();

        return (areaAId, areaBId);
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
    public async Task AreaBenchmarkCalculator_AreaWithMinAudits_ComputesAndUpsertsBenchmark()
    {
        // Arrange
        var (areaAId, _) = await SeedTestDataAsync();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act - this class and method do not exist yet (RED)
        // Expected signature: AreaBenchmarkCalculator.RunForAllAreasAsync(AppDbContext db, CancellationToken ct)
        var logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<AreaBenchmarkWorkerTests>>();
        await Checkly.Api.Features.Analytics.AreaBenchmarkCalculator.RunForAllAreasAsync(db, logger, CancellationToken.None);

        // Assert (AB-01, AB-06)
        var snapshot = await db.AreaBenchmarkSnapshots.FirstOrDefaultAsync(x => x.AreaId == areaAId);
        
        Assert.NotNull(snapshot);
        Assert.Equal(5, snapshot.TotalAuditCount);
        
        // Assert math (AB-07)
        // Store A1 (82.5), Store A2 (72.5), Store A3 (90)
        // Mean = (82.5 + 72.5 + 90) / 3 = 81.66...
        Assert.True(snapshot.OverallAvgScore > 0);
        Assert.True(snapshot.StdDeviation > 0); 
        
        // Assert JSON mapping (AB-08)
        Assert.False(string.IsNullOrEmpty(snapshot.CategoryAverages));
        var dict = JsonSerializer.Deserialize<Dictionary<string, double>>(snapshot.CategoryAverages);
        Assert.NotNull(dict);
        Assert.True(dict.ContainsKey("Section A"));
    }

    [Fact]
    public async Task AreaBenchmarkCalculator_AreaUnderMinAudits_SkipsBenchmark()
    {
        // Arrange
        var (_, areaBId) = await SeedTestDataAsync();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var logger = scope.ServiceProvider.GetRequiredService<Microsoft.Extensions.Logging.ILogger<AreaBenchmarkWorkerTests>>();
        await Checkly.Api.Features.Analytics.AreaBenchmarkCalculator.RunForAllAreasAsync(db, logger, CancellationToken.None);

        // Assert (AB-05)
        var snapshot = await db.AreaBenchmarkSnapshots.FirstOrDefaultAsync(x => x.AreaId == areaBId);
        Assert.Null(snapshot); // Area B only had 2 audits, should be skipped
    }
}
