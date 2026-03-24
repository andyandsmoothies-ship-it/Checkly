using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// DELETE /api/areas/{id} — soft-delete an area (AdminOnly).
/// Cascade guard: returns 409 Conflict if the area has active stores.
/// Returns 404 if the area doesn't exist.
/// Returns 204 NoContent on success.
/// </summary>
public static class DeleteArea
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AppDbContext db,
        CancellationToken ct)
    {
        // Cascade guard: refuse to delete if area has active stores
        var hasActiveStores = await db.Stores
            .AnyAsync(s => s.AreaId == id && s.IsActive == true, ct);

        if (hasActiveStores)
            return TypedResults.Conflict(new { error = "Cannot delete area with active stores" });

        var area = await db.Areas.FindAsync([id], ct);

        if (area is null || area.IsActive == false)
            return TypedResults.NotFound(new { error = "Area not found" });

        area.IsActive = false;
        area.UpdatedAt = DateTimeOffset.UtcNow;

        await db.SaveChangesAsync(ct);

        return TypedResults.NoContent();
    }
}
