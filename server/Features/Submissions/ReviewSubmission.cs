using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// PUT /api/submissions/{id}/review — admin approve/reject/flag an audit.
/// Sets ReviewStatus and generates a notification to the auditor.
/// </summary>
public static class ReviewSubmission
{
    public record Request(string Status); // "approved", "rejected", "flagged"

    private static readonly HashSet<string> ValidStatuses = ["approved", "rejected", "flagged"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Validate status
        if (!ValidStatuses.Contains(request.Status))
        {
            return TypedResults.BadRequest(new { error = $"Invalid review status. Must be one of: {string.Join(", ", ValidStatuses)}" });
        }

        // Find submission
        var submission = await db.Submissions
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (submission is null)
        {
            return TypedResults.NotFound(new { error = "Submission not found" });
        }

        // Set review fields
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var callerName = user.FindFirstValue(ClaimTypes.Name) ?? user.FindFirstValue(ClaimTypes.Email) ?? "Admin";

        submission.ReviewStatus = request.Status;
        submission.ApprovedBy = callerId;
        submission.ApprovedAt = DateTimeOffset.UtcNow;
        submission.ApproverName = callerName;
        submission.UpdatedAt = DateTimeOffset.UtcNow;

        // Notify the auditor
        if (submission.AuditorId.HasValue)
        {
            var notifType = request.Status == "approved"
                ? "audit_approved"
                : request.Status == "rejected"
                    ? "audit_rejected"
                    : "audit_flagged";

            var notifTitle = request.Status == "approved"
                ? "Audit approved"
                : request.Status == "rejected"
                    ? "Audit rejected"
                    : "Audit flagged for review";

            db.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = submission.AuditorId.Value,
                Type = notifType,
                Title = notifTitle,
                Message = $"Your audit for {submission.StoreName ?? "unknown store"} ({submission.TemplateTitle ?? "audit"}) has been {request.Status}",
                CreatedAt = DateTimeOffset.UtcNow,
            });
        }

        await db.SaveChangesAsync(ct);
        AuditLogger.Log(db, user, "submission_reviewed", "Submission", submission.Id,
            message: $"Submission '{submission.Id}' reviewed as '{request.Status}' by admin",
            userEmail: user.FindFirstValue(ClaimTypes.Email));
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new
        {
            id = submission.Id,
            reviewStatus = submission.ReviewStatus,
            approvedBy = submission.ApprovedBy,
            approvedAt = submission.ApprovedAt,
        });
    }
}
