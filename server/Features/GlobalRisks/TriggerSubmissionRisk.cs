using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// POST /api/submissions/{submissionId}/risks
/// Triggers a GlobalRisk on a submission.
/// Rules:
///   - IDOR guard: caller must own the submission (or be admin).
///   - Only draft submissions can have risks added (409 for completed/voided).
///   - GlobalRisk must exist and be active (404 otherwise).
///   - Duplicate trigger (same submission + risk) returns 409.
/// </summary>
public static class TriggerSubmissionRisk
{
    public static async Task<IResult> HandleAsync(
        Guid submissionId,
        TriggerSubmissionRiskRequest request,
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
        if (!await SubmissionAccessGuard.CanAccessAsync(
                user, submission.StoreId, areaId: null, submission.AuditorId, db, ct))
            return TypedResults.Forbid();

        // 3. Draft-only guard
        if (submission.Status != "draft")
            return TypedResults.Conflict(new { message = "Risks can only be triggered on draft submissions." });

        // 4. Validate GlobalRisk exists and is active
        var globalRisk = await db.GlobalRisks
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == request.GlobalRiskId, ct);

        if (globalRisk is null || !globalRisk.IsActive)
            return TypedResults.NotFound(new { message = "Global risk not found or inactive." });

        // 5. Insert SubmissionRisk (catch 23505 duplicate constraint violation)
        var callerId = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var cid) ? cid : (Guid?)null;
        var now = DateTimeOffset.UtcNow;

        var submissionRisk = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submissionId,
            GlobalRiskId = request.GlobalRiskId,
            TriggeredById = callerId,
            TriggeredAt = now,
            CreatedAt = now
        };
        db.SubmissionRisks.Add(submissionRisk);

        AuditLogger.Log(db, user, "trigger_submission_risk", "SubmissionRisk", submissionRisk.Id,
            message: $"Risk '{globalRisk.Label}' triggered on submission {submissionId}",
            path: $"/api/submissions/{submissionId}/risks");

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (ex.InnerException?.Message.Contains("23505") == true)
        {
            return TypedResults.Conflict(new { message = "This risk is already triggered on this submission." });
        }

        return TypedResults.Created(
            $"/api/submissions/{submissionId}/risks/{submissionRisk.Id}",
            new SubmissionRiskDto(
                submissionRisk.Id,
                submissionRisk.SubmissionId,
                submissionRisk.GlobalRiskId,
                globalRisk.Label,
                submissionRisk.TriggeredById,
                submissionRisk.TriggeredAt,
                submissionRisk.CreatedAt));
    }
}
