using System.Security.Claims;
using System.Text.Json;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// POST /api/submissions — creates submission + answers in one transaction.
/// Supports two modes:
///   - status=draft  → creates a draft submission (no score, no answers)
///   - status=completed (or omitted) → full submission with scoring verification
/// </summary>
public static class CreateSubmission
{
    private static readonly HashSet<string> ValidStatuses = new(StringComparer.OrdinalIgnoreCase)
        { "draft", "completed", "scheduled" };

    public static async Task<IResult> HandleAsync(
        CreateSubmissionRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        ScoringVerifier scorer,
        IConfiguration config,
        CancellationToken ct)
    {
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var auditorId = request.AssignToAuditorId ?? callerId;

        // Tactical 9/10 Fix: Prevent IDOR assignment if not an admin/manager
        if (request.AssignToAuditorId.HasValue && request.AssignToAuditorId.Value != callerId)
        {
            if (!SubmissionAccessGuard.CanDelegate(user))
            {
                return TypedResults.Forbid();
            }
        }

        // Determine mode
        var requestedStatus = request.Status?.ToLowerInvariant() ?? "completed";
        if (!ValidStatuses.Contains(requestedStatus))
        {
            Log.Warning("CreateSubmission 400: Invalid status {Status}", request.Status);
            return TypedResults.BadRequest(new { error = $"Invalid status: '{request.Status}'. Must be draft, scheduled, or completed." });
        }

        var isDraft = requestedStatus == "draft";
        var isScheduled = requestedStatus == "scheduled";

        // Idempotency check
        if (!string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            var existing = await db.Submissions
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.IdempotencyKey == request.IdempotencyKey, ct);

            if (existing is not null)
            {
                return TypedResults.Ok(new SubmissionDto(
                    existing.Id, existing.TemplateId, existing.TemplateTitle, existing.TemplateType, existing.DisplayNoun,
                    existing.StoreId, existing.StoreName, existing.AuditorId,
                    existing.AuditorName, existing.Status, existing.TotalScore,
                    existing.SectionScores, existing.Notes,
                    existing.CreatedAt, existing.CompletedAt, existing.ScheduledAt,
                    existing.TemplateVersion));
            }
        }

        // Validate: completed submissions MUST have score + answers
        if (!isDraft && !isScheduled)
        {
            if (request.ClientScore is null)
            {
                Log.Warning("CreateSubmission 400: ClientScore is missing");
                return TypedResults.BadRequest(new { error = "ClientScore is required for completed submissions" });
            }
            if (request.Answers is null || request.Answers.Count == 0)
            {
                Log.Warning("CreateSubmission 400: Answers are empty");
                return TypedResults.BadRequest(new { error = "Answers are required for completed submissions" });
            }
        }

