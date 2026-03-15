using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// GET /api/areas — list areas. Active-only by default.
/// Pass ?includeInactive=true for admin use cases.
/// </summary>
public static class ListAreas
{
    public static async Task<IResult> HandleAsync(
        HttpContext httpContext,
        AppDbContext db,
        CancellationToken ct)
    {
        var includeInactive = string.Equals(
            httpContext.Request.Query["includeInactive"].FirstOrDefault(),
            "true", StringComparison.OrdinalIgnoreCase);

        var query = db.Areas.AsNoTracking();

        if (!includeInactive)
            query = query.Where(a => a.IsActive);

        var areas = await query
            .OrderBy(a => a.Name)
            .Take(100)
            .Select(a => new AreaDto(a.Id, a.Name, a.Description, a.IsActive, a.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(areas);
    }
}
