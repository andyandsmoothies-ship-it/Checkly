using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
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

        // 4. Verify score
        var tempAnswers = request.Answers.Select(a => new Answer
        {
            CriteriaId = a.CriteriaId,
            NumericValue = a.NumericValue,
            Value = a.Value
        }).ToList();

        var verification = scorer.Verify(request.ClientScore, tempAnswers, groups, criteria);

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
        submission.TotalScore = verification.ServerScore;
        submission.SectionScores = request.SectionScores;
        submission.Notes = request.Notes;
        submission.GpsLat = request.GpsLat;
        submission.GpsLng = request.GpsLng;
        submission.GpsVerifiedAt = request.GpsLat.HasValue ? now : null;
        submission.CompletedAt = now;
        submission.UpdatedAt = now;

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

        // 7. Auto-create action plans for failed answers
        var failedAnswers = answers.Where(a => a.Value == "non_conform").ToList();
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

        return TypedResults.Ok(new SubmissionDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt));
    }
}
