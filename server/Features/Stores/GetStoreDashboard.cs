using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Features.ActionPlans;
using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// GET /api/stores/{id}/dashboard — store-level metrics.
/// Infra Slice 1: IDOR guard added.
///   admin       → full access
///   auditor     → 403 (auditors use the audit form, not the dashboard)
///   store_manager → only their assigned store (profile.StoreId == id)
///   area_manager  → only stores assigned via ProfileStoreAssignment
/// </summary>
public static class GetStoreDashboard
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);

        // Auditors are forbidden — they use the audit form, not the store dashboard
        if (role == AppRoles.Auditor)
            return TypedResults.Forbid();

        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id && s.IsActive == true, ct);

        if (store is null)
            return TypedResults.NotFound(new { error = "Store not found" });

        // Role-scoped IDOR guard for store_manager and area_manager
        if (role is AppRoles.StoreManager or AppRoles.AreaManager)
        {
            if (!Guid.TryParse(userId, out var userGuid))
                return TypedResults.Forbid();

            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == userGuid, ct);

            if (profile is null)
                return TypedResults.Forbid();

            if (role == AppRoles.StoreManager && profile.StoreId != id)
                return TypedResults.Forbid();

            if (role == AppRoles.AreaManager)
            {
                var isAssigned = await db.ProfileStoreAssignments
                    .AnyAsync(a => a.ProfileId == userGuid && a.StoreId == id, ct);
                if (!isAssigned) return TypedResults.Forbid();
            }
        }

        var submissions = await db.Submissions
            .AsNoTracking()
            .Where(s => s.StoreId == id && s.Status == SubmissionStatus.Completed && (s.ReviewStatus == null || s.ReviewStatus != ReviewStatus.Rejected))
            .OrderByDescending(s => s.CreatedAt)
            .Take(20)
            .Select(s => new
            {
                s.Id,
                s.TemplateTitle,
                s.TotalScore,
                s.AuditorName,
                s.CreatedAt,
            })
            .ToListAsync(ct);

        var scored = submissions.Where(s => s.TotalScore.HasValue).ToList();
        var avgScore = scored.Count > 0
            ? Math.Round(scored.Average(s => (double)s.TotalScore!.Value), 1)
            : 0.0;

        var openAPs = await db.ActionPlans
            .CountAsync(ap => ap.StoreId == id && ap.Status == ActionPlanStatus.Open, ct);

        // Fetch pre-computed snapshot (may not exist yet)
        var snapshot = await db.StoreAnalyticsSnapshots
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.StoreId == id, ct);

        return TypedResults.Ok(new
        {
            store = new { store.Id, store.Name, store.Address, store.IsActive },
            avgScore,
            totalAudits = submissions.Count,
            openActionPlans = openAPs,
            recentAudits = submissions,
            // Snapshot fields (S3.2)
            avgScore30d = snapshot?.AvgScore30d ?? 0m,
            lastAuditScore = snapshot?.LastAuditScore,
            overdueActionPlans = snapshot?.OverdueActionPlans ?? 0,
        });
    }
}
