using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// PUT /api/action-plans/{id} — update action plan status, evidence, details.
/// </summary>
public static class UpdateActionPlan
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        UpdateActionPlanRequest request,
        AppDbContext db,
        CancellationToken ct)
    {
        var plan = await db.ActionPlans.FindAsync(id);
        if (plan is null)
            return TypedResults.NotFound();

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

        return TypedResults.Ok(CreateActionPlan.ToDto(plan));
    }
}
