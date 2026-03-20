using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// Shared service for auto-creating action plans from triggered answers.
/// Called by both CreateSubmission (completed flow) and FinalizeSubmission (draft → completed).
/// </summary>
public static class ActionPlanService
{
    /// <summary>
    /// Evaluates triggered answers and creates action plan records.
    /// Idempotent: skips if action plans already exist for this submission.
    /// Calls SaveChangesAsync internally if new APs are created.
    /// </summary>
    public static async Task AutoCreateAsync(
        Guid submissionId,
        Guid? storeId,
        List<Answer> answers,
        List<Criterion> criteria,
        List<Group> groups,
        DateTimeOffset now,
        AppDbContext db,
        CancellationToken ct)
    {
        var failedAnswers = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);
        if (failedAnswers.Count == 0)
            return;

        // Idempotency: skip if action plans already exist for this submission
        var existingAPs = await db.ActionPlans
            .AnyAsync(ap => ap.SubmissionId == submissionId, ct);

        if (existingAPs)
            return;

        var store = storeId.HasValue
            ? await db.Stores.AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == storeId.Value, ct)
            : null;

        var smProfile = storeId.HasValue
            ? await db.Profiles.AsNoTracking()
                .FirstOrDefaultAsync(p => p.StoreId == storeId.Value, ct)
            : null;

        var deadline = now.AddDays(7);

        foreach (var fail in failedAnswers)
        {
            var criterion = criteria.FirstOrDefault(c => c.Id == fail.CriteriaId);
            var group = criterion != null
                ? groups.FirstOrDefault(g => g.Id == criterion.GroupId)
                : null;

            db.ActionPlans.Add(new ActionPlan
            {
                Id = Guid.NewGuid(),
                SubmissionId = submissionId,
                AnswerId = fail.Id,
                StoreId = storeId,
                StoreManagerId = smProfile?.Id,
                CriteriaLabel = criterion?.Label ?? "",
                GroupTitle = group?.Title ?? "",
                Status = "open",
                Deadline = deadline,
                StoreName = store?.Name,
                StoreManagerName = smProfile?.FullName,
                CreatedAt = now,
                UpdatedAt = now
            });
        }

        await db.SaveChangesAsync(ct);
    }
}
