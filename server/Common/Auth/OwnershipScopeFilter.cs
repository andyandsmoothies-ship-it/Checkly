using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// Applies row-level ownership scoping to a Submissions queryable.
/// Extracted from ListSubmissions to make the scope rule reusable across handlers
/// (GetSubmission, UpdateSubmission, etc.) without copy-paste drift.
///
/// Role → Scope mapping:
///   admin         → all rows (no filter)
///   auditor       → own submissions (AuditorId == userId)
///   store_manager → submissions for their store (Profile.StoreId)
///   area_manager  → submissions for all stores in their area (Profile.AreaId → Stores)
///   (other)       → no rows (defensive fallback)
///
/// Called AFTER the capability gate (RequireCapability) has already passed.
/// </summary>
public static class OwnershipScopeFilter
{
    public static async Task<IQueryable<Submission>> ApplyAsync(
        IQueryable<Submission> query,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;

        switch (role)
        {
            case "admin":
                // No filter — admin sees all submissions
                break;

            case "auditor":
                query = query.Where(s => s.AuditorId == userId);
                break;

            case "store_manager":
                var smProfile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.Id == userId, ct);
                query = smProfile?.StoreId != null
                    ? query.Where(s => s.StoreId == smProfile.StoreId)
                    : query.Where(_ => false); // No store → no results (defensive)
                break;

            case "area_manager":
                var amProfile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.Id == userId, ct);
                if (amProfile?.AreaId != null)
                {
                    var storeIds = await db.Stores
                        .Where(s => s.AreaId == amProfile.AreaId)
                        .Select(s => s.Id)
                        .ToListAsync(ct);
                    query = query.Where(s => storeIds.Contains(s.StoreId!.Value));
                }
                else
                {
                    query = query.Where(_ => false); // No area → no results (defensive)
                }
                break;

            default:
                // Unknown or unmapped role → zero results (fail-safe)
                query = query.Where(_ => false);
                break;
        }

        return query;
    }
}
