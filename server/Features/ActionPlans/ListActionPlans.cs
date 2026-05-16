using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// GET /api/action-plans — role-based list.
/// admin sees all, store_manager sees their store's plans,
/// area_manager sees all plans for stores assigned via ProfileStoreAssignment.
/// Auditors and unknown roles receive an empty list by design —
/// auditors access plan details via submission review, not this list endpoint.
/// </summary>
public static class ListActionPlans
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        [Microsoft.AspNetCore.Mvc.FromServices] PbacDictionaryCache pbacCache,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
        var callerCapabilities = pbacCache.GetCapabilities(role);

        var query = db.ActionPlans.AsNoTracking().AsQueryable();

        if (role != "admin")
        {
            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == userId, ct);

            if (role == "store_manager" && profile?.StoreId != null)
            {
                // SM sees all plans for their assigned store, regardless of StoreManagerId snapshot.
                query = query.Where(ap => ap.StoreId == profile.StoreId);
            }
            else if (role == "area_manager")
            {
                // AM sees all plans for stores assigned via junction.
                // If the AM has no store assignments (e.g. a new hire or global oversight role),
                // they fall through to unfiltered visibility — same read-level as admin.
                // Their allowedActions are still restricted by capabilities (no write by default).
                var assignedStoreIds = await db.ProfileStoreAssignments
                    .Where(a => a.ProfileId == userId)
                    .Select(a => a.StoreId)
                    .ToListAsync(ct);

                if (assignedStoreIds.Count > 0)
                    query = query.Where(ap => ap.StoreId != null && assignedStoreIds.Contains(ap.StoreId.Value));
                // else: no filter — AM sees all plans
            }
            else if (role == "auditor")
            {
                // Auditors see plans linked to their own submissions.
                var auditorSubmissionIds = db.Submissions
                    .Where(s => s.AuditorId == userId)
                    .Select(s => s.Id);
                query = query.Where(ap => ap.SubmissionId != null && auditorSubmissionIds.Contains(ap.SubmissionId.Value));
            }
            else
            {
                // Unscoped profiles and unknown roles: return empty list by design.
                query = query.Where(ap => false);
            }
        }

        // Pagination (defaults: page 1, 50 items, max 100)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 100) : 50;

        var total = await query.CountAsync(ct);

        // Overflow guard: if the requested skip exceeds total rows, return empty page without hitting DB
        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<ActionPlanDto>([], total, page, pageSize));

        // Materialize first, then map in-memory to avoid translating capability logic into SQL (N+1 guard).
        var rawPlans = await query
            .OrderByDescending(ap => ap.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var plans = rawPlans.ConvertAll(ap => CreateActionPlan.ToDto(ap, callerCapabilities));

        return TypedResults.Ok(new PagedResult<ActionPlanDto>(plans, total, page, pageSize));
    }
}
