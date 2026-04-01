using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common;

/// <summary>
/// Reusable IDOR guard for submission-scoped resources (submissions, photos, etc.).
/// Checks whether the current user has role-appropriate access to a submission.
/// </summary>
public static class SubmissionAccessGuard
{
    /// <summary>
    /// Returns true if the user can access a submission with the given storeId and auditorId.
    /// </summary>
    public static async Task<bool> CanAccessAsync(
        ClaimsPrincipal user, Guid? storeId, Guid? areaId, Guid? auditorId,
        AppDbContext db, CancellationToken ct)
    {
        if (!Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return false;

        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        return role switch
        {
            "admin" => true,
            "auditor" => auditorId == userId,
            "store_manager" => await IsUserStoreAsync(userId, storeId, db, ct),
            "area_manager" => await IsUserAreaAsync(userId, storeId, areaId, db, ct),
            _ => false
        };
    }

    private static async Task<bool> IsUserStoreAsync(Guid userId, Guid? storeId, AppDbContext db, CancellationToken ct)
    {
        if (storeId is null) return false;
        var profile = await db.Profiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == userId, ct);
        return profile?.StoreId == storeId;
    }

    private static async Task<bool> IsUserAreaAsync(Guid userId, Guid? storeId, Guid? areaId, AppDbContext db, CancellationToken ct)
    {
        if (storeId is null && areaId is null) return false;
        var profile = await db.Profiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == userId, ct);
        if (profile?.AreaId is null) return false;

        if (areaId.HasValue) return areaId.Value == profile.AreaId;

        var store = await db.Stores.AsNoTracking().FirstOrDefaultAsync(s => s.Id == storeId, ct);
        return store?.AreaId == profile.AreaId;
    }
}
