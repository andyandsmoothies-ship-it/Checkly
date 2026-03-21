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
            .Select(a => new AreaDto(a.Id, a.Name, a.Description, a.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(areas);
    }
}
