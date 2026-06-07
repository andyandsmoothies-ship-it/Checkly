using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// POST /api/action-plans — create action plan (store_manager or admin).
/// </summary>
public static class CreateActionPlan
{
    public static async Task<IResult> HandleAsync(
        CreateActionPlanRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        [Microsoft.AspNetCore.Mvc.FromServices] Checkly.Api.Common.Auth.PbacDictionaryCache cache,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var submission = await db.Submissions
            .Include(s => s.ProgramAssignment)
                .ThenInclude(pa => pa!.Program)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == request.SubmissionId, ct);

        if (submission is null)
            return TypedResults.BadRequest(new { error = "Submission not found" });

        if (!await ResourceAccessGuard.CanAccessAsync(
                user, new ResourceScope(StoreId: submission.StoreId, OwnerId: submission.AuditorId), db, ct))
        {
            return TypedResults.Forbid();
        }

        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == userId, ct);

        var store = submission.StoreId.HasValue
            ? await db.Stores.AsNoTracking().FirstOrDefaultAsync(s => s.Id == submission.StoreId, ct)
            : null;

        var sourceTitle = submission.ProgramAssignment?.Program?.Title != null
            ? $"Campaign: {submission.ProgramAssignment.Program.Title}"
            : $"Audit: {submission.TemplateTitle ?? "Unknown"}";

        var now = DateTimeOffset.UtcNow;
        var plan = new ActionPlan
        {
            Id = Guid.NewGuid(),
            SubmissionId = request.SubmissionId,
            AnswerId = request.AnswerId,
            StoreId = submission.StoreId,
            StoreManagerId = userId,
            SourceTitle = sourceTitle,
            CriteriaLabel = request.CriteriaLabel,
            GroupTitle = request.GroupTitle,
            PlanDescription = request.PlanDescription,
            RootCause = request.RootCause,
            CorrectionPlan = request.CorrectionPlan,
            Deadline = request.Deadline,
            Status = "open",
            CreatedAt = now,
            UpdatedAt = now,
            StoreName = store?.Name,
            StoreManagerName = profile?.FullName
        };

        db.ActionPlans.Add(plan);
        await db.SaveChangesAsync(ct);

        AuditLogger.Log(db, user, "action_plan_created", "ActionPlan", plan.Id, userEmail: user.FindFirstValue(ClaimTypes.Email));

        var callerCapabilities = cache.GetCapabilities(user.FindFirstValue(ClaimTypes.Role) ?? "");

        return TypedResults.Created($"/api/action-plans/{plan.Id}",
            ToDto(plan, callerCapabilities));
    }

    internal static ActionPlanDto ToDto(ActionPlan p, IReadOnlySet<string> callerCapabilities)
    {
        var actions = new List<string> { ActionPlanActions.View };

        if (p.Status == "open" && callerCapabilities.Contains(Common.Auth.AppCapabilities.ActionPlansWrite))
            actions.Add(ActionPlanActions.SubmitEvidence);

        if (p.Status == "pending_verify" && callerCapabilities.Contains(Common.Auth.AppCapabilities.ActionPlansVerify))
        {
            actions.Add(ActionPlanActions.VerifyClose);
            actions.Add(ActionPlanActions.RejectEvidence);
        }

        return new ActionPlanDto(
            p.Id, p.SubmissionId, p.StoreId, p.StoreName,
            p.StoreManagerId, p.StoreManagerName,
            p.SourceTitle,
            p.CriteriaLabel, p.GroupTitle, p.PlanDescription,
            p.RootCause, p.CorrectionPlan,
            p.EvidencePhotoUrl, p.EvidenceNote,
            p.Status, p.Deadline, p.ClosedAt,
            p.VerifierName, p.EvidenceSubmittedAt, p.EvidenceSubmittedByName,
            p.CreatedAt, p.UpdatedAt,
            p.AreaManagerId, p.AreaManagerName,
            actions);
    }
}
