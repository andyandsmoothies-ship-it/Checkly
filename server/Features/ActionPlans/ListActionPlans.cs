using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// GET /api/action-plans — role-based list.
/// admin sees all, store_manager sees their store's plans.
/// </summary>
public static class ListActionPlans
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        var query = db.ActionPlans.AsNoTracking().AsQueryable();

        if (role != "admin")
        {
            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == userId, ct);

            if (profile?.StoreId != null)
                query = query.Where(ap => ap.StoreId == profile.StoreId);
            else
                query = query.Where(ap => ap.StoreManagerId == userId);
        }

        var plans = await query
            .OrderByDescending(ap => ap.CreatedAt)
            .Select(ap => CreateActionPlan.ToDto(ap))
            .ToListAsync(ct);

        return TypedResults.Ok(plans);
    }
}
