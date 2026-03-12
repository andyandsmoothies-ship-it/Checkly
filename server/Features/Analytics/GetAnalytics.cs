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
        var area = httpContext.Request.Query["area"].FirstOrDefault();
        var type = httpContext.Request.Query["type"].FirstOrDefault();

        var query = db.Submissions.AsNoTracking()
            .Where(s => s.Status == "completed" && s.ReviewStatus != "rejected");

        if (!string.IsNullOrEmpty(storeId) && Guid.TryParse(storeId, out var sid))
            query = query.Where(s => s.StoreId == sid);

        if (!string.IsNullOrEmpty(area))
        {
            var storeIds = await db.Stores.AsNoTracking()
                .Where(st => st.AreaCode == area)
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

        var submissions = await query.ToListAsync(ct);

        // KPIs
        var totalAudits = submissions.Count;
        var avgScore = submissions.Count > 0
            ? Math.Round((double)submissions.Where(s => s.TotalScore.HasValue).Average(s => (double)s.TotalScore!.Value), 1)
            : 0.0;

        var openAPs = await db.ActionPlans.CountAsync(ap => ap.Status == "open", ct);
        var overdueAPs = await db.ActionPlans.CountAsync(
            ap => ap.Status == "open" && ap.Deadline.HasValue && ap.Deadline < DateTimeOffset.UtcNow, ct);

        var completionRate = totalAudits > 0
            ? Math.Round((double)submissions.Count(s => s.CompletedAt.HasValue) / totalAudits * 100, 1)
            : 0.0;

        // 6-month trend (monthly avg scores)
        var sixMonthsAgo = DateTimeOffset.UtcNow.AddMonths(-6);
        var trend = submissions
            .Where(s => s.CreatedAt >= sixMonthsAgo && s.TotalScore.HasValue)
            .GroupBy(s => new { s.CreatedAt.Year, s.CreatedAt.Month })
            .Select(g => new
            {
                month = $"{g.Key.Year}-{g.Key.Month:D2}",
                avgScore = Math.Round(g.Average(s => (double)s.TotalScore!.Value), 1),
                count = g.Count()
            })
            .OrderBy(t => t.month)
            .ToList();

        return TypedResults.Ok(new
        {
            kpis = new { totalAudits, avgScore, openAPs, overdueAPs, completionRate },
            trend
        });
    }
}
