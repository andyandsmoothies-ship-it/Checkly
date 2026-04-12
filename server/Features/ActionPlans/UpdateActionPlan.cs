using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// PUT /api/action-plans/{id} — update action plan status, evidence, details.
/// S2: Generates notifications on status transitions.
/// </summary>
public static class UpdateActionPlan
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        UpdateActionPlanRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        [Microsoft.AspNetCore.Mvc.FromServices] PbacDictionaryCache cache,
        CancellationToken ct)
    {
        var plan = await db.ActionPlans.FindAsync(id);
        if (plan is null)
            return TypedResults.NotFound();

        // Capture old status BEFORE applying updates (for PBAC gate + S2 notification logic)
        var oldStatus = plan.Status;

        // PBAC: Gate status transitions imperatively (one endpoint, two distinct capability gates).
        // Field-only updates (description, evidence URL, etc.) bypass this check by design.
        if (request.Status is not null)
        {
            var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

            bool isWriteTransition  = request.Status == "pending_verify";
            bool isVerifyTransition =
                (request.Status == "closed" && oldStatus == "pending_verify") ||
                (request.Status == "open"   && oldStatus == "pending_verify");

            if (isWriteTransition  && !cache.GetCapabilities(role).Contains(AppCapabilities.ActionPlansWrite))
                return TypedResults.Forbid();
            if (isVerifyTransition && !cache.GetCapabilities(role).Contains(AppCapabilities.ActionPlansVerify))
                return TypedResults.Forbid();
        }

        if (request.PlanDescription is not null) plan.PlanDescription = request.PlanDescription;
        if (request.RootCause is not null) plan.RootCause = request.RootCause;
        if (request.CorrectionPlan is not null) plan.CorrectionPlan = request.CorrectionPlan;
        if (request.EvidencePhotoUrl is not null) plan.EvidencePhotoUrl = request.EvidencePhotoUrl;
        if (request.EvidenceNote is not null) plan.EvidenceNote = request.EvidenceNote;
        if (request.Status is not null) plan.Status = request.Status;
        if (request.Deadline.HasValue) plan.Deadline = request.Deadline;

        if (request.Status == "closed")
            plan.ClosedAt = DateTimeOffset.UtcNow;

        plan.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        // --- S2: Generate notifications on status change ---
        if (request.Status is not null && request.Status != oldStatus)
        {
            Notification? notif = null;

            if (request.Status == "pending_verify")
            {
                // S2-1: Evidence submitted → notify auditor (or calling user as fallback)
                Guid? targetUserId = null;

                if (plan.SubmissionId.HasValue)
                {
                    var submission = await db.Submissions.AsNoTracking()
                        .FirstOrDefaultAsync(s => s.Id == plan.SubmissionId, ct);
                    targetUserId = submission?.AuditorId;
                }

                // Fallback: use the calling user's identity
                targetUserId ??= Guid.TryParse(
                    user.FindFirstValue(ClaimTypes.NameIdentifier), out var callerId)
                    ? callerId
                    : null;

                if (targetUserId.HasValue)
                {
                    notif = new Notification
                    {
                        Id = Guid.NewGuid(),
                        UserId = targetUserId.Value,
                        Type = "action_plan_evidence_submitted",
                        Title = "Evidence submitted",
                        Message = $"Evidence submitted for {plan.CriteriaLabel} at {plan.StoreName}",
                        CreatedAt = DateTimeOffset.UtcNow
                    };
                }
            }
            else if (request.Status == "closed" && oldStatus == "pending_verify")
            {
                // S2-2: Plan closed → notify SM
                if (plan.StoreManagerId.HasValue)
                {
                    notif = new Notification
                    {
                        Id = Guid.NewGuid(),
                        UserId = plan.StoreManagerId.Value,
                        Type = "action_plan_closed",
                        Title = "Action plan verified",
                        Message = $"Action plan for {plan.CriteriaLabel} verified and closed",
                        CreatedAt = DateTimeOffset.UtcNow
                    };
                }
            }
            else if (request.Status == "open" && oldStatus == "pending_verify")
            {
                // S2-3: Evidence rejected → notify SM
                if (plan.StoreManagerId.HasValue)
                {
                    notif = new Notification
                    {
                        Id = Guid.NewGuid(),
                        UserId = plan.StoreManagerId.Value,
                        Type = "action_plan_rejected",
                        Title = "Evidence rejected",
                        Message = $"Evidence for {plan.CriteriaLabel} rejected, please resubmit",
                        CreatedAt = DateTimeOffset.UtcNow
                    };
                }
            }

            if (notif is not null)
            {
                db.Notifications.Add(notif);
                await db.SaveChangesAsync(ct);
            }
        }

        return TypedResults.Ok(CreateActionPlan.ToDto(plan));
    }
}
