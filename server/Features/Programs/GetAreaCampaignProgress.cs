using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// GET /api/programs/area-progress
/// Returns campaign completion progress for all stores assigned to the calling Area Manager.
/// Scoping: uses ProfileStoreAssignments — never trusts client-supplied store lists.
/// Capability gate: programs:assignments_list (enforced at route level via RequireCapability).
/// AllowedActions: computed server-side per PBAC02 hybrid entity-driven UI contract.
/// </summary>
public static class GetAreaCampaignProgress
{
    // Statuses that count as "completed" for the progress bar.
    private static readonly HashSet<string> CompletedStatuses =
        ["submitted", "verified", "needs_revision"];

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        PbacDictionaryCache pbacCache,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // --- Compute allowedActions flags BEFORE any query (EF cannot translate cache calls) ---
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
        var capabilities = pbacCache.GetCapabilities(role);
        var canViewDetails = capabilities.Contains(AppCapabilities.ProgramsAssignmentsList);
        var allowedActions = canViewDetails
            ? new List<string> { "view_details" }
            : new List<string>();

        // Step 1: Resolve stores assigned to this Area Manager.
        var assignedStoreIds = await db.ProfileStoreAssignments
            .AsNoTracking()
            .Where(psa => psa.ProfileId == userId)
            .Select(psa => psa.StoreId)
            .ToListAsync(ct);

        if (assignedStoreIds.Count == 0)
            return TypedResults.Ok(new List<AreaCampaignProgressDto>());

        // Step 2: Load raw assignment rows for those stores (lean projection — no grouping in EF).
        var rawAssignments = await db.ProgramAssignments
            .AsNoTracking()
            .Where(a => assignedStoreIds.Contains(a.StoreId))
            .Select(a => new
            {
                a.ProgramId,
                ProgramTitle = a.Program!.Title,
                ProgramCategory = a.Program.Category,
                ProgramDeadline = a.Program.Deadline,
                ProgramStatus = a.Program.Status,
                a.Status,
            })
            .ToListAsync(ct);

        if (rawAssignments.Count == 0)
            return TypedResults.Ok(new List<AreaCampaignProgressDto>());

        // Step 3: Group in-memory to avoid complex EF LINQ grouping translation.
        var grouped = rawAssignments
            .GroupBy(a => a.ProgramId)
            .Select(g =>
            {
                var first = g.First();
                var total = g.Count();
                var completed = g.Count(a => CompletedStatuses.Contains(a.Status));
                var rate = total == 0 ? 0 : (int)Math.Round((double)completed / total * 100);

                return new AreaCampaignProgressDto(
                    g.Key,
                    first.ProgramTitle,
                    first.ProgramCategory,
                    first.ProgramDeadline,
                    first.ProgramStatus,
                    total,
                    completed,
                    rate,
                    allowedActions);
            })
            .OrderByDescending(dto => dto.Deadline)
            .ToList();

        return TypedResults.Ok(grouped);
    }
}
