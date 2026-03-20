using System.Security.Claims;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Features.ActionPlans;
using Microsoft.EntityFrameworkCore;

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
        var auditorId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Determine mode
        var requestedStatus = request.Status?.ToLowerInvariant() ?? "completed";
        if (!ValidStatuses.Contains(requestedStatus))
            return TypedResults.BadRequest(new { error = $"Invalid status: '{request.Status}'. Must be draft, scheduled, or completed." });

        var isDraft = requestedStatus == "draft";
        var isScheduled = requestedStatus == "scheduled";

        // Idempotency check — if key already used, return existing submission
        if (!string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            var existing = await db.Submissions
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.IdempotencyKey == request.IdempotencyKey, ct);

            if (existing is not null)
            {
                return TypedResults.Ok(new SubmissionDto(
                    existing.Id, existing.TemplateId, existing.TemplateTitle, existing.DisplayNoun,
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
                return TypedResults.BadRequest(new { error = "ClientScore is required for completed submissions" });
            if (request.Answers is null || request.Answers.Count == 0)
                return TypedResults.BadRequest(new { error = "Answers are required for completed submissions" });
        }

        // Load template (always needed for snapshot)
        var template = await db.Templates
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == request.TemplateId, ct);

        if (template is null)
            return TypedResults.BadRequest(new { error = "Template not found" });

        if (!template.IsActive)
            return TypedResults.BadRequest(new { error = "Template is archived" });

        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == request.StoreId, ct);

        if (store is null)
            return TypedResults.BadRequest(new { error = "Store not found" });

        if (store.IsActive == false)
            return TypedResults.BadRequest(new { error = "Store is deactivated" });

        if (store.AreaId.HasValue)
        {
            var area = await db.Areas.AsNoTracking()
                .FirstOrDefaultAsync(a => a.Id == store.AreaId.Value, ct);
            if (area is not null && !area.IsActive)
                return TypedResults.BadRequest(new { error = "Area is deactivated" });
        }

        // Load groups + criteria for ALL statuses (needed for snapshot)
        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == request.TemplateId && g.IsActive)
            .ToListAsync(ct);

        var groupIds = groups.Select(g => g.Id).ToList();
        var criteria = await db.Criteria
            .AsNoTracking()
            .Where(c => groupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        // Build template snapshot JSON
        var snapshotModel = new TemplateSnapshotModel
        {
            SnapshotVersion = 1,
            Title = template.Title,
            Version = template.Version,
            ScoringLogicConfig = template.ScoringLogicConfig,
            DisplayNoun = template.DisplayNoun,
            Groups = groups.Select(g => new SnapshotGroup
            {
                Id = g.Id,
                Title = g.Title,
                Weight = g.Weight,
                MaxDeductionPoints = g.MaxDeductionPoints,
                MinusPerFault = g.MinusPerFault,
                OrderIndex = g.OrderIndex,
                ParentId = g.ParentId,
                Metadata = g.Metadata,
                Criteria = criteria.Where(c => c.GroupId == g.Id).Select(c => new SnapshotCriterion
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
                    Metadata = c.Metadata
                }).ToList()
            }).ToList()
        };
        var templateSnapshotJson = JsonSerializer.Serialize(snapshotModel);

        // Scoring verification — only for completed submissions
        decimal? serverScore = null;

        if (!isDraft && !isScheduled)
        {
            // Parse scoring mode from template config
            var scoringMode = "penalty";
            if (!string.IsNullOrEmpty(template.ScoringLogicConfig))
            {
                try
                {
                    var configDoc = System.Text.Json.JsonDocument.Parse(template.ScoringLogicConfig);
                    if (configDoc.RootElement.TryGetProperty("scoringMode", out var modeElem))
                        scoringMode = modeElem.GetString() ?? "penalty";
                }
                catch { /* malformed config → default to penalty */ }
            }

            var tempAnswers = request.Answers!.Select(a => new Answer
            {
                CriteriaId = a.CriteriaId,
                NumericValue = a.NumericValue,
                Value = a.Value
            }).ToList();

            var verification = scorer.Verify(request.ClientScore!.Value, tempAnswers, groups, criteria,
                scoringMode: scoringMode);

            var scoreMode = config["ScoreVerification:Mode"] ?? "enforce";
            if (!verification.IsValid)
            {
                if (scoreMode == "enforce")
                {
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

        // Snapshot auditor info
        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == auditorId, ct);

        // Parse scoring mode from template config (for all statuses — denormalized for analytics)
        var submissionScoringMode = "penalty";
        if (!string.IsNullOrEmpty(template.ScoringLogicConfig))
        {
            try
            {
                var cfgDoc = System.Text.Json.JsonDocument.Parse(template.ScoringLogicConfig);
                if (cfgDoc.RootElement.TryGetProperty("scoringMode", out var modeVal))
                    submissionScoringMode = modeVal.GetString() ?? "penalty";
            }
            catch { /* malformed config → default to penalty */ }
        }

        // Create submission
        var now = DateTimeOffset.UtcNow;
        var submission = new Submission
        {
            Id = Guid.NewGuid(),
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
            ScheduledAt = request.ScheduledAt,
            CreatedAt = now,
            UpdatedAt = now,
            // Snapshot fields
            AuditorName = profile?.FullName,
            AuditorEmail = profile?.Email,
            StoreName = store.Name,
            TemplateTitle = template.Title,
            DisplayNoun = template.DisplayNoun,
            IdempotencyKey = request.IdempotencyKey,
            TemplateSnapshot = templateSnapshotJson,
            TemplateVersion = template.Version
        };

        db.Submissions.Add(submission);

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
                CriteriaLabel = criteria.FirstOrDefault(c => c.Id == a.CriteriaId)?.Label,
                CreatedAt = now,
                UpdatedAt = now
            }).ToList();

            db.Answers.AddRange(answers);
            await db.SaveChangesAsync(ct);

            // --- S1: Auto-create action plans for triggered answers ---
            await ActionPlanService.AutoCreateAsync(
                submission.Id, submission.StoreId,
                answers, criteria, groups, now, db, ct);
        }
        else
        {
            // Draft or scheduled — just save the submission (no answers)
            await db.SaveChangesAsync(ct);
        }

        return TypedResults.Created($"/api/submissions/{submission.Id}", new SubmissionDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle, submission.DisplayNoun,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt,
            submission.TemplateVersion));
    }
}
