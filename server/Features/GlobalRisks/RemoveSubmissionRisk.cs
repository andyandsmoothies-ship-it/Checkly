using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// DELETE /api/submissions/{submissionId}/risks/{globalRiskId}
/// Removes a triggered risk from a submission (hard-delete of the SubmissionRisk row).
/// Rules:
///   - IDOR guard: caller must own the submission.
///   - Only draft submissions can have risks removed (409 for completed/voided).
///   - Returns 204 NoContent on success.
///   - Returns 404 if the SubmissionRisk row does not exist.
/// </summary>
public static class RemoveSubmissionRisk
{
    public static async Task<IResult> HandleAsync(
        Guid submissionId,
        Guid globalRiskId,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // 1. Load submission
        var submission = await db.Submissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId, ct);

        if (submission is null)
            return TypedResults.NotFound(new { message = "Submission not found." });

        // 2. IDOR guard
        if (!await ResourceAccessGuard.CanAccessAsync(
                user, new ResourceScope(StoreId: submission.StoreId, OwnerId: submission.AuditorId), db, ct))
            return TypedResults.Forbid();

        // 3. Draft-only guard
        if (submission.Status != "draft")
            return TypedResults.Conflict(new { message = "Risks can only be removed from draft submissions." });

        // 4. Find the SubmissionRisk row
        var submissionRisk = await db.SubmissionRisks
            .FirstOrDefaultAsync(r => r.SubmissionId == submissionId && r.GlobalRiskId == globalRiskId, ct);

        if (submissionRisk is null)
            return TypedResults.NotFound(new { message = "Risk is not triggered on this submission." });

        // 5. Hard-delete the SubmissionRisk row
        db.SubmissionRisks.Remove(submissionRisk);

        AuditLogger.Log(db, user, "remove_submission_risk", "SubmissionRisk", submissionRisk.Id,
            message: $"Risk {globalRiskId} removed from submission {submissionId}",
            path: $"/api/submissions/{submissionId}/risks/{globalRiskId}");

        await db.SaveChangesAsync(ct);

        return TypedResults.NoContent();
    }
}
