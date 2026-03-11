using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
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
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var submission = await db.Submissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == request.SubmissionId, ct);

        if (submission is null)
            return TypedResults.BadRequest(new { error = "Submission not found" });

        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == userId, ct);

        var store = submission.StoreId.HasValue
            ? await db.Stores.AsNoTracking().FirstOrDefaultAsync(s => s.Id == submission.StoreId, ct)
            : null;

        var now = DateTimeOffset.UtcNow;
        var plan = new ActionPlan
        {
            Id = Guid.NewGuid(),
            SubmissionId = request.SubmissionId,
            AnswerId = request.AnswerId,
            StoreId = submission.StoreId,
            StoreManagerId = userId,
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

        return TypedResults.Created($"/api/action-plans/{plan.Id}", ToDto(plan));
    }

    internal static ActionPlanDto ToDto(ActionPlan p) => new(
        p.Id, p.SubmissionId, p.StoreId, p.StoreName,
        p.StoreManagerId, p.StoreManagerName,
        p.CriteriaLabel, p.GroupTitle, p.PlanDescription,
        p.RootCause, p.CorrectionPlan,
        p.EvidencePhotoUrl, p.EvidenceNote,
        p.Status, p.Deadline, p.ClosedAt,
        p.VerifierName, p.CreatedAt, p.UpdatedAt);
}
