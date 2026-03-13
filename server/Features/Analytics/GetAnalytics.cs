using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics — KPI cards + 6-month trend data with filters.
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

        // ── KPIs (SQL scalar queries — zero rows loaded into memory) ──
        var totalAudits = await query.CountAsync(ct);

        var scoredQuery = query.Where(s => s.TotalScore.HasValue);
        var scoredCount = await scoredQuery.CountAsync(ct);
        var avgScore = scoredCount > 0
            ? Math.Round((double)await scoredQuery.AverageAsync(s => s.TotalScore!.Value, ct), 1)
            : 0.0;

        var completedCount = await query.CountAsync(s => s.CompletedAt.HasValue, ct);
        var completionRate = totalAudits > 0
            ? Math.Round((double)completedCount / totalAudits * 100, 1)
            : 0.0;

        var openAPs = await db.ActionPlans.CountAsync(ap => ap.Status == "open", ct);
        var overdueAPs = await db.ActionPlans.CountAsync(
            ap => ap.Status == "open" && ap.Deadline.HasValue && ap.Deadline < DateTimeOffset.UtcNow, ct);

        // ── 6-month trend (SQL GroupBy — returns max 6 rows, not 100K) ──
        var sixMonthsAgo = DateTimeOffset.UtcNow.AddMonths(-6);
        var trend = await query
            .Where(s => s.CreatedAt >= sixMonthsAgo && s.TotalScore.HasValue)
            .GroupBy(s => new { s.CreatedAt.Year, s.CreatedAt.Month })
            .Select(g => new TrendPoint(
                g.Key.Year + "-" + g.Key.Month.ToString().PadLeft(2, '0'),
                Math.Round((double)g.Average(s => s.TotalScore!.Value), 1),
                g.Count()))
            .OrderBy(t => t.Month)
            .ToListAsync(ct);

        return TypedResults.Ok(new AnalyticsResponse(
            new AnalyticsKpis(totalAudits, avgScore, openAPs, overdueAPs, completionRate),
            trend));
    }
}
