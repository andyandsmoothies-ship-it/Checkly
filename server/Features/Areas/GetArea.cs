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
            .Select(a => new AreaDto(a.Id, a.Name, a.Description, a.IsActive, a.CreatedAt))
            .FirstOrDefaultAsync(ct);

        return area is null
            ? TypedResults.NotFound()
            : TypedResults.Ok(area);
    }
}
