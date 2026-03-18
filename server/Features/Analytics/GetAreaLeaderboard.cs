using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/area-leaderboard?areaId={areaId}
/// Returns stores in the given area with their analytics snapshot metrics.
/// </summary>
public static class GetAreaLeaderboard
{
    public static async Task<IResult> HandleAsync(
        HttpContext httpContext,
        AppDbContext db,
        CancellationToken ct)
    {
        var areaIdStr = httpContext.Request.Query["areaId"].FirstOrDefault();
        if (string.IsNullOrEmpty(areaIdStr) || !Guid.TryParse(areaIdStr, out var areaId))
            return TypedResults.BadRequest(new { error = "areaId query parameter is required" });

        var stores = await (
            from s in db.Stores.AsNoTracking()
            join snap in db.StoreAnalyticsSnapshots.AsNoTracking()
                on s.Id equals snap.StoreId into snapJoin
            from snap in snapJoin.DefaultIfEmpty()
            where s.AreaId == areaId
            select new
            {
                storeId = s.Id,
                name = s.Name,
                avgScore30d = snap != null ? snap.AvgScore30d : 0m,
                totalAudits30d = snap != null ? snap.TotalAudits30d : 0
            })
            .OrderByDescending(x => x.avgScore30d)
            .Take(100)
            .ToListAsync(ct);

        return TypedResults.Ok(new { stores });
    }
}
