using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// POST /api/programs/assignments/{id}/reject
/// Transitions a submitted assignment to 'needs_revision' with a rejection reason.
///
/// Status machine: submitted → needs_revision.
/// Security: requires programs:review capability (HQ/admin only).
///
/// Business rules:
///   - Reason must not be blank (TC7 → 400).
///   - Assignment must be in 'submitted' status (TC3: pending → 400, TC2: needs_revision → 400).
///   - Returns 200 { newStatus: "needs_revision" } on success.
/// </summary>
public static class RejectProgramAssignment
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        RejectRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // TC7: Reason must not be blank
        if (string.IsNullOrWhiteSpace(request.Reason))
            return TypedResults.BadRequest(new { error = "reason must not be empty." });

        var assignment = await db.ProgramAssignments
            .FirstOrDefaultAsync(a => a.Id == id, ct);

        if (assignment is null)
            return TypedResults.NotFound(new { error = "Assignment not found." });

        // TC3: Cannot reject a pending assignment (not yet submitted)
        // TC2: Cannot reject a needs_revision assignment (already rejected)
        // Only 'submitted' is a valid transition source.
        if (assignment.Status != "submitted")
            return TypedResults.BadRequest(new { error = $"Cannot reject an assignment with status '{assignment.Status}'." });

        assignment.Status = "needs_revision";
        assignment.RejectionComment = request.Reason.Trim();
        assignment.UpdatedAt = DateTimeOffset.UtcNow;

        AuditLogger.Log(db, user, "program_rejected", "ProgramAssignment", assignment.Id,
            $"Assignment {assignment.Id} rejected. Reason: {request.Reason[..Math.Min(100, request.Reason.Length)]}",
            $"/api/programs/assignments/{assignment.Id}/reject");

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { newStatus = "needs_revision" });
    }
}
