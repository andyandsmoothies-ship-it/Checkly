using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Checkly.Api.Features.Analytics;

public static class ProvinceBenchmarkCalculator
{
    public static async Task RunForAllProvincesAsync(AppDbContext db, ILogger logger, CancellationToken ct)
    {
        var cutoff30d = DateTimeOffset.UtcNow.AddDays(-30);
        var cutoff90d = DateTimeOffset.UtcNow.AddDays(-90);

        // Get distinct provinces from stores, ignoring null/empty
        var provinces = await db.Stores
            .Where(s => s.Address2 != null && !string.IsNullOrEmpty(s.Address2.Province))
            .Select(s => s.Address2!.Province!)
            .Distinct()
            .ToListAsync(ct);

        foreach (var province in provinces)
        {
            // COUNT submissions in last 30d for this province
            var totalAudits30d = await db.Submissions
                .Where(s => s.Store!.Address2 != null && s.Store.Address2.Province == province && s.CreatedAt >= cutoff30d)
                .CountAsync(ct);

            if (totalAudits30d < 3)
            {
                logger.LogInformation("Skipped province {Province}: Insufficient audits ({Count})", province, totalAudits30d);
                continue; // SKIP
            }

            // COMPUTE OverallAvgScore and StdDeviation (from StoreAnalyticsSnapshot)
            var storeSnapshots = await db.StoreAnalyticsSnapshots
                .Where(s => s.Store!.Address2 != null && s.Store.Address2.Province == province)
                .ToListAsync(ct);

            decimal overallAvgScore = 0;
            decimal stdDeviation = 0;

            if (storeSnapshots.Any())
            {
                overallAvgScore = storeSnapshots.Average(s => s.AvgScore30d);

                // StdDev
                if (storeSnapshots.Count > 1)
                {
                    var sumOfSquares = storeSnapshots.Sum(s => Math.Pow((double)(s.AvgScore30d - overallAvgScore), 2));
                    stdDeviation = (decimal)Math.Sqrt(sumOfSquares / storeSnapshots.Count);
                }
            }

            // COMPUTE CategoryAverages (from SubmissionSectionScores, last 90d)
            var categoryAveragesRaw = await db.SubmissionSectionScores
                .Where(s => s.Submission!.Store!.Address2 != null && s.Submission.Store.Address2.Province == province && s.CreatedAt >= cutoff90d)
                .GroupBy(s => s.SectionTitle)
                .Select(g => new
                {
                    SectionTitle = g.Key,
                    // Convert score and max score to ratio, then average it
                    AvgRatio = g.Average(x => x.MaxScore > 0 ? (double)(x.Score / x.MaxScore) : 0)
                })
                .ToListAsync(ct);

            var categoryAverages = new Dictionary<string, double>();
            foreach (var cat in categoryAveragesRaw)
            {
                categoryAverages[cat.SectionTitle] = Math.Round(cat.AvgRatio * 100.0, 2);
            }

            var jsonCategoryAverages = JsonSerializer.Serialize(categoryAverages);

            // UPSERT province_benchmark_snapshots
            var existing = await db.ProvinceBenchmarkSnapshots.FirstOrDefaultAsync(x => x.Province == province, ct);
            if (existing != null)
            {
                existing.OverallAvgScore = overallAvgScore;
                existing.StdDeviation = stdDeviation;
                existing.TotalAuditCount = totalAudits30d;
                existing.CategoryAverages = jsonCategoryAverages;
                existing.LastCalculatedAt = DateTimeOffset.UtcNow;
            }
            else
            {
                db.ProvinceBenchmarkSnapshots.Add(new ProvinceBenchmarkSnapshot
                {
                    Province = province,
                    OverallAvgScore = overallAvgScore,
                    StdDeviation = stdDeviation,
                    TotalAuditCount = totalAudits30d,
                    CategoryAverages = jsonCategoryAverages,
                    CreatedAt = DateTimeOffset.UtcNow,
                    LastCalculatedAt = DateTimeOffset.UtcNow
                });
            }

            logger.LogInformation("Processed province {Province}: {Count} audits, Avg: {AvgScore}, StdDev: {StdDev}",
                province, totalAudits30d, overallAvgScore, stdDeviation);
        }

        await db.SaveChangesAsync(ct);
    }
}
