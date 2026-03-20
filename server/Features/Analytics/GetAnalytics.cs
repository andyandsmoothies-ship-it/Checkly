using System.Security.Claims;
using Checkly.Api.Common.Persistence;
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
        var type = httpContext.Request.Query["type"].FirstOrDefault();
        var scoringModeFilter = httpContext.Request.Query["scoringMode"].FirstOrDefault();

        var query = db.Submissions.AsNoTracking()
            .Where(s => s.Status == "completed" && s.ReviewStatus != "rejected");

        if (!string.IsNullOrEmpty(storeId) && Guid.TryParse(storeId, out var sid))
            query = query.Where(s => s.StoreId == sid);

        var areaIdStr = httpContext.Request.Query["areaId"].FirstOrDefault();
        if (!string.IsNullOrEmpty(areaIdStr) && Guid.TryParse(areaIdStr, out var areaIdParsed))
        {
            var storeIds = await db.Stores.AsNoTracking()
                .Where(st => st.AreaId == areaIdParsed)
                .Select(st => st.Id)
                .ToListAsync(ct);
            query = query.Where(s => s.StoreId.HasValue && storeIds.Contains(s.StoreId.Value));
        }

        if (!string.IsNullOrEmpty(type))
        {
            var templateIds = await db.Templates.AsNoTracking()
                .Where(t => t.Type == type)
                .Select(t => t.Id)
                .ToListAsync(ct);
            query = query.Where(s => s.TemplateId.HasValue && templateIds.Contains(s.TemplateId.Value));
        }

        // Scoring mode filter (new)
        if (!string.IsNullOrEmpty(scoringModeFilter))
            query = query.Where(s => s.ScoringMode == scoringModeFilter);

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

        var openAPs = await db.ActionPlans.CountAsync(ap => ap.Status == "open", ct);
        var overdueAPs = await db.ActionPlans.CountAsync(
            ap => ap.Status == "open" && ap.Deadline.HasValue && ap.Deadline < DateTimeOffset.UtcNow, ct);

        // ── 6-month trend (GroupBy server-side, project in memory) ──
        var sixMonthsAgo = DateTimeOffset.UtcNow.AddMonths(-6);
        var trendRaw = await query
            .Where(s => s.CreatedAt >= sixMonthsAgo && s.TotalScore.HasValue)
            .GroupBy(s => new { Year = s.CreatedAt.Year, Month = s.CreatedAt.Month })
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

        // ── Section breakdown from relational table (GroupBy server, project in memory) ──
        var sectionRaw = await db.SubmissionSectionScores
            .AsNoTracking()
            .Where(ss => ss.MaxScore > 0)
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

        return TypedResults.Ok(new AnalyticsResponse(
            new AnalyticsKpis(totalAudits, scoredCount, totalSurveys, avgScore, openAPs, overdueAPs, completionRate),
            trend,
            sectionBreakdown));
    }
}
