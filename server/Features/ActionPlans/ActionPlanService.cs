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
    /// Evaluates triggered answers and stages action plan records in the change tracker.
    /// Idempotent: skips if action plans already exist for this submission.
    /// Does NOT call SaveChangesAsync — the caller is responsible for flushing.
    /// </summary>
    public static async Task AutoCreateAsync(
        Guid submissionId,
        Guid? storeId,
        List<Answer> answers,
        List<Criterion> criteria,
        List<Group> groups,
        DateTimeOffset now,
        AppDbContext db,
        CancellationToken ct,
        string? scoringMode = null,
        string? scoringLogicConfig = null)
    {
        // F2: Survey-mode submissions should never generate action plans
        if (string.Equals(scoringMode, "survey", StringComparison.OrdinalIgnoreCase))
            return;

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

        // F1: Parse configurable deadline from template config (default: 7 days, range: 1–90)
        var deadlineDays = 7;
        if (!string.IsNullOrEmpty(scoringLogicConfig))
        {
            try
            {
                var configDoc = System.Text.Json.JsonDocument.Parse(scoringLogicConfig);
                if (configDoc.RootElement.TryGetProperty("features", out var features)
                    && features.TryGetProperty("action_plan_deadline_days", out var daysElem)
                    && daysElem.TryGetInt32(out var parsedDays))
                {
                    deadlineDays = Math.Clamp(parsedDays, 1, 90);
                }
            }
            catch { /* malformed config → default to 7 days */ }
        }
        var deadline = now.AddDays(deadlineDays);

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
    }
}
