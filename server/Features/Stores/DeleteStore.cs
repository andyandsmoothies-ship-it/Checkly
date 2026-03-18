using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// DELETE /api/stores/{id} — soft-delete a store (AdminOnly).
/// Sets IsActive = false. Does NOT hard-delete.
/// Profiles referencing this store keep their store_id (historical snapshots).
/// </summary>
public static class DeleteStore
{
    public static async Task<IResult> HandleAsync(Guid id, AppDbContext db, CancellationToken ct)
    {
        var store = await db.Stores.FindAsync([id], ct);
        if (store is null)
            return Results.NotFound();

        store.IsActive = false;
        store.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }
}
