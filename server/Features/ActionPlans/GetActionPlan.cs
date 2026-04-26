using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// GET /api/action-plans/{id} — fetch a single action plan by ID.
/// Role-based IDOR guard mirrors ListActionPlans.cs:
///   admin → any plan
///   store_manager → only plans for their assigned store
///   area_manager → only plans for stores in their area
///   auditor → only plans linked to their own submissions
///   other → 404 by design (no information leakage)
/// Returns 404 if not found or caller has no access.
/// </summary>
public static class GetActionPlan
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        var plan = await db.ActionPlans
            .AsNoTracking()
            .FirstOrDefaultAsync(ap => ap.Id == id, ct);

        if (plan is null)
            return TypedResults.NotFound();

        // Role-based access check — same logic as ListActionPlans.cs
        if (role != "admin")
        {
            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == userId, ct);

            var hasAccess = role switch
            {
                "store_manager" => profile?.StoreId != null && plan.StoreId == profile.StoreId,
                "area_manager" => profile?.AreaId != null && await db.Stores
                    .AnyAsync(s => s.Id == plan.StoreId && s.AreaId == profile.AreaId, ct),
                "auditor" => plan.SubmissionId != null && await db.Submissions
                    .AnyAsync(s => s.Id == plan.SubmissionId && s.AuditorId == userId, ct),
                _ => false,
            };

            if (!hasAccess)
                return TypedResults.NotFound(); // 404 > 403 to avoid IDOR enumeration
        }

        return TypedResults.Ok(CreateActionPlan.ToDto(plan));
    }
}
