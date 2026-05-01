using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// GET /api/programs/assignments/my
/// Returns the calling Store Manager's active program assignments for their store.
/// Store scoping: reads Profile.StoreId from DB — never trusts a claim.
/// Overdue computation: if status=pending AND deadline &lt; now → DTO shows "overdue".
/// </summary>
public static class GetMyAssignments
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Resolve the SM's store from their Profile — never trust request data for scoping
        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == userId, ct);

        if (profile?.StoreId is null)
            return TypedResults.Ok(new AssignmentsListResponse([]));

        var storeId = profile.StoreId.Value;

        var assignments = await db.ProgramAssignments
            .AsNoTracking()
            .Where(a => a.StoreId == storeId)
            .OrderBy(a => a.Program!.Deadline)
            .Select(a => new AssignmentSummaryDto(
                a.Id,
                a.ProgramId,
                a.Program!.Title,
                a.Program.Category,
                a.Program.Deadline,
                // Compute overdue in projection — not stored in DB
                a.Status == "pending" && a.Program.Deadline < DateTimeOffset.UtcNow
                    ? "overdue"
                    : a.Status,
                a.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new AssignmentsListResponse(assignments));
    }

    /// <summary>
    /// Envelope for GET /api/programs/assignments/my.
    /// Uses 'items' to match TC1/TC2 ATDD test contract expectations.
    /// </summary>
    public record AssignmentsListResponse(List<AssignmentSummaryDto> Items);
}
