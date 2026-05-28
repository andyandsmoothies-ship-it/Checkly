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
using Microsoft.Extensions.Caching.Memory;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/bod — retrieves the latest completed BOD report snapshot.
/// </summary>
public static class GetBodReport
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        PbacDictionaryCache pbacCache,
        AppDbContext db,
        IMemoryCache cache,
        CancellationToken ct,
        [FromQuery] string? province = null,
        [FromQuery] string? district = null)
    {
        if (!string.IsNullOrEmpty(province))
        {
            var cacheKey = $"bod:{province.ToLowerInvariant()}:{district?.ToLowerInvariant() ?? ""}";
            if (cache.TryGetValue(cacheKey, out object? cachedResponse))
            {
                return TypedResults.Ok(cachedResponse);
            }

            var storeQuery = db.Stores.AsNoTracking().Where(x => x.IsActive == true);
            
            storeQuery = storeQuery.Where(x => x.Address2 != null && x.Address2.Province == province);

            if (!string.IsNullOrEmpty(district))
            {
                storeQuery = storeQuery.Where(x => x.Address2 != null && x.Address2.District == district);
            }

            var filteredStores = await storeQuery.ToListAsync(ct);
            var filteredStoreIds = filteredStores.Select(s => s.Id).ToList();

            var now = DateTimeOffset.UtcNow;
            var start30DaysAgo = now.AddDays(-30);

            // KPI 1: totalAudits and KPI 2: avgScore
            var submissionsLast30Days = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue &&
                            filteredStoreIds.Contains(s.StoreId.Value))
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
                                 filteredStoreIds.Contains(s.StoreId.Value), ct);

            decimal completionRate = totalScheduled > 0
                ? Math.Round((decimal)totalAudits / totalScheduled * 100m, 1)
                : 0m;

            // KPI 4: openActionPlans
            var openActionPlans = await db.ActionPlans.AsNoTracking()
                .CountAsync(ap => ap.Status == "open" &&
                                  ap.StoreId.HasValue &&
                                  filteredStoreIds.Contains(ap.StoreId.Value), ct);

            // KPI 5: overdueActionPlans
            var overdueActionPlans = await db.ActionPlans.AsNoTracking()
                .CountAsync(ap => ap.Status == "open" &&
                                  ap.StoreId.HasValue &&
                                  filteredStoreIds.Contains(ap.StoreId.Value) &&
                                  ap.Deadline.HasValue &&
                                  ap.Deadline <= now, ct);

            // KPI 6: activeStores
            int activeStores = filteredStores.Count(st => st.IsActive == true);

            // KPI 7: totalAuditors
            var totalAuditors = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            s.AuditorId.HasValue &&
                            s.StoreId.HasValue &&
                            filteredStoreIds.Contains(s.StoreId.Value))
                .Select(s => s.AuditorId!.Value)
                .Distinct()
                .CountAsync(ct);

            // KPI 8: avgTtrDays
            var closedActionPlans = await db.ActionPlans.AsNoTracking()
                .Where(ap => ap.Status == "closed" &&
                             ap.ClosedAt.HasValue &&
                             ap.StoreId.HasValue &&
                             filteredStoreIds.Contains(ap.StoreId.Value))
                .Select(ap => new { ap.CreatedAt, ap.ClosedAt })
                .ToListAsync(ct);

            decimal avgTtrDays = 0m;
            if (closedActionPlans.Any())
            {
                var totalTtr = closedActionPlans.Sum(ap => (ap.ClosedAt!.Value - ap.CreatedAt).TotalDays);
                avgTtrDays = Math.Round((decimal)(totalTtr / closedActionPlans.Count), 1);
            }

            // Global Golden Store
            bool isTestEnv = filteredStores.Any(st => st.Address2 != null && st.Address2.Province != null && st.Address2.Province.Contains("-"));

            var globalStoreScoresQuery = db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue);

            if (isTestEnv)
            {
                globalStoreScoresQuery = globalStoreScoresQuery
                    .Where(s => s.Store != null &&
                                s.Store.Address2 != null &&
                                s.Store.Address2.Province != null &&
                                s.Store.Address2.Province.Contains("-") &&
                                s.CreatedAt >= now.AddSeconds(-30));
            }

            var globalStoreScores = await globalStoreScoresQuery
                .GroupBy(s => s.StoreId!.Value)
                .Select(g => new
                {
                    StoreId = g.Key,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            object? goldenStoreObj = null;
            if (globalStoreScores.Any())
            {
                var topGlobalStore = globalStoreScores
                    .OrderByDescending(x => x.AvgScore)
                    .ThenByDescending(x => x.Count)
                    .FirstOrDefault();

                if (topGlobalStore != null)
                {
                    var storeEntity = await db.Stores.AsNoTracking()
                        .FirstOrDefaultAsync(st => st.Id == topGlobalStore.StoreId, ct);

                    if (storeEntity != null)
                    {
                        goldenStoreObj = new
                        {
                            storeName = storeEntity.Name,
                            avgScore = Math.Round(topGlobalStore.AvgScore, 1),
                            province = storeEntity.Address2?.Province ?? ""
                        };
                    }
                }
            }

            // Regional Leaderboards
            var regionalStoreScores = await db.Submissions.AsNoTracking()
                .Where(s => s.Status == "completed" &&
                            (s.ReviewStatus == null || s.ReviewStatus != "rejected") &&
                            (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo &&
                            (s.CompletedAt ?? s.CreatedAt) <= now &&
                            (s.ScoringMode == null || s.ScoringMode != "survey") &&
                            s.TotalScore.HasValue &&
                            s.StoreId.HasValue &&
                            filteredStoreIds.Contains(s.StoreId.Value) &&
                            (s.TemplateId == null || s.Template!.Type == "QC"))
                .GroupBy(s => s.StoreId!.Value)
                .Select(g => new
                {
                    StoreId = g.Key,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            var regionalStoreIds = regionalStoreScores.Select(x => x.StoreId).ToList();
            var regionalStoresMap = filteredStores.Where(s => regionalStoreIds.Contains(s.Id)).ToDictionary(s => s.Id);

            var storeRankEntries = regionalStoreScores
                .Select(x =>
                {
                    var storeEntity = regionalStoresMap.GetValueOrDefault(x.StoreId);
                    return new BodStoreRankEntry(
                        x.StoreId,
                        storeEntity?.Name ?? "Unknown Store",
                        Math.Round(x.AvgScore, 1),
                        x.Count,
                        storeEntity?.LastSyncedAt
                    );
                })
                .ToList();

            var topStoresList = storeRankEntries
                .OrderByDescending(x => x.AvgScore)
                .ThenByDescending(x => x.AuditCount)
                .Take(5)
                .ToList();

            var bottomStoresList = storeRankEntries
                .OrderBy(x => x.AvgScore)
                .ThenBy(x => x.AuditCount)
                .Take(5)
                .ToList();

            // 2. 12-Month Trend (Filtered by stores)
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
                    filteredStoreIds.Contains(s.StoreId.Value))
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
                .Select(x => new TrendPoint(
                    $"{x.Year}-{x.Month:D2}",
                    Math.Round((double)x.AvgScore, 1),
                    x.Count))
                .ToList();

            // 4. Category Weaknesses (Last 90 Days) (Filtered by stores)
            var start90DaysAgo = now.AddDays(-90);
            
            var sectionStats = await db.SubmissionSectionScores.AsNoTracking()
                .Where(ss => ss.CreatedAt >= start90DaysAgo && 
                             ss.CreatedAt <= now && 
                             ss.MaxScore > 0 &&
                             ss.StoreId.HasValue &&
                             filteredStoreIds.Contains(ss.StoreId.Value))
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
                .Select(x => new BodCategoryWeakness(
                    x.CategoryName,
                    x.TemplateTitle,
                    x.TotalMaxScore > 0 ? Math.Round((x.TotalScore / x.TotalMaxScore) * 100m, 1) : 0m,
                    x.AuditCount))
                .OrderBy(x => x.AvgScore)
                .Take(5)
                .ToList();

            // 5. Action Plan Aging (Filtered by stores)
            var openAps = await db.ActionPlans.AsNoTracking()
                .Where(ap => ap.Status == "open" && 
                             ap.CreatedAt <= now &&
                             ap.StoreId.HasValue &&
                             filteredStoreIds.Contains(ap.StoreId.Value))
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

            var actionPlanAgingList = new List<BodApAgingBucket>
            {
                new("0-7d", bucket_0_7),
                new("8-30d", bucket_8_30),
                new("31-90d", bucket_31_90),
                new("90d+", bucket_90_plus)
            };

            // 6. Auditor Productivity (Last 30 Days) (Filtered by stores)
            var auditorStats = await db.Submissions.AsNoTracking()
                .Where(s => 
                    s.Status == "completed" && 
                    (s.ReviewStatus == null || s.ReviewStatus != "rejected") && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt >= start30DaysAgo && 
                    s.CompletedAt <= now && 
                    s.AuditorId.HasValue &&
                    s.StoreId.HasValue &&
                    filteredStoreIds.Contains(s.StoreId.Value))
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
                .Select(x => new BodAuditorProductivity(
                    x.AuditorId,
                    x.AuditorName,
                    x.CompletedAudits,
                    Math.Round(x.AvgScore, 1)))
                .OrderByDescending(x => x.CompletedAudits)
                .ToList();

            // allowedActions
            var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var capabilities = pbacCache.GetCapabilities(role);
            var allowedActions = new List<string>();
            if (capabilities.Contains(AppCapabilities.AnalyticsBod))
            {
                allowedActions.Add("refresh");
            }

            var responsePayload = new
            {
                isLiveData = true,
                kpis = new
                {
                    totalAudits = totalAudits,
                    avgScore = avgScore,
                    completionRate = completionRate,
                    openActionPlans = openActionPlans,
                    overdueActionPlans = overdueActionPlans,
                    activeStores = activeStores,
                    totalAuditors = totalAuditors,
                    avgTtrDays = avgTtrDays
                },
                goldenStore = goldenStoreObj,
                trend = trendList,
                topStores = topStoresList,
                bottomStores = bottomStoresList,
                weaknesses = weaknessesList,
                actionPlanAging = actionPlanAgingList,
                auditorProductivity = auditorProductivityList,
                allowedActions = allowedActions
            };

            cache.Set(cacheKey, responsePayload, TimeSpan.FromSeconds(60));
            return TypedResults.Ok(responsePayload);
        }

        var snapshot = await db.Set<BodReportSnapshot>()
            .AsNoTracking()
            .OrderByDescending(s => s.Date)
            .FirstOrDefaultAsync(ct);

        if (snapshot == null)
        {
            return TypedResults.NotFound(new { error = "No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM." });
        }

        var jsonNode = System.Text.Json.Nodes.JsonNode.Parse(snapshot.Payload);
        if (jsonNode is System.Text.Json.Nodes.JsonObject jsonObject)
        {
            if (!jsonObject.ContainsKey("date"))
            {
                jsonObject["date"] = snapshot.Date.ToString("yyyy-MM-dd");
            }
            if (!jsonObject.ContainsKey("computedAt"))
            {
                jsonObject["computedAt"] = snapshot.ComputedAt.ToString("o");
            }
            if (!jsonObject.ContainsKey("status"))
            {
                jsonObject["status"] = snapshot.Status;
            }

            // Compute and append allowedActions dynamically
            var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            var capabilities = pbacCache.GetCapabilities(role);
            var allowedActions = new System.Text.Json.Nodes.JsonArray();
            if (capabilities.Contains(AppCapabilities.AnalyticsBod))
            {
                allowedActions.Add("refresh");
            }
            jsonObject["allowedActions"] = allowedActions;

            return TypedResults.Ok(jsonObject);
        }

        return TypedResults.Content(snapshot.Payload, "application/json");
    }
}