        var template = await db.Templates
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == request.TemplateId, ct);

        if (template is null)
        {
            Log.Warning("CreateSubmission 400: Template not found {Id}", request.TemplateId);
            return TypedResults.BadRequest(new { error = "Template not found" });
        }

        if (!template.IsActive)
        {
            Log.Warning("CreateSubmission 400: Template archived");
            return TypedResults.BadRequest(new { error = "Template is archived" });
        }

        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == request.StoreId, ct);

        if (store is null)
        {
            Log.Warning("CreateSubmission 400: Store not found {Id}", request.StoreId);
            return TypedResults.BadRequest(new { error = "Store not found" });
        }

        if (store.IsActive == false)
        {
            Log.Warning("CreateSubmission 400: Store deactivated");
            return TypedResults.BadRequest(new { error = "Store is deactivated" });
        }

        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == request.TemplateId && g.IsActive)
            .ToListAsync(ct);

        var groupIds = groups.Select(g => g.Id).ToList();
        var criteria = await db.Criteria
            .AsNoTracking()
            .Where(c => groupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        var templateSnapshotJson = TemplateSnapshotBuilder.BuildSnapshot(template, groups, criteria);

        decimal? serverScore = null;

        if (!isDraft && !isScheduled)
        {
            var (scoringMode, progressiveRepeatPenalty) = ScoringConfigParser.Parse(template.ScoringLogicConfig);

            var tempAnswers = request.Answers!.Select(a => new Answer
            {
                CriteriaId = a.CriteriaId,
                NumericValue = a.NumericValue,
                Value = a.Value,
                RepeatedFaults = a.RepeatedFaults
            }).ToList();

            // Apply answer-level CCP/Risk overrides to the in-memory criteria list.
            // Mirrors FinalizeSubmission.cs — auditor manual flags override template defaults.
            var answerOverrideMap = request.Answers!
                .Where(a => a.IsCcp || a.IsRisk)
                .ToDictionary(a => a.CriteriaId);

            // Build explicit override set — passed to Verify() to trigger RISK unconditionally
            // regardless of answer value (mirrors Flutter's isAnswerRisk unconditional path).
            var explicitRiskIds = request.Answers!
                .Where(a => a.IsRisk)
                .Select(a => a.CriteriaId)
                .ToHashSet();

            foreach (var crit in criteria)
            {
                if (answerOverrideMap.TryGetValue(crit.Id, out var ans))
                {
                    if (ans.IsCcp) crit.IsCcp = true;
                    if (ans.IsRisk) crit.IsRisk = true;
                }
            }

            // Global Risk: for one-shot submissions, the client sends hasGlobalRisk in the payload.
            // Since there are no persisted SubmissionRisks yet (submission doesn't exist),
            // we rely entirely on the flag the client sends. This mirrors FinalizeSubmission which
            // loads from DB — but here we have no submission row yet.
            bool hasGlobalRisk = request.HasGlobalRisk;

            var verification = scorer.Verify(request.ClientScore!.Value, tempAnswers, groups, criteria,
                scoringMode: scoringMode, explicitRiskAnswerIds: explicitRiskIds, progressiveRepeatPenalty: progressiveRepeatPenalty, hasGlobalRisk: hasGlobalRisk);

            var scoreMode = config["ScoreVerification:Mode"] ?? "enforce";
            if (!verification.IsValid)
            {
                if (scoreMode == "enforce")
                {
                    Log.Warning("CreateSubmission 400: Score mismatch. Client: {Client}, Server: {Server}. Reason: {Reason}",
                        request.ClientScore, verification.ServerScore, verification.Reason);
                    return TypedResults.BadRequest(new
                    {
                        error = "Score verification failed",
                        clientScore = request.ClientScore,
                        serverScore = verification.ServerScore,
                        reason = verification.Reason
                    });
                }
            }

            serverScore = scoringMode == "survey" ? null : verification.ServerScore;
        }

        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == auditorId, ct);

        var (submissionScoringMode, _) = ScoringConfigParser.Parse(template.ScoringLogicConfig);

        var now = DateTimeOffset.UtcNow;
        var submission = new Submission
        {
            Id = request.Id ?? Guid.NewGuid(),
            TemplateId = request.TemplateId,
            StoreId = request.StoreId,
            AuditorId = auditorId,
            Status = requestedStatus,
            ScoringMode = submissionScoringMode,
            TotalScore = serverScore,
            SectionScores = request.SectionScores,
            Notes = request.Notes,
            GpsLat = request.GpsLat,
            GpsLng = request.GpsLng,
            GpsVerifiedAt = request.GpsLat.HasValue ? now : null,
            CompletedAt = (isDraft || isScheduled) ? null : now,
            StartedAt = isDraft ? now : (isScheduled ? null : now),
            ScheduledAt = request.ScheduledAt?.ToUniversalTime(),
            CreatedAt = now,
            UpdatedAt = now,
            AuditorName = profile?.FullName,
            AuditorEmail = profile?.Email,
            StoreName = store.Name,
            TemplateTitle = template.Title,
            TemplateType = template.Type,
            DisplayNoun = template.DisplayNoun,
            IdempotencyKey = request.IdempotencyKey,
            TemplateSnapshot = templateSnapshotJson,
            TemplateVersion = template.Version
        };

        var strategy = db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            db.Submissions.Add(submission);

            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // Create answers — only for completed submissions
            if (!isDraft && !isScheduled && request.Answers is not null)
            {
                var answers = request.Answers.Select(a => new Answer
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = submission.Id,
                    CriteriaId = a.CriteriaId,
                    Value = a.Value,
                    NumericValue = a.NumericValue,
                    Note = a.Note,
                    PhotoUrl = a.PhotoUrl,
                    IsRepeatedError = a.IsRepeatedError,
                    IsCcp = a.IsCcp,   // Persist auditor CCP escalation override
                    IsRisk = a.IsRisk, // Persist auditor RISK escalation override
                    CriteriaLabel = criteria.FirstOrDefault(c => c.Id == a.CriteriaId)?.Label,
                    CreatedAt = now,
                    UpdatedAt = now
                }).ToList();

                db.Answers.AddRange(answers);

                // --- S1: Auto-create action plans for triggered answers (stages only, no flush) ---
                await ActionPlanService.AutoCreateAsync(
                    submission.Id, submission.StoreId,
                    answers, criteria, groups, now, db, ct,
                    scoringMode: submissionScoringMode,
                    scoringLogicConfig: template.ScoringLogicConfig);
            }

            AuditLogger.Log(db, user, "submission_started", "Submission", submission.Id,
                message: $"Submission created with status '{submission.Status}' for store '{submission.StoreName}'",
                userEmail: user.FindFirstValue(ClaimTypes.Email));

            // Atomic flush 1: submission + answers + action plans + audit log
            await db.SaveChangesAsync(ct);

            if (!isDraft && !isScheduled)
            {
                // --- S2: Explode SectionScores JSON into relational rows (skip for survey mode) ---
                if (submissionScoringMode != "survey")
                {
                    await SectionScoreExploder.ExplodeAsync(submission.Id, submission.StoreId, submission.TemplateId, request.SectionScores, db, now, ct);
                }

                // --- S3: Upsert StoreAnalyticsSnapshot ---
                await StoreAnalyticsUpdater.UpdateMetricsAsync(submission.StoreId, submission, db, now, ct);
            }

            await transaction.CommitAsync(ct);

            return TypedResults.Created($"/api/submissions/{submission.Id}", new SubmissionDto(
                submission.Id, submission.TemplateId, submission.TemplateTitle, submission.TemplateType, submission.DisplayNoun,
                submission.StoreId, submission.StoreName, submission.AuditorId,
                submission.AuditorName, submission.Status, submission.TotalScore,
                submission.SectionScores, submission.Notes,
                submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt,
                submission.TemplateVersion));
        });
    }
}
