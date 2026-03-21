using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// GET /api/areas/{id} — get a single area by ID.
/// </summary>
public static class GetArea
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AppDbContext db,
        CancellationToken ct)
    {
        var area = await db.Areas
            .AsNoTracking()
            .Where(a => a.Id == id)
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
            .FirstOrDefaultAsync(ct);

        return area is null
            ? TypedResults.NotFound()
            : TypedResults.Ok(area);
    }
}
