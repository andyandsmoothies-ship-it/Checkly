using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// POST /api/action-plans/{id}/comments — add a comment to an action plan.
/// 
/// Access rule: ResourceAccessGuard (admins, assigned store managers, linked auditors, and assigned area managers are allowed).
///
/// Notification: if the plan is linked to a submission, inserts a Notification of type
/// "action_plan_comment_added" targeting the submission's AuditorId.
/// If no submission is linked, the comment is stored successfully but no notification is sent.
/// </summary>
public static class AddComment
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AddCommentRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        IFcmDispatchService fcm,
        CancellationToken ct)
    {
        var plan = await db.ActionPlans.FindAsync([id], ct);
        if (plan is null)
            return TypedResults.NotFound();

        // Resolve AuditorId from linked submission (for auditor-role scoping).
        Guid? linkedAuditorId = null;
        if (plan.SubmissionId.HasValue)
        {
            linkedAuditorId = await db.Submissions
                .AsNoTracking()
                .Where(s => s.Id == plan.SubmissionId.Value)
                .Select(s => s.AuditorId)
                .FirstOrDefaultAsync(ct);
        }

        if (!await ResourceAccessGuard.CanAccessAsync(
                user, new ResourceScope(StoreId: plan.StoreId, OwnerId: linkedAuditorId), db, ct))
        {
            return TypedResults.Forbid();
        }

        if (!Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var callerId))
            return TypedResults.Forbid();

        // Build comment DTO — no DB table needed; comment is the payload, not persisted separately.
        var comment = new CommentDto(
            Id: Guid.NewGuid(),
            UserId: callerId,
            Body: request.Body,
            CreatedAt: DateTimeOffset.UtcNow);

        // Notify auditor if plan is linked to a submission.
        if (plan.SubmissionId.HasValue)
        {
            var auditorId = await db.Submissions
                .AsNoTracking()
                .Where(s => s.Id == plan.SubmissionId.Value)
                .Select(s => s.AuditorId)
                .FirstOrDefaultAsync(ct);

            if (auditorId.HasValue && auditorId != Guid.Empty)
            {
                db.Notifications.Add(new Notification
                {
                    Id = Guid.NewGuid(),
                    UserId = auditorId.Value,
                    Type = "action_plan_comment_added",
                    Title = "New comment on action plan",
                    Message = $"A comment was added: \"{request.Body}\"",
                    ActionUrl = $"/action-plans/{id}",
                    CreatedAt = DateTimeOffset.UtcNow
                });
                await db.SaveChangesAsync(ct);
                await fcm.DispatchSyncNeededAsync(auditorId.Value);
            }
        }

        return TypedResults.Created($"/api/action-plans/{id}/comments/{comment.Id}", comment);
    }
}
