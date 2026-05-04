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
///   area_manager  → submissions for all stores assigned via ProfileStoreAssignment
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
                var assignedStoreSubquery = db.ProfileStoreAssignments
                    .Where(a => a.ProfileId == userId)
                    .Select(a => a.StoreId);
                query = query.Where(s => s.StoreId.HasValue && assignedStoreSubquery.Contains(s.StoreId.Value));
                break;

            default:
                // Unknown or unmapped role → zero results (fail-safe)
                query = query.Where(_ => false);
                break;
        }

        return query;
    }
}
