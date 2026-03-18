using System.Security.Claims;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Checkly.Api.Features.ActionPlans;
using Checkly.Api.Features.Submissions;
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

        // 3. Load template + groups + criteria for scoring
        var template = await db.Templates
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == submission.TemplateId, ct);

        if (template is null)
            return TypedResults.BadRequest(new { error = "Template not found" });

        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == submission.TemplateId && g.IsActive)
            .ToListAsync(ct);

        var groupIds = groups.Select(g => g.Id).ToList();
        var criteria = await db.Criteria
            .AsNoTracking()
            .Where(c => groupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        // 4. Verify score — parse scoring mode from template config
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
        submission.DisplayNoun = template.DisplayNoun;

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
            CriteriaLabel = criteria.FirstOrDefault(c => c.Id == a.CriteriaId)?.Label,
            CreatedAt = now,
            UpdatedAt = now
        }).ToList();

        db.Answers.AddRange(answers);
        await db.SaveChangesAsync(ct);

        // 7. Auto-create action plans for triggered answers
        var failedAnswers = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);
        if (failedAnswers.Count > 0)
        {
            var existingAPs = await db.ActionPlans
                .AnyAsync(ap => ap.SubmissionId == submission.Id, ct);

            if (!existingAPs)
            {
                var store = await db.Stores
                    .AsNoTracking()
                    .FirstOrDefaultAsync(s => s.Id == submission.StoreId, ct);

                var smProfile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.StoreId == submission.StoreId, ct);

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
                        SubmissionId = submission.Id,
                        AnswerId = fail.Id,
                        StoreId = submission.StoreId,
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

        // 8. Explode SectionScores JSON into relational rows (skip for survey mode)
        if (scoringMode != "survey" && !string.IsNullOrEmpty(request.SectionScores))
        {
            try
            {
                var sectionsDoc = JsonDocument.Parse(request.SectionScores);
                foreach (var prop in sectionsDoc.RootElement.EnumerateObject())
                {
                    var sectionTitle = prop.Name;
                    var sectionScore = prop.Value.TryGetProperty("score", out var sc) ? sc.GetDecimal() : 0m;
                    var sectionMax = prop.Value.TryGetProperty("maxScore", out var mx) ? mx.GetDecimal() : 0m;

                    db.SubmissionSectionScores.Add(new SubmissionSectionScore
                    {
                        Id = Guid.NewGuid(),
                        SubmissionId = submission.Id,
                        StoreId = submission.StoreId,
                        TemplateId = submission.TemplateId,
                        SectionTitle = sectionTitle,
                        Score = sectionScore,
                        MaxScore = sectionMax,
                        Ratio = sectionMax > 0 ? Math.Round(sectionScore / sectionMax, 4) : null,
                        IsCcpFailed = false, // ISSUE: CCP flag derivation deferred — requires group-level is_ccp aggregation during section score explosion
                        Weight = null, // ISSUE: Weight derivation deferred — requires matching SectionTitle to group.title for weight lookup
                        CreatedAt = now
                    });
                }

                await db.SaveChangesAsync(ct);
            }
            catch (JsonException)
            {
                // Malformed JSON → skip section score rows silently
            }
        }

        // 9. Upsert StoreAnalyticsSnapshot
        if (submission.StoreId.HasValue)
        {
            var thirtyDaysAgo = now.AddDays(-30);
            var storeIdVal = submission.StoreId.Value;

            // Recalculate 30-day metrics from live data
            var recentSubs = await db.Submissions
                .Where(s => s.StoreId == storeIdVal
                    && s.Status == "completed"
                    && s.CompletedAt >= thirtyDaysAgo
                    && s.TotalScore.HasValue)
                .ToListAsync(ct);

            var totalAudits = recentSubs.Count;
            var avgScore = totalAudits > 0
                ? Math.Round(recentSubs.Average(s => s.TotalScore!.Value), 1)
                : 0m;

            var openAPs = await db.ActionPlans
                .CountAsync(ap => ap.StoreId == storeIdVal && ap.Status == "open", ct);
            var overdueAPs = await db.ActionPlans
                .CountAsync(ap => ap.StoreId == storeIdVal
                    && ap.Status == "open"
                    && ap.Deadline.HasValue
                    && ap.Deadline < now, ct);

            var snapshot = await db.StoreAnalyticsSnapshots
                .FirstOrDefaultAsync(s => s.StoreId == storeIdVal, ct);

            if (snapshot is null)
            {
                snapshot = new StoreAnalyticsSnapshot { StoreId = storeIdVal };
                db.StoreAnalyticsSnapshots.Add(snapshot);
            }

            snapshot.AvgScore30d = avgScore;
            snapshot.TotalAudits30d = totalAudits;
            snapshot.OpenActionPlans = openAPs;
            snapshot.OverdueActionPlans = overdueAPs;
            snapshot.LastAuditScore = submission.TotalScore;
            snapshot.LastAuditAt = submission.CompletedAt;
            snapshot.UpdatedAt = now;

            await db.SaveChangesAsync(ct);
        }

        return TypedResults.Ok(new SubmissionDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle, submission.DisplayNoun,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt));
    }
}
