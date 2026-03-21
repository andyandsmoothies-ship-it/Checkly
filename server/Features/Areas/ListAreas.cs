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
        CancellationToken ct)
    {
        var areas = await db.Areas
            .AsNoTracking()
            .OrderBy(a => a.Name)
            .Take(100)
            .Select(a => new AreaDto(
                a.Id, a.Name, a.Description,
                a.Stores.Count(s => s.IsActive == true),
                db.Profiles
                    .Where(p => p.AreaId == a.Id)
                    .Join(db.AppUserRoles, p => p.Id, r => r.UserId, (p, r) => new { p.FullName, r.Role })
                    .Where(x => x.Role == "area_manager")
                    .Select(x => x.FullName)
                    .FirstOrDefault(),
                a.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(areas);
    }
}
