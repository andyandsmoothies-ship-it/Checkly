using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// PUT /api/areas/{id} — admin-only. Updates Name and/or Description.
/// </summary>
public static class UpdateArea
{
    public record Request(string? Name, string? Description, bool? IsActive);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        var area = await db.Areas.FirstOrDefaultAsync(a => a.Id == id, ct);
        if (area is null)
            return TypedResults.NotFound(new { error = "Area not found" });

        if (request.Name != null)
            area.Name = request.Name.Trim();

        if (request.Description != null)
            area.Description = request.Description.Trim();

        if (request.IsActive.HasValue)
            area.IsActive = request.IsActive.Value;

        area.UpdatedAt = DateTimeOffset.UtcNow;

        await db.SaveChangesAsync(ct);

        // Reload with counts for consistent response
        var dto = await db.Areas
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
                a.CreatedAt,
                a.IsActive))
            .FirstAsync(ct);

        return TypedResults.Ok(dto);
    }
}
