using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Checkly.Api.Features.ActionPlans;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// POST /api/submissions/{id}/void — admin-only compensating transaction to neutralize an audit.
/// Atomically: flips status to 'voided', cascades ActionPlan closures, writes audit log.
///
/// NOTE: This handler wraps BeginTransactionAsync inside CreateExecutionStrategy().ExecuteAsync
/// because Npgsql's NpgsqlRetryingExecutionStrategy does not allow user-initiated transactions
/// without the explicit execution strategy wrapper.
/// </summary>
public static class VoidSubmission
{
    public record Command(string VoidReason);

    private static readonly HashSet<string> VoidableStatuses = ["draft", "scheduled", "completed", "approved", "rejected", "pending_approval"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        Command command,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // ── 1. Auth Guard: admin-only ────────────────────────────────────────
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != AppRoles.Admin)
            return TypedResults.Forbid();

        // ── 2. Validate command ──────────────────────────────────────────────
        if (string.IsNullOrWhiteSpace(command.VoidReason))
            return TypedResults.BadRequest(new { error = "A void reason is required." });

        // ── 3. Fetch submission ──────────────────────────────────────────────
        var submission = await db.Submissions
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (submission is null)
            return TypedResults.NotFound(new { error = "Submission not found." });

        // ── 4. State Guards ──────────────────────────────────────────────────
        // Rule 1: Idempotent queue draining — already voided → return success silently.
        if (submission.Status == SubmissionStatus.Voided)
            return TypedResults.NoContent();

        // Rule: Only non-draft/non-scheduled audits may be voided.
        if (!VoidableStatuses.Contains(submission.Status))
            return TypedResults.BadRequest(new
            {
                error = $"Cannot void a submission with status '{submission.Status}'. Only draft, scheduled, completed, approved, or rejected submissions may be voided."
            });

        // ── 5. Compensating Transaction ──────────────────────────────────────
        // IMPORTANT: NpgsqlRetryingExecutionStrategy requires wrapping user-initiated
        // transactions inside CreateExecutionStrategy().ExecuteAsync(). Not doing so
        // throws InvalidOperationException at runtime.
        var strategy = db.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // Mutate submission entity
            submission.Status = SubmissionStatus.Voided;
            submission.VoidReason = command.VoidReason;
            submission.VoidedAt = DateTimeOffset.UtcNow;
            submission.UpdatedAt = DateTimeOffset.UtcNow;

            // Write the audit log (participates in same transaction via Change Tracker)
            AuditLogger.Log(
                db, user,
                action: "submission_voided",
                entityType: "Submission",
                entityId: submission.Id,
                message: command.VoidReason,
                userEmail: user.FindFirstValue(ClaimTypes.Email));

            // Commit submission + audit log together (single SaveChanges inside transaction)
            await db.SaveChangesAsync(ct);

            // Rule 3: Cascade Action Plans via ExecuteUpdateAsync (bulk, no entity loading)
            await db.ActionPlans
                .Where(ap => ap.SubmissionId == id && ap.Status != ActionPlanStatus.Closed)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(ap => ap.Status, ActionPlanStatus.Closed)
                    .SetProperty(ap => ap.RootCause, "SYSTEM_VOID")
                    .SetProperty(ap => ap.UpdatedAt, DateTimeOffset.UtcNow),
                    ct);

            // Rule 4: Touch store analytics snapshot timestamp if one exists
            if (submission.StoreId.HasValue)
            {
                await db.StoreAnalyticsSnapshots
                    .Where(snap => snap.StoreId == submission.StoreId.Value)
                    .ExecuteUpdateAsync(s => s
                        .SetProperty(snap => snap.UpdatedAt, DateTimeOffset.UtcNow),
                        ct);
            }

            await transaction.CommitAsync(ct);
        });

        return TypedResults.NoContent();
    }
}
