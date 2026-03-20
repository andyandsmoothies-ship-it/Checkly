using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// POST /api/admin/stores/{storeId}/transfer — S8 SM transfer protocol.
/// Atomic swap: old SM's StoreId = null, new SM's StoreId = storeId.
/// Reassigns all open ActionPlans from old SM to new SM.
/// </summary>
public static class TransferStoreManager
{
    public record Request(Guid NewManagerId);

    public static async Task<IResult> HandleAsync(
        Guid storeId,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // Validate store exists and is active
        var store = await db.Stores.AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == storeId, ct);
        if (store is null)
            return TypedResults.NotFound(new { error = "Store not found" });
        if (store.IsActive == false)
            return TypedResults.BadRequest(new { error = "Cannot transfer SM to a deactivated store" });
        var newManagerProfile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == request.NewManagerId, ct);
        if (newManagerProfile is null)
            return TypedResults.NotFound(new { error = "New manager profile not found" });

        if (newManagerProfile.StoreId.HasValue && newManagerProfile.StoreId != storeId)
        {
            return TypedResults.Conflict(new
            {
                error = "New manager is already assigned to another store",
                currentStoreId = newManagerProfile.StoreId
            });
        }

        // Verify new manager has store_manager role
        var newManagerRole = await db.AppUserRoles
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.UserId == request.NewManagerId, ct);
        if (newManagerRole?.Role != "store_manager")
        {
            return TypedResults.BadRequest(new { error = "Target user does not have store_manager role" });
        }

        // Find old SM (if any)
        var oldSmProfile = await db.Profiles
            .FirstOrDefaultAsync(p => p.StoreId == storeId
                && db.AppUserRoles.Any(r => r.UserId == p.Id && r.Role == "store_manager")
                && p.Id != request.NewManagerId, ct);

        // Atomic swap
        if (oldSmProfile != null)
        {
            oldSmProfile.StoreId = null;
            oldSmProfile.UpdatedAt = DateTimeOffset.UtcNow;
        }

        newManagerProfile.StoreId = storeId;
        newManagerProfile.UpdatedAt = DateTimeOffset.UtcNow;

        // Reassign open APs from old SM to new SM
        var openAps = await db.ActionPlans
            .Where(ap => ap.StoreId == storeId
                && ap.Status != "closed"
                && (oldSmProfile == null || ap.StoreManagerId == oldSmProfile.Id))
            .ToListAsync(ct);

        foreach (var ap in openAps)
        {
            ap.StoreManagerId = request.NewManagerId;
            ap.StoreManagerName = newManagerProfile.FullName;
            ap.UpdatedAt = DateTimeOffset.UtcNow;
        }

        // Log the admin action
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = "transfer_store_manager",
            Category = "admin",
            EntityType = "store",
            EntityId = storeId,
            Message = $"Transferred store {storeId} from {oldSmProfile?.FullName ?? "none"} to {newManagerProfile.FullName}. Reassigned {openAps.Count} action plans.",
            Path = $"/api/admin/stores/{storeId}/transfer",
            Level = "warning",
            CreatedAt = DateTimeOffset.UtcNow,
        });

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new
        {
            storeId,
            oldManagerId = oldSmProfile?.Id,
            newManagerId = request.NewManagerId,
            actionPlansReassigned = openAps.Count,
        });
    }
}
