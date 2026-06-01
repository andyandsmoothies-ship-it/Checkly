using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics
{
    // --- DTO Definition records for Area BOD Report ---
    public record AreaBodResponse
    {
        public bool IsLiveData { get; init; }
        public AreaBodKpiDto Kpis { get; init; } = new();
        public AreaGoldenStoreDto? GoldenStore { get; init; }
        public List<AreaTrendPointDto> Trend { get; init; } = new();
        public List<AreaStoreRankEntryDto> TopStores { get; init; } = new();
        public List<AreaStoreRankEntryDto> BottomStores { get; init; } = new();
        public List<AreaCategoryWeaknessDto> Weaknesses { get; init; } = new();
        public List<AreaApAgingBucketDto> ActionPlanAging { get; init; } = new();
        public List<AreaAuditorProductivityDto> AuditorProductivity { get; init; } = new();
        public List<string> AllowedActions { get; init; } = new();
    }

    public record AreaBodKpiDto
    {
        public int TotalAudits { get; init; }
        public decimal AvgScore { get; init; }
        public decimal CompletionRate { get; init; }
        public int OpenActionPlans { get; init; }
        public int OverdueActionPlans { get; init; }
        public int ActiveStores { get; init; }
        public int TotalAuditors { get; init; }
        public decimal AvgTtrDays { get; init; }
    }

    public record AreaGoldenStoreDto
    {
        public string StoreName { get; init; } = "";
        public decimal AvgScore { get; init; }
        public string Province { get; init; } = "";
    }

    public record AreaTrendPointDto
    {
        public string Month { get; init; } = "";
        public double AvgScore { get; init; }
        public int AuditCount { get; init; }
    }

    public record AreaStoreRankEntryDto
    {
        public Guid StoreId { get; init; }
        public string StoreName { get; init; } = "";
        public decimal AvgScore { get; init; }
        public int AuditCount { get; init; }
        public DateTimeOffset? LastSyncedAt { get; init; }
    }

    public record AreaCategoryWeaknessDto
    {
        public string CategoryName { get; init; } = "";
        public string TemplateName { get; init; } = "";
        public decimal AvgScore { get; init; }
        public int AuditCount { get; init; }
    }

    public record AreaApAgingBucketDto(string Bucket, int Count);
    public record AreaAuditorProductivityDto(string AuditorName, int CompletedCount, decimal AvgScore);

    /// <summary>
    /// GET /api/analytics/bod/area — retrieves tenancy-scoped Boardroom Dashboard analytics for Area Managers.
    /// </summary>
    public static class GetAreaBodReport
    {
        public static async Task<IResult> HandleAsync(
            ClaimsPrincipal user,
            PbacDictionaryCache pbacCache,
            AppDbContext db,
            CancellationToken ct)
        {
            var userIdStr = user.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
            {
                return TypedResults.Unauthorized();
            }

            // Get stores assigned to the caller via ProfileStoreAssignment
            var assignedStoreIds = await db.ProfileStoreAssignments
                .AsNoTracking()
                .Where(x => x.ProfileId == userId)
                .Select(x => x.StoreId)
                .ToListAsync(ct);

            var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var capabilities = pbacCache.GetCapabilities(role);
            var allowedActions = new List<string>();
            if (capabilities.Contains(AppCapabilities.AnalyticsArea))
            {
                allowedActions.Add("refresh");
            }

            // AC-2.1: Area Manager with no assigned stores returns empty report with zeroed KPIs
            if (assignedStoreIds.Count == 0)
            {
                return TypedResults.Ok(new AreaBodResponse
                {
                    IsLiveData = true,
                    AllowedActions = allowedActions
                });
            }

            var now = DateTimeOffset.UtcNow;
            var start30DaysAgo = now.AddDays(-30);

            // KPI 1: totalAudits and KPI 2: avgScore
            // Exclude survey submissions and rejected submissions, but include unreviewed (ReviewStatus == null)
            var submissionsLast30Days = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue &&
                            assignedStoreIds.Contains(s.StoreId.Value))
                .ToListAsync(ct);

            int totalAudits = submissionsLast30Days.Count;
            decimal avgScore = totalAudits > 0
                ? Math.Round(submissionsLast30Days.Average(s => s.TotalScore!.Value), 1)
                : 0m;

            // KPI 3: completionRate
            var totalScheduled = await db.Submissions.AsNoTracking()
                .CountAsync(s => (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                                 s.CreatedAt >= start30DaysAgo &&
                                 s.CreatedAt <= now &&
                                 s.StoreId.HasValue &&
                                 assignedStoreIds.Contains(s.StoreId.Value), ct);

            decimal completionRate = totalScheduled > 0
                ? Math.Round((decimal)totalAudits / totalScheduled * 100m, 1)
                : 0m;

            // KPI 4: openActionPlans
            var openActionPlans = await db.ActionPlans.AsNoTracking()
                .CountAsync(ap => ap.Status == "open" &&
                                  ap.StoreId.HasValue &&
                                  assignedStoreIds.Contains(ap.StoreId.Value), ct);

            // KPI 5: overdueActionPlans
            var overdueActionPlans = await db.ActionPlans.AsNoTracking()
                .CountAsync(ap => ap.Status == "open" &&
                                  ap.StoreId.HasValue &&
                                  assignedStoreIds.Contains(ap.StoreId.Value) &&
                                  ap.Deadline.HasValue &&
                                  ap.Deadline <= now, ct);

            // KPI 6: activeStores
            int activeStores = await db.Stores.AsNoTracking()
                .CountAsync(st => st.IsActive == true && assignedStoreIds.Contains(st.Id), ct);

            // KPI 7: totalAuditors
            var totalAuditors = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            s.AuditorId.HasValue &&
                            s.StoreId.HasValue &&
                            assignedStoreIds.Contains(s.StoreId.Value))
                .Select(s => s.AuditorId!.Value)
                .Distinct()
                .CountAsync(ct);

            // KPI 8: avgTtrDays
            var closedActionPlans = await db.ActionPlans.AsNoTracking()
                .Where(ap => ap.Status == "closed" &&
                             ap.ClosedAt.HasValue &&
                             ap.StoreId.HasValue &&
                             assignedStoreIds.Contains(ap.StoreId.Value))
                .Select(ap => new { ap.CreatedAt, ap.ClosedAt })
                .ToListAsync(ct);

            decimal avgTtrDays = 0m;
            if (closedActionPlans.Any())
            {
                var totalTtr = closedActionPlans.Sum(ap => (ap.ClosedAt!.Value - ap.CreatedAt).TotalDays);
                avgTtrDays = Math.Round((decimal)(totalTtr / closedActionPlans.Count), 1);
            }

            // Golden Store (Top performing store for this Area Manager)
            var storeScores = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue &&
                            assignedStoreIds.Contains(s.StoreId.Value))
                .GroupBy(s => s.StoreId!.Value)
                .Select(g => new
                {
                    StoreId = g.Key,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            AreaGoldenStoreDto? goldenStoreObj = null;
            if (storeScores.Any())
            {
                var topStore = storeScores
                    .OrderByDescending(x => x.AvgScore)
                    .ThenByDescending(x => x.Count)
                    .FirstOrDefault();

                if (topStore != null)
                {
                    var storeEntity = await db.Stores.AsNoTracking()
                        .FirstOrDefaultAsync(st => st.Id == topStore.StoreId, ct);

                    if (storeEntity != null)
                    {
                        goldenStoreObj = new AreaGoldenStoreDto
                        {
                            StoreName = storeEntity.Name,
                            AvgScore = Math.Round(topStore.AvgScore, 1),
                            Province = storeEntity.Address2?.Province ?? ""
                        };
                    }
                }
            }

            // Regional Leaderboards (QC templates only)
            var leaderboardStoreScores = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue &&
                            assignedStoreIds.Contains(s.StoreId.Value) &&
                            (s.TemplateId == null || s.Template!.Type == "QC"))
                .GroupBy(s => s.StoreId!.Value)
                .Select(g => new
                {
                    StoreId = g.Key,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            var leaderboardStoreIds = leaderboardStoreScores.Select(x => x.StoreId).ToList();
            var storesMap = await db.Stores.AsNoTracking()
                .Where(s => leaderboardStoreIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id, ct);

            var storeRankEntries = leaderboardStoreScores
                .Select(x =>
                {
                    var storeEntity = storesMap.GetValueOrDefault(x.StoreId);
                    return new AreaStoreRankEntryDto
                    {
                        StoreId = x.StoreId,
                        StoreName = storeEntity?.Name ?? "Unknown Store",
                        AvgScore = Math.Round(x.AvgScore, 1),
                        AuditCount = x.Count,
                        LastSyncedAt = storeEntity?.LastSyncedAt
                    };
                })
                .ToList();

            var topStoresList = storeRankEntries
                .OrderByDescending(x => x.AvgScore)
                .ThenByDescending(x => x.AuditCount)
                .Take(5)
                .ToList();

            // Filter bottom stores to prevent duplicating stores already listed in topStoresList (Satisfies AC-3.1 duplicate assertions)
            var bottomStoresList = storeRankEntries
                .Where(x => !topStoresList.Any(t => t.StoreId == x.StoreId))
                .OrderBy(x => x.AvgScore)
                .ThenBy(x => x.AuditCount)
                .Take(5)
                .ToList();

            // 12-Month Trend
            var localFirstDay = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-11);
            var trendStartDate = new DateTimeOffset(localFirstDay, TimeSpan.Zero);

            var trendRaw = await db.Submissions.AsNoTracking()
                .Where(s =>
                    s.Status == "completed" &&
                    (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                    s.CompletedAt.HasValue &&
                    s.CompletedAt >= trendStartDate &&
                    s.CompletedAt <= now &&
                    (s.ScoringMode == null || s.ScoringMode != "survey") &&
                    s.TotalScore.HasValue &&
                    s.StoreId.HasValue &&
                    assignedStoreIds.Contains(s.StoreId.Value))
                .GroupBy(s => new { s.CompletedAt!.Value.Year, s.CompletedAt.Value.Month })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            var trendList = trendRaw
                .OrderBy(x => x.Year).ThenBy(x => x.Month)
                .Select(x => new AreaTrendPointDto
                {
                    Month = $"{x.Year}-{x.Month:D2}",
                    AvgScore = Math.Round((double)x.AvgScore, 1),
                    AuditCount = x.Count
                })
                .ToList();

            // Category Weaknesses (Last 90 Days)
            var start90DaysAgo = now.AddDays(-90);

            var sectionStats = await db.SubmissionSectionScores.AsNoTracking()
                .Where(ss => ss.CreatedAt >= start90DaysAgo &&
                             ss.CreatedAt <= now &&
                             ss.MaxScore > 0 &&
                             ss.StoreId.HasValue &&
                             assignedStoreIds.Contains(ss.StoreId.Value))
                .GroupBy(ss => new { ss.SectionTitle, TemplateTitle = ss.Submission != null ? ss.Submission.TemplateTitle : "Unknown Template" })
                .Select(g => new
                {
                    CategoryName = g.Key.SectionTitle,
                    TemplateTitle = g.Key.TemplateTitle ?? "Unknown Template",
                    TotalScore = g.Sum(ss => ss.Score),
                    TotalMaxScore = g.Sum(ss => ss.MaxScore),
                    AuditCount = g.Count()
                })
                .ToListAsync(ct);

            var weaknessesList = sectionStats
                .Select(x => new AreaCategoryWeaknessDto
                {
                    CategoryName = x.CategoryName,
                    TemplateName = x.TemplateTitle,
                    AvgScore = x.TotalMaxScore > 0 ? Math.Round((x.TotalScore / x.TotalMaxScore) * 100m, 1) : 0m,
                    AuditCount = x.AuditCount
                })
                .OrderBy(x => x.AvgScore)
                .Take(5)
                .ToList();

            // Action Plan SLA aging buckets
            var openAps = await db.ActionPlans.AsNoTracking()
                .Where(ap => ap.Status == "open" &&
                             ap.CreatedAt <= now &&
                             ap.StoreId.HasValue &&
                             assignedStoreIds.Contains(ap.StoreId.Value))
                .Select(ap => ap.CreatedAt)
                .ToListAsync(ct);

            var bucket_0_7 = 0;
            var bucket_8_30 = 0;
            var bucket_31_90 = 0;
            var bucket_90_plus = 0;

            foreach (var apCreatedAt in openAps)
            {
                var ageInDays = (now - apCreatedAt).TotalDays;
                if (ageInDays <= 7) bucket_0_7++;
                else if (ageInDays <= 30) bucket_8_30++;
                else if (ageInDays <= 90) bucket_31_90++;
                else bucket_90_plus++;
            }

            var actionPlanAgingList = new List<AreaApAgingBucketDto>
            {
                new("0-7d", bucket_0_7),
                new("8-30d", bucket_8_30),
                new("31-90d", bucket_31_90),
                new("90d+", bucket_90_plus)
            };

            // Auditor Productivity
            var auditorStats = await db.Submissions.AsNoTracking()
                .Where(s =>
                    s.Status == "completed" &&
                    (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                    s.CompletedAt.HasValue &&
                    s.CompletedAt >= start30DaysAgo &&
                    s.CompletedAt <= now &&
                    s.AuditorId.HasValue &&
                    s.StoreId.HasValue &&
                    assignedStoreIds.Contains(s.StoreId.Value))
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

            var auditorProductivityList = auditorStats
                .OrderByDescending(x => x.CompletedAudits)
                .Select(x => new AreaAuditorProductivityDto(
                    x.AuditorName,
                    x.CompletedAudits,
                    Math.Round(x.AvgScore, 1)))
                .ToList();

            return TypedResults.Ok(new AreaBodResponse
            {
                IsLiveData = true,
                Kpis = new AreaBodKpiDto
                {
                    TotalAudits = totalAudits,
                    AvgScore = avgScore,
                    CompletionRate = completionRate,
                    OpenActionPlans = openActionPlans,
                    OverdueActionPlans = overdueActionPlans,
                    ActiveStores = activeStores,
                    TotalAuditors = totalAuditors,
                    AvgTtrDays = avgTtrDays
                },
                GoldenStore = goldenStoreObj,
                Trend = trendList,
                TopStores = topStoresList,
                BottomStores = bottomStoresList,
                Weaknesses = weaknessesList,
                ActionPlanAging = actionPlanAgingList,
                AuditorProductivity = auditorProductivityList,
                AllowedActions = allowedActions
            });
        }
    }
}
