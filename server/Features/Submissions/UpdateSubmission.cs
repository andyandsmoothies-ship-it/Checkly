using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// PUT /api/submissions/{id} — update submission status.
/// Primary use case: scheduled → draft (auditor starts a scheduled audit).
/// </summary>
public static class UpdateSubmission
{
    public sealed record Request(
        string? Status,
        string? AuditorName,
        string? AuditorEmail);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var submission = await db.Submissions
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (submission is null)
            return TypedResults.NotFound(new { error = "Submission not found" });

        var now = DateTimeOffset.UtcNow;

        // Handle status transitions
        if (request.Status is not null)
        {
            var from = submission.Status;
            var to = request.Status.ToLowerInvariant();

            switch (from, to)
            {
                case ("scheduled", "draft"):
                    // A4: Block overdue audits
                    if (submission.ScheduledAt.HasValue)
                    {
                        var scheduledDate = submission.ScheduledAt.Value.Date;
                        if (scheduledDate < DateTimeOffset.UtcNow.Date)
                        {
                            return TypedResults.BadRequest(new
                            {
                                error = "Cannot start an overdue audit. Please contact your manager to reschedule."
                            });
                        }
                    }

                    submission.Status = "draft";
                    submission.StartedAt = now;

                    // Claim auditor if not already assigned
                    if (!submission.AuditorId.HasValue)
                    {
                        submission.AuditorId = callerId;
                    }

                    // Update auditor info if provided
                    if (request.AuditorName is not null)
                        submission.AuditorName = request.AuditorName;
                    if (request.AuditorEmail is not null)
                        submission.AuditorEmail = request.AuditorEmail;

                    break;

                default:
                    return TypedResults.Conflict(new
                    {
                        error = $"Invalid status transition: '{from}' → '{to}'",
                        currentStatus = from,
                        requestedStatus = to
                    });
            }
        }

        submission.UpdatedAt = now;
        await db.SaveChangesAsync(ct);
        AuditLogger.Log(db, user, "submission_draft_saved", "Submission", submission.Id,
            message: $"Submission status transitioned to '{submission.Status}'",
            userEmail: user.FindFirstValue(ClaimTypes.Email));
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new SubmissionDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle, submission.DisplayNoun,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt));
    }
}
