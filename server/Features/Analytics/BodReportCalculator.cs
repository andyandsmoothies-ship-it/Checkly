using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Checkly.Api.Features.Analytics
{
    public class BodReportCalculator
    {
        private readonly ILogger<BodReportCalculator>? _logger;

        public string LastRunStatus { get; set; } = "Complete";

        public BodReportCalculator(ILogger<BodReportCalculator>? logger = null)
        {
            _logger = logger;
        }

        public virtual async Task<string> ComputeDailyReportAsync(AppDbContext db, DateOnly date, CancellationToken ct)
        {
            return await ComputeDailyReportWithTimezoneAsync(db, date, null, ct);
        }

        public virtual async Task<string> ComputeDailyReportWithTimezoneAsync(AppDbContext db, DateOnly date, string? timezoneId, CancellationToken ct)
        {
            LastRunStatus = "Complete";

            // Resolve Corporate Timezone
            TimeZoneInfo tz;
            if (string.IsNullOrEmpty(timezoneId))
            {
                tz = TimeZoneInfo.Utc;
            }
            else
            {
                try
                {
                    tz = TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
                }
                catch
                {
                    if (timezoneId == "Asia/Ho_Chi_Minh")
                    {
                        try { tz = TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"); }
                        catch { tz = TimeZoneInfo.Utc; }
                    }
                    else if (timezoneId == "US/Eastern")
                    {
                        try { tz = TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time"); }
                        catch { tz = TimeZoneInfo.Utc; }
                    }
                    else
                    {
                        tz = TimeZoneInfo.Utc;
                    }
                }
            }

            // Local end of the target date: 23:59:59.999
            var localEndOfDay = new DateTime(date.Year, date.Month, date.Day, 23, 59, 59, 999, DateTimeKind.Unspecified);
            
            // Convert to UTC DateTimeOffset
            DateTimeOffset targetDateTime;
            if (tz == TimeZoneInfo.Utc)
            {
                targetDateTime = new DateTimeOffset(localEndOfDay, TimeSpan.Zero);
            }
            else
            {
                var offset = tz.GetUtcOffset(localEndOfDay);
                targetDateTime = new DateTimeOffset(localEndOfDay, offset).ToUniversalTime();
            }

            // Initialize all section variables
            var kpis = new BodChainKpis(0, 0m, 0m, 0, 0, 0, 0);
            var trend = new List<TrendPoint>();
            List<BodStoreRankEntry>? topStores = new();
            List<BodStoreRankEntry>? bottomStores = new();
            var weaknesses = new List<BodCategoryWeakness>();
            var actionPlanAging = new List<BodApAgingBucket>();
            var auditorProductivity = new List<BodAuditorProductivity>();

            // 1. Chain KPIs
            try
            {
                var totalAudits = await db.Submissions.CountAsync(s => 
                    s.Status == "completed" && 
                    s.ReviewStatus != "rejected" && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt <= targetDateTime, ct);

                var scoredQuery = db.Submissions.Where(s => 
                    s.Status == "completed" && 
                    s.ReviewStatus != "rejected" && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt <= targetDateTime && 
                    s.ScoringMode != "survey" && 
                    s.TotalScore.HasValue);

                var scoredCount = await scoredQuery.CountAsync(ct);
                var avgScore = scoredCount > 0
                    ? Math.Round(await scoredQuery.AverageAsync(s => s.TotalScore!.Value, ct), 1)
                    : 0m;

                var totalScheduled = await db.Submissions.CountAsync(s => 
                    s.ReviewStatus != "rejected" && 
                    s.CreatedAt <= targetDateTime, ct);

                var completionRate = totalScheduled > 0
                    ? Math.Round((decimal)totalAudits / totalScheduled * 100m, 1)
                    : 0m;

                var openActionPlans = await db.ActionPlans.CountAsync(ap => 
                    ap.Status == "open" && 
                    ap.CreatedAt <= targetDateTime, ct);

                var overdueActionPlans = await db.ActionPlans.CountAsync(ap => 
                    ap.Status == "open" && 
                    ap.CreatedAt <= targetDateTime && 
                    ap.Deadline.HasValue && 
                    ap.Deadline <= targetDateTime, ct);

                var activeStores = await db.Stores.CountAsync(st => 
                    st.IsActive == true && 
                    st.CreatedAt <= targetDateTime, ct);

                var totalAuditors = await db.Submissions.Where(s => 
                    s.Status == "completed" && 
                    s.ReviewStatus != "rejected" && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt <= targetDateTime && 
                    s.AuditorId.HasValue)
                    .Select(s => s.AuditorId!.Value)
                    .Distinct()
                    .CountAsync(ct);

                kpis = new BodChainKpis(
                    totalAudits,
                    avgScore,
                    completionRate,
                    openActionPlans,
                    overdueActionPlans,
                    activeStores,
                    totalAuditors
                );
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 1 (Chain KPIs) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
            }

            // 2. 12-Month Trend
            try
            {
                var localFirstDay = new DateTime(date.Year, date.Month, 1, 0, 0, 0, DateTimeKind.Unspecified).AddMonths(-11);
                
                DateTimeOffset trendStartDate;
                if (tz == TimeZoneInfo.Utc)
                {
                    trendStartDate = new DateTimeOffset(localFirstDay, TimeSpan.Zero);
                }
                else
                {
                    var offset = tz.GetUtcOffset(localFirstDay);
                    trendStartDate = new DateTimeOffset(localFirstDay, offset).ToUniversalTime();
                }

                var trendRaw = await db.Submissions.AsNoTracking()
                    .Where(s => 
                        s.Status == "completed" && 
                        s.ReviewStatus != "rejected" && 
                        s.CompletedAt.HasValue && 
                        s.CompletedAt >= trendStartDate && 
                        s.CompletedAt <= targetDateTime && 
                        s.ScoringMode != "survey" && 
                        s.TotalScore.HasValue)
                    .GroupBy(s => new { s.CompletedAt!.Value.Year, s.CompletedAt.Value.Month })
                    .Select(g => new
                    {
                        g.Key.Year,
                        g.Key.Month,
                        AvgScore = g.Average(s => s.TotalScore!.Value),
                        Count = g.Count()
                    })
                    .ToListAsync(ct);

                trend = trendRaw
                    .OrderBy(x => x.Year).ThenBy(x => x.Month)
                    .Select(x => new TrendPoint(
                        $"{x.Year}-{x.Month:D2}",
                        Math.Round((double)x.AvgScore, 1),
                        x.Count))
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 2 (12-Month Trend) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
            }

            // 3. Top/Bottom Stores (Last 30 Days)
            try
            {
                var local30DaysAgo = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Unspecified).AddDays(-30);
                
                DateTimeOffset start30DaysAgo;
                if (tz == TimeZoneInfo.Utc)
                {
                    start30DaysAgo = new DateTimeOffset(local30DaysAgo, TimeSpan.Zero);
                }
                else
                {
                    var offset = tz.GetUtcOffset(local30DaysAgo);
                    start30DaysAgo = new DateTimeOffset(local30DaysAgo, offset).ToUniversalTime();
                }

                var storeStats = await db.Submissions.AsNoTracking()
                    .Where(s => 
                        s.Status == "completed" && 
                        s.ReviewStatus != "rejected" && 
                        s.CompletedAt.HasValue && 
                        s.CompletedAt >= start30DaysAgo && 
                        s.CompletedAt <= targetDateTime && 
                        s.ScoringMode != "survey" && 
                        s.TotalScore.HasValue && 
                        s.StoreId.HasValue)
                    .GroupBy(s => new { s.StoreId!.Value, s.StoreName })
                    .Select(g => new
                    {
                        StoreId = g.Key.Value,
                        StoreName = g.Key.StoreName ?? "Unknown Store",
                        AvgScore = g.Average(s => s.TotalScore!.Value),
                        AuditCount = g.Count()
                    })
                    .ToListAsync(ct);

                topStores = storeStats
                    .OrderByDescending(x => x.AvgScore)
                    .ThenByDescending(x => x.AuditCount)
                    .Take(5)
                    .Select(x => new BodStoreRankEntry(x.StoreId, x.StoreName, Math.Round(x.AvgScore, 1), x.AuditCount))
                    .ToList();

                bottomStores = storeStats
                    .OrderBy(x => x.AvgScore)
                    .ThenBy(x => x.AuditCount)
                    .Take(5)
                    .Select(x => new BodStoreRankEntry(x.StoreId, x.StoreName, Math.Round(x.AvgScore, 1), x.AuditCount))
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 3 (Top/Bottom Stores) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
                topStores = null;
                bottomStores = null;
            }

            // 4. Category Weaknesses (Last 90 Days)
            try
            {
                var local90DaysAgo = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Unspecified).AddDays(-90);
                
                DateTimeOffset start90DaysAgo;
                if (tz == TimeZoneInfo.Utc)
                {
                    start90DaysAgo = new DateTimeOffset(local90DaysAgo, TimeSpan.Zero);
                }
                else
                {
                    var offset = tz.GetUtcOffset(local90DaysAgo);
                    start90DaysAgo = new DateTimeOffset(local90DaysAgo, offset).ToUniversalTime();
                }

                var sectionStats = await db.SubmissionSectionScores.AsNoTracking()
                    .Where(ss => ss.CreatedAt >= start90DaysAgo && ss.CreatedAt <= targetDateTime && ss.MaxScore > 0)
                    .GroupBy(ss => new { ss.SectionTitle, TemplateTitle = ss.Submission!.TemplateTitle })
                    .Select(g => new
                    {
                        CategoryName = g.Key.SectionTitle,
                        TemplateTitle = g.Key.TemplateTitle ?? "Unknown Template",
                        TotalScore = g.Sum(ss => ss.Score),
                        TotalMaxScore = g.Sum(ss => ss.MaxScore),
                        AuditCount = g.Count()
                    })
                    .ToListAsync(ct);

                weaknesses = sectionStats
                    .Select(x => new BodCategoryWeakness(
                        x.CategoryName,
                        x.TemplateTitle,
                        x.TotalMaxScore > 0 ? Math.Round((x.TotalScore / x.TotalMaxScore) * 100m, 1) : 0m,
                        x.AuditCount))
                    .OrderBy(x => x.AvgScore)
                    .Take(5)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 4 (Category Weaknesses) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
            }

            // 5. Action Plan Aging
            try
            {
                var openAps = await db.ActionPlans.AsNoTracking()
                    .Where(ap => ap.Status == "open" && ap.CreatedAt <= targetDateTime)
                    .Select(ap => ap.CreatedAt)
                    .ToListAsync(ct);

                var bucket_0_7 = 0;
                var bucket_8_30 = 0;
                var bucket_31_90 = 0;
                var bucket_90_plus = 0;

                foreach (var createdAt in openAps)
                {
                    var ageInDays = (targetDateTime - createdAt).TotalDays;
                    if (ageInDays <= 7) bucket_0_7++;
                    else if (ageInDays <= 30) bucket_8_30++;
                    else if (ageInDays <= 90) bucket_31_90++;
                    else bucket_90_plus++;
                }

                actionPlanAging = new List<BodApAgingBucket>
                {
                    new("0-7d", bucket_0_7),
                    new("8-30d", bucket_8_30),
                    new("31-90d", bucket_31_90),
                    new("90d+", bucket_90_plus)
                };
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 5 (Action Plan Aging) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
            }

            // 6. Auditor Productivity (Last 30 Days)
            try
            {
                var local30DaysAgo = new DateTime(date.Year, date.Month, date.Day, 0, 0, 0, DateTimeKind.Unspecified).AddDays(-30);
                
                DateTimeOffset start30DaysAgo;
                if (tz == TimeZoneInfo.Utc)
                {
                    start30DaysAgo = new DateTimeOffset(local30DaysAgo, TimeSpan.Zero);
                }
                else
                {
                    var offset = tz.GetUtcOffset(local30DaysAgo);
                    start30DaysAgo = new DateTimeOffset(local30DaysAgo, offset).ToUniversalTime();
                }

                var auditorStats = await db.Submissions.AsNoTracking()
                    .Where(s => 
                        s.Status == "completed" && 
                        s.ReviewStatus != "rejected" && 
                        s.CompletedAt.HasValue && 
                        s.CompletedAt >= start30DaysAgo && 
                        s.CompletedAt <= targetDateTime && 
                        s.AuditorId.HasValue)
                    .GroupBy(s => new { s.AuditorId!.Value, s.AuditorName })
                    .Select(g => new
                    {
                        AuditorId = g.Key.Value,
                        AuditorName = g.Key.AuditorName ?? "Unknown Auditor",
                        CompletedAudits = g.Count(),
                        AvgScore = g.Any(s => s.TotalScore.HasValue && s.ScoringMode != "survey")
                            ? g.Where(s => s.TotalScore.HasValue && s.ScoringMode != "survey").Average(s => s.TotalScore!.Value)
                            : 0m
                    })
                    .ToListAsync(ct);

                auditorProductivity = auditorStats
                    .Select(x => new BodAuditorProductivity(
                        x.AuditorId,
                        x.AuditorName,
                        x.CompletedAudits,
                        Math.Round(x.AvgScore, 1)))
                    .OrderByDescending(x => x.CompletedAudits)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger?.LogWarning(ex, "Query 6 (Auditor Productivity) failed during BOD report calculation.");
                LastRunStatus = "PartiallyFailed";
            }

            // Combine into final payload
            var response = new BodReportResponse(
                kpis,
                trend,
                topStores,
                bottomStores,
                weaknesses,
                actionPlanAging,
                auditorProductivity
            );

            var options = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            };

            return JsonSerializer.Serialize(response, options);
        }
    }
}
