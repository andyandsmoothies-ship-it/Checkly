using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// POST /api/programs/assignments/{id}/verify
/// Transitions a submitted or needs_revision assignment to 'verified'.
/// Sets the VerifiedAt timestamp (GapAC2).
///
/// Status machine: submitted → verified, needs_revision → verified.
/// Security: requires programs:review capability (HQ/admin only).
///
/// Business rules:
///   - Assignment must be 'submitted' or 'needs_revision' (TC6: already verified → 400).
///   - Returns 200 { newStatus: "verified" } on success.
/// </summary>
public static class VerifyProgramAssignment
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var assignment = await db.ProgramAssignments
            .FirstOrDefaultAsync(a => a.Id == id, ct);

        if (assignment is null)
            return TypedResults.NotFound(new { error = "Assignment not found." });

        // TC6: Cannot verify an already-verified assignment
        // Only 'submitted' or 'needs_revision' are valid transition sources.
        if (assignment.Status == "verified")
            return TypedResults.BadRequest(new { error = "Assignment is already verified." });

        if (assignment.Status != "submitted" && assignment.Status != "needs_revision")
            return TypedResults.BadRequest(new { error = $"Cannot verify an assignment with status '{assignment.Status}'." });

        assignment.Status = "verified";
        assignment.VerifiedAt = DateTimeOffset.UtcNow;  // GapAC2
        assignment.UpdatedAt = DateTimeOffset.UtcNow;

        AuditLogger.Log(db, user, "program_verified", "ProgramAssignment", assignment.Id,
            $"Assignment {assignment.Id} verified.",
            $"/api/programs/assignments/{assignment.Id}/verify");

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { newStatus = "verified" });
    }
}
