using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// GET /api/areas — list all areas.
/// </summary>
public static class ListAreas
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {

        var page = int.TryParse(httpContext.Request.Query["page"], out var pg) ? Math.Max(1, pg) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        // Query 2: fetch areas, then map manager name in-memory via dict (O(1) per area).
        var areaQuery = db.Areas
            .AsNoTracking()
            .OrderBy(a => a.Name);

        var total = await areaQuery.CountAsync(ct);

        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<AreaDto>([], total, page, pageSize));

        var areaRows = await areaQuery
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new { 
                a.Id, 
                a.Name, 
                a.Description, 
                StoreCount = a.Stores.Count(s => s.IsActive == true), 
                a.CreatedAt,
                ManagerName = db.Profiles
                    .Where(p => p.AreaId == a.Id && db.AppUserRoles.Any(r => r.UserId == p.Id && r.Role == "area_manager"))
                    .Select(p => p.FullName)
                    .FirstOrDefault()
            })
            .ToListAsync(ct);

        var areas = areaRows
            .Select(a => new AreaDto(
                a.Id, a.Name, a.Description, a.StoreCount,
                a.ManagerName,
                a.CreatedAt))
            .ToList();

        return TypedResults.Ok(new PagedResult<AreaDto>(areas, total, page, pageSize));
    }
}
