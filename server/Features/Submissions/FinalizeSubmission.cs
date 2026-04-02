using System.Security.Claims;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// PUT /api/submissions/{id}/finalize — atomic draft → completed transition.
/// Accepts score + answers, verifies score, creates answers + action plans.
/// </summary>
public static class FinalizeSubmission
{
    public sealed record FinalizeRequest(
        decimal ClientScore,
        string? SectionScores,
        string? Notes,
        decimal? GpsLat,
        decimal? GpsLng,
        List<AnswerInput> Answers);

    public static async Task<IResult> HandleAsync(
        Guid id,
        FinalizeRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        ScoringVerifier scorer,
        IConfiguration config,
        CancellationToken ct)
    {
        var auditorId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // 1. Load submission
        var submission = await db.Submissions.FindAsync([id], ct);
        if (submission is null)
            return TypedResults.NotFound();

        // Must be draft to finalize
        if (submission.Status != "draft")
            return TypedResults.Conflict(new { error = $"Cannot finalize a submission with status '{submission.Status}'. Only draft submissions can be finalized." });

        // Must be the same auditor (or admin — future)
        if (submission.AuditorId != auditorId)
            return TypedResults.Forbid();

        // 2. Validate answers
        if (request.Answers.Count == 0)
            return TypedResults.BadRequest(new { error = "Answers are required to finalize" });

        // 3. Load template data — prefer snapshot, fallback to live DB
        List<Group> groups;
        List<Criterion> criteria;
        string? scoringLogicConfig;
        string? snapshotDisplayNoun;

        if (!string.IsNullOrEmpty(submission.TemplateSnapshot))
        {
            // Snapshot path — deserialize frozen template tree
            var snapshot = System.Text.Json.JsonSerializer.Deserialize<TemplateSnapshotModel>(submission.TemplateSnapshot)!;
            scoringLogicConfig = snapshot.ScoringLogicConfig;
            snapshotDisplayNoun = snapshot.DisplayNoun;

            groups = snapshot.Groups.Select(g => new Group
            {
                Id = g.Id,
                Title = g.Title,
                Weight = g.Weight,
                MaxDeductionPoints = g.MaxDeductionPoints,
                MinusPerFault = g.MinusPerFault,
                OrderIndex = g.OrderIndex,
                ParentId = g.ParentId,
                Metadata = g.Metadata,
                IsActive = true
            }).ToList();

            criteria = snapshot.Groups.SelectMany(g => g.Criteria).Select(c => new Criterion
            {
                Id = c.Id,
                GroupId = c.GroupId,
                Label = c.Label,
                InputType = c.InputType,
                PointsWeight = c.PointsWeight,
                IsCcp = c.IsCcp,
                IsRisk = c.IsRisk,
                MinusImpact = c.MinusImpact,
                OrderIndex = c.OrderIndex,
                Metadata = c.Metadata,
                IsActive = true
            }).ToList();
        }
        else
        {
            // Fallback — live DB reads for pre-migration drafts
            var template = await db.Templates
                .AsNoTracking()
                .FirstOrDefaultAsync(t => t.Id == submission.TemplateId, ct);

            if (template is null)
                return TypedResults.BadRequest(new { error = "Template not found" });

            scoringLogicConfig = template.ScoringLogicConfig;
            snapshotDisplayNoun = template.DisplayNoun;

            groups = await db.Groups
                .AsNoTracking()
                .Where(g => g.TemplateId == submission.TemplateId && g.IsActive)
                .ToListAsync(ct);

            var groupIds = groups.Select(g => g.Id).ToList();
            criteria = await db.Criteria
                .AsNoTracking()
                .Where(c => groupIds.Contains(c.GroupId) && c.IsActive)
                .ToListAsync(ct);
        }

        // 4. Verify score — parse scoring mode from template config
        var scoringMode = "penalty";
        if (!string.IsNullOrEmpty(scoringLogicConfig))
        {
            try
            {
                var configDoc = System.Text.Json.JsonDocument.Parse(scoringLogicConfig);
                if (configDoc.RootElement.TryGetProperty("scoringMode", out var modeElem))
                    scoringMode = modeElem.GetString() ?? "penalty";
            }
            catch { /* malformed config → default to penalty */ }
        }

        var tempAnswers = request.Answers.Select(a => new Answer
        {
            CriteriaId = a.CriteriaId,
            NumericValue = a.NumericValue,
            Value = a.Value
        }).ToList();

        var verification = scorer.Verify(request.ClientScore, tempAnswers, groups, criteria,
            scoringMode: scoringMode);

        var scoreMode = config["ScoreVerification:Mode"] ?? "enforce";
        if (!verification.IsValid && scoreMode == "enforce")
        {
            return TypedResults.BadRequest(new
            {
                error = "Score verification failed",
                clientScore = request.ClientScore,
                serverScore = verification.ServerScore,
                reason = verification.Reason
            });
        }

        // 5. Update submission
        var now = DateTimeOffset.UtcNow;
        submission.Status = "completed";
        submission.TotalScore = scoringMode == "survey" ? null : verification.ServerScore;
        submission.ScoringMode = scoringMode;
        submission.SectionScores = request.SectionScores;
        submission.Notes = request.Notes;
        submission.GpsLat = request.GpsLat;
        submission.GpsLng = request.GpsLng;
        submission.GpsVerifiedAt = request.GpsLat.HasValue ? now : null;
        submission.CompletedAt = now;
        submission.UpdatedAt = now;
        submission.DisplayNoun = snapshotDisplayNoun;

        // 6. Delete any existing draft answers (if any) then create new
        var existingAnswers = await db.Answers
            .Where(a => a.SubmissionId == submission.Id)
            .ToListAsync(ct);
        if (existingAnswers.Count > 0)
            db.Answers.RemoveRange(existingAnswers);

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
            IsFailure = verification.FailedCriteriaIds.Contains(a.CriteriaId),
            CriteriaLabel = criteria.FirstOrDefault(c => c.Id == a.CriteriaId)?.Label,
            CreatedAt = now,
            UpdatedAt = now
        }).ToList();

        db.Answers.AddRange(answers);

        AuditLogger.Log(db, user, "submission_finalized", "submission", submission.Id,
            $"Finalized submission for store '{submission.StoreName}'",
            $"/api/submissions/{submission.Id}/finalize");

        // 7. Auto-create action plans for triggered answers (stages only, no flush)
        await ActionPlanService.AutoCreateAsync(
            submission.Id, submission.StoreId,
            answers, criteria, groups, now, db, ct,
            scoringMode: scoringMode,
            scoringLogicConfig: scoringLogicConfig);

        var strategy = db.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            // Start explicit transaction to guarantee all 3 saves complete atomically
            await using var transaction = await db.Database.BeginTransactionAsync(ct);

            // Atomic flush 1: submission update + answers + audit log + action plans
            await db.SaveChangesAsync(ct);

            // 8. Explode SectionScores JSON into relational rows (skip for survey mode)
            if (scoringMode != "survey")
            {
                await SectionScoreExploder.ExplodeAsync(submission.Id, submission.StoreId, submission.TemplateId, request.SectionScores, db, now, ct);
            }

            // 9. Upsert StoreAnalyticsSnapshot
            await StoreAnalyticsUpdater.UpdateMetricsAsync(submission.StoreId, submission, db, now, ct);

            await transaction.CommitAsync(ct);

            return TypedResults.Ok(new SubmissionDto(
                submission.Id, submission.TemplateId, submission.TemplateTitle, submission.DisplayNoun,
                submission.StoreId, submission.StoreName, submission.AuditorId,
                submission.AuditorName, submission.Status, submission.TotalScore,
                submission.SectionScores, submission.Notes,
                submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt,
                submission.TemplateVersion));
        });
    }
}
