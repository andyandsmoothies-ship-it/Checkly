using System.Security.Claims;
using Checkly.Api.Common;
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
        HttpContext httpContext,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Resolve the SM's store from their Profile — never trust request data for scoping
        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == userId, ct);

        // Pagination defaults
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        if (profile?.StoreId is null)
            return TypedResults.Ok(new PagedResult<AssignmentSummaryDto>([], 0, page, pageSize));

        var storeId = profile.StoreId.Value;

        var query = db.ProgramAssignments
            .AsNoTracking()
            .Where(a => a.StoreId == storeId);

        var total = await query.CountAsync(ct);

        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<AssignmentSummaryDto>([], total, page, pageSize));

        var assignments = await query
            .OrderBy(a => a.Program!.Deadline)
            .ThenBy(a => a.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
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

        return TypedResults.Ok(new PagedResult<AssignmentSummaryDto>(assignments, total, page, pageSize));
    }
}
