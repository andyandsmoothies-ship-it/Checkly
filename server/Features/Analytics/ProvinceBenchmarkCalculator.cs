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

        // OBS-6: Only active stores belong in benchmark calculations.
        // OBS-3: Hoist province list to use IsActive filter consistently with the bulk queries below.
        var provinces = await db.Stores
            .Where(s => s.Address2 != null && !string.IsNullOrEmpty(s.Address2.Province) && s.IsActive == true)
            .Select(s => s.Address2!.Province!)
            .Distinct()
            .ToListAsync(ct);

        if (provinces.Count == 0) return;

        // ── OBS-3: Replace 3N DB roundtrips with 3 single GroupBy queries ──────────
        // BEFORE: 3 separate DB hits per province inside the loop = 3N roundtrips.
        // AFTER:  3 queries total that return ALL provinces at once, then we partition
        //         the results in memory. Zero loop DB hits.

        // Query 1 of 3: audit count per province, last 30 days.
        // OBS-6: Only active stores contribute to the count.
        var auditCountsByProvince = await db.Submissions
            .Where(s => s.Store!.Address2 != null &&
                        s.Store.IsActive == true &&
                        s.CreatedAt >= cutoff30d)
            .GroupBy(s => s.Store!.Address2!.Province!)
            .Select(g => new { Province = g.Key, Count = g.Count() })
            .ToListAsync(ct);

        var auditCountMap = auditCountsByProvince
            .ToDictionary(x => x.Province, x => x.Count);

        // Query 2 of 3: store analytics snapshots per province.
        // OBS-6: Snapshots are only meaningful for active stores.
        var allSnapshots = await db.StoreAnalyticsSnapshots
            .Where(s => s.Store!.Address2 != null && s.Store.IsActive == true)
            .Select(s => new { Province = s.Store!.Address2!.Province!, s.AvgScore30d })
            .ToListAsync(ct);

        var snapshotsByProvince = allSnapshots
            .Where(x => x.Province != null)
            .GroupBy(x => x.Province)
            .ToDictionary(g => g.Key, g => g.Select(x => x.AvgScore30d).ToList());

        // Query 3 of 3: section score ratios per province, last 90 days.
        // OBS-6: Traversal through active stores only.
        var allCategoryAverages = await db.SubmissionSectionScores
            .Where(s => s.Submission!.Store!.Address2 != null &&
                        s.Submission.Store.IsActive == true &&
                        s.CreatedAt >= cutoff90d)
            .GroupBy(s => new { Province = s.Submission!.Store!.Address2!.Province!, s.SectionTitle })
            .Select(g => new
            {
                g.Key.Province,
                g.Key.SectionTitle,
                AvgRatio = g.Average(x => x.MaxScore > 0 ? (double)(x.Score / x.MaxScore) : 0),
            })
            .ToListAsync(ct);

        var categoryAveragesByProvince = allCategoryAverages
            .GroupBy(x => x.Province)
            .ToDictionary(
                g => g.Key,
                g => g.ToDictionary(x => x.SectionTitle, x => Math.Round(x.AvgRatio * 100.0, 2)));

        // ── Process each province in memory — zero DB hits below this line ───────
        foreach (var province in provinces)
        {
            var totalAudits30d = auditCountMap.GetValueOrDefault(province, 0);

            if (totalAudits30d < 3)
            {
                logger.LogInformation("Skipped province {Province}: Insufficient audits ({Count})", province, totalAudits30d);
                continue;
            }

            // Compute OverallAvgScore and StdDeviation from in-memory snapshots.
            decimal overallAvgScore = 0;
            decimal stdDeviation = 0;

            if (snapshotsByProvince.TryGetValue(province, out var scores) && scores.Count > 0)
            {
                overallAvgScore = scores.Average();

                if (scores.Count > 1)
                {
                    var sumOfSquares = scores.Sum(s => Math.Pow((double)(s - overallAvgScore), 2));
                    stdDeviation = (decimal)Math.Sqrt(sumOfSquares / scores.Count);
                }
            }

            // Build category averages from in-memory partition.
            var categoryAverages = categoryAveragesByProvince.GetValueOrDefault(province, []);
            var jsonCategoryAverages = JsonSerializer.Serialize(categoryAverages);

            // UPSERT province_benchmark_snapshots.
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
                    LastCalculatedAt = DateTimeOffset.UtcNow,
                });
            }

            logger.LogInformation("Processed province {Province}: {Count} audits, Avg: {AvgScore}, StdDev: {StdDev}",
                province, totalAudits30d, overallAvgScore, stdDeviation);
        }

        await db.SaveChangesAsync(ct);
    }
}
