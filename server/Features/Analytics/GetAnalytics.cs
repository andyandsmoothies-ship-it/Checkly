using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics — KPI cards + 6-month trend data + section breakdown with filters.
/// </summary>
public static class GetAnalytics
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var storeId = httpContext.Request.Query["storeId"].FirstOrDefault();
        var province = httpContext.Request.Query["province"].FirstOrDefault();
        var type = httpContext.Request.Query["type"].FirstOrDefault();
        var scoringModeFilter = httpContext.Request.Query["scoringMode"].FirstOrDefault();

        // OBS-2: Read date range filter params sent by Flutter analytics_api_service.dart.
        // Without these, "Last 30 days" in the UI silently returns all-time data in online mode.
        DateTimeOffset? startDateFilter = null;
        DateTimeOffset? endDateFilter = null;
        if (DateTimeOffset.TryParse(httpContext.Request.Query["startDate"].FirstOrDefault(), out var parsedStart))
            startDateFilter = parsedStart;
        if (DateTimeOffset.TryParse(httpContext.Request.Query["endDate"].FirstOrDefault(), out var parsedEnd))
            endDateFilter = parsedEnd;


        // Pre-declared for AM tenancy: populated in the area_manager block below, consumed after query init.
        List<Guid> amAssignedStoreIds = [];

        // ── WARN-SEC-05: Enforce role-based data tenancy ──────────────────────
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
        var userIdStr = user.FindFirstValue(ClaimTypes.NameIdentifier);

        // Admins have global visibility. Other roles must be strictly scoped.
        if (role == "admin")
        {
            // Bypass tenancy checks (global scope)
        }
        else if ((role == "store_manager" || role == "area_manager") && Guid.TryParse(userIdStr, out var callerId))
        {
            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == callerId, ct);

            if (role == "store_manager")
            {
                // Profile must have an assigned store — otherwise the data makes no sense.
                if (profile?.StoreId is null)
                    return TypedResults.Forbid();

                // If the caller explicitly requested a different store, that is an IDOR attempt.
                if (!string.IsNullOrEmpty(storeId) &&
                    Guid.TryParse(storeId, out var requestedStore) &&
                    requestedStore != profile.StoreId.Value)
                    return TypedResults.Forbid();

                // Force scope to the manager's own store.
                storeId = profile.StoreId.Value.ToString();
            }
            else // area_manager
            {
                // Scope to stores assigned via ProfileStoreAssignment junction.
                // AMs are assigned per-store via the junction table.
                // This matches the canonical pattern in ListActionPlans.cs:42-55.
                amAssignedStoreIds = await db.ProfileStoreAssignments
                    .Where(a => a.ProfileId == callerId)
                    .Select(a => a.StoreId)
                    .ToListAsync(ct);

                if (amAssignedStoreIds.Count > 0)
                {
                    // Overwrite any caller-supplied storeId to prevent IDOR.
                    storeId = null;
                }
                // else: AM has no assignments — global read (no filter applied).
            }
        }
        else
        {
            // Failsafe: Any new or unknown role (e.g. auditor) gets no data unless explicitly bypassed above.
            return TypedResults.Forbid();
        }
        // ──────────────────────────────────────────────────────────────────────

        var query = db.Submissions.AsNoTracking()
            .Where(s => s.Status == "completed" && s.ReviewStatus != "rejected");

        // AM store-scope: apply after query is declared (IDs were resolved in the tenancy block above).
        if (amAssignedStoreIds.Count > 0)
            query = query.Where(s => s.StoreId.HasValue && amAssignedStoreIds.Contains(s.StoreId.Value));

        // Pre-declare sid so it is reusable by the section score filter block below (C-01).
        var sid = Guid.Empty;
        if (!string.IsNullOrEmpty(storeId) && Guid.TryParse(storeId, out sid))
            query = query.Where(s => s.StoreId == sid);

        // Hoist subquery references so they are reusable by the section score query below.
        IQueryable<Guid>? storeSubquery = null;
        IQueryable<Guid>? templateSubquery = null;

        if (!string.IsNullOrEmpty(province))
        {
            storeSubquery = db.Stores.AsNoTracking()
                // OBS-6: Exclude deactivated stores from province analytics.
                // IsActive is bool? — use == true to treat null as inactive.
                .Where(st => st.Address2 != null && st.Address2.Province == province && st.IsActive == true)
                .Select(st => st.Id);
            query = query.Where(s => s.StoreId.HasValue && storeSubquery.Contains(s.StoreId.Value));
        }


        if (!string.IsNullOrEmpty(type))
        {
            templateSubquery = db.Templates.AsNoTracking()
                .Where(t => t.Type == type)
                .Select(t => t.Id);
            query = query.Where(s => s.TemplateId.HasValue && templateSubquery.Contains(s.TemplateId.Value));
        }

        // Scoring mode filter (new)
        if (!string.IsNullOrEmpty(scoringModeFilter))
            query = query.Where(s => s.ScoringMode == scoringModeFilter);

        // OBS-2: Apply date range filter. Both bounds are optional and independent.
        if (startDateFilter.HasValue)
            query = query.Where(s => s.CreatedAt >= startDateFilter.Value);
        if (endDateFilter.HasValue)
            query = query.Where(s => s.CreatedAt <= endDateFilter.Value);

        // ── KPIs (SQL scalar queries — zero rows loaded into memory) ──
        var totalAudits = await query.CountAsync(ct);

        // Scored submissions = non-survey with a TotalScore
        var scoredQuery = query.Where(s => s.ScoringMode != "survey" && s.TotalScore.HasValue);
        var scoredCount = await scoredQuery.CountAsync(ct);
        var avgScore = scoredCount > 0
            ? Math.Round((double)await scoredQuery.AverageAsync(s => s.TotalScore!.Value, ct), 1)
            : 0.0;

        // Survey count
        var totalSurveys = await query.CountAsync(s => s.ScoringMode == "survey", ct);

        var completedCount = await query.CountAsync(s => s.CompletedAt.HasValue, ct);
        var completionRate = totalAudits > 0
            ? Math.Round((double)completedCount / totalAudits * 100, 1)
            : 0.0;

        var apBase = db.ActionPlans.AsNoTracking();
        if (!string.IsNullOrEmpty(storeId) && Guid.TryParse(storeId, out var apSid))
            apBase = apBase.Where(ap => ap.StoreId == apSid);
        else if (storeSubquery is not null)
            apBase = apBase.Where(ap => ap.StoreId.HasValue && storeSubquery.Contains(ap.StoreId.Value));

        var openAPs = await apBase.CountAsync(ap => ap.Status == "open", ct);
        var overdueAPs = await apBase.CountAsync(
            ap => ap.Status == "open" && ap.Deadline.HasValue && ap.Deadline < DateTimeOffset.UtcNow, ct);

        // ── 6-month trend (GroupBy server-side, project in memory) ──
        var sixMonthsAgo = DateTimeOffset.UtcNow.AddMonths(-6);
        var trendRaw = await query
            .Where(s => s.CreatedAt >= sixMonthsAgo && s.TotalScore.HasValue)
            .GroupBy(s => new { s.CreatedAt.Year, s.CreatedAt.Month })
            .Select(g => new
            {
                g.Key.Year,
                g.Key.Month,
                AvgScore = g.Average(s => s.TotalScore!.Value),
                Count = g.Count()
            })
            .OrderBy(x => x.Year).ThenBy(x => x.Month)
            .ToListAsync(ct);

        var trend = trendRaw
            .Select(x => new TrendPoint(
                $"{x.Year}-{x.Month:D2}",
                Math.Round((double)x.AvgScore, 1),
                x.Count))
            .ToList();

        // ── Section breakdown — C-01 Fix: apply same store/area/type filters ──
        // WARN-DB-03 Fix: scope to last 90 days to prevent full table scan as data grows.
        var ninetyDaysAgo = DateTimeOffset.UtcNow.AddDays(-90);
        var sectionScoreQuery = db.SubmissionSectionScores
            .AsNoTracking()
            .Where(ss => ss.MaxScore > 0 && ss.CreatedAt >= ninetyDaysAgo);

        // Mirror storeId filter — reuse `sid` already parsed at line 25 (avoids CS0128 duplicate declaration).
        var storeIdParsed = !string.IsNullOrEmpty(storeId) && Guid.TryParse(storeId, out sid);
        if (storeIdParsed)
            sectionScoreQuery = sectionScoreQuery.Where(ss => ss.StoreId == sid);

        // Mirror store subquery filter (re-use hoisted storeSubquery)
        if (storeSubquery is not null)
            sectionScoreQuery = sectionScoreQuery.Where(ss => ss.StoreId.HasValue && storeSubquery.Contains(ss.StoreId.Value));

        // Mirror type filter (re-use hoisted templateSubquery)
        if (templateSubquery is not null)
            sectionScoreQuery = sectionScoreQuery.Where(ss => ss.TemplateId.HasValue && templateSubquery.Contains(ss.TemplateId.Value));

        var sectionRaw = await sectionScoreQuery
            .GroupBy(ss => ss.SectionTitle)
            .Select(g => new
            {
                Section = g.Key,
                TotalScore = g.Sum(ss => ss.Score),
                TotalMaxScore = g.Sum(ss => ss.MaxScore),
                Count = g.Count()
            })
            .OrderByDescending(x => x.Count)
            .ToListAsync(ct);

        var sectionBreakdown = sectionRaw
            .Select(x => new SectionScore(
                x.Section,
                Math.Round((double)x.TotalScore / (double)x.TotalMaxScore * 100.0, 1),
                x.Count))
            .ToList();

        // ── Slice 2: Insights & Radar (Province Benchmark Integration) ──
        var (insights, radarData, insightsStale) = await GetAnalyticsInsightsResolver.ResolveAsync(
            db, province, storeIdParsed, sid, sectionBreakdown, avgScore, totalAudits, overdueAPs, ct);

        return TypedResults.Ok(new AnalyticsResponse(
            new AnalyticsKpis(totalAudits, scoredCount, totalSurveys, avgScore, openAPs, overdueAPs, completionRate),
            trend,
            sectionBreakdown,
            insights,
            radarData,
            insightsStale));
    }
}
