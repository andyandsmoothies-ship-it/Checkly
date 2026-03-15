using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// POST /api/submissions — creates submission + answers in one transaction.
/// Snapshots auditor/store/template names. Verifies score server-side.
/// </summary>
public static class CreateSubmission
{
    public static async Task<IResult> HandleAsync(
        CreateSubmissionRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        ScoringVerifier scorer,
        IConfiguration config,
        CancellationToken ct)
    {
        var auditorId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Idempotency check — if key already used, return existing submission
        if (!string.IsNullOrWhiteSpace(request.IdempotencyKey))
        {
            var existing = await db.Submissions
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.IdempotencyKey == request.IdempotencyKey, ct);

            if (existing is not null)
            {
                return TypedResults.Ok(new SubmissionDto(
                    existing.Id, existing.TemplateId, existing.TemplateTitle,
                    existing.StoreId, existing.StoreName, existing.AuditorId,
                    existing.AuditorName, existing.Status, existing.TotalScore,
                    existing.SectionScores, existing.Notes,
                    existing.CreatedAt, existing.CompletedAt, existing.ScheduledAt));
            }
        }

        // Load template + groups + criteria for scoring verification
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

        // Load groups + criteria for this template
        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == request.TemplateId && g.IsActive)
            .ToListAsync(ct);

        var groupIds = groups.Select(g => g.Id).ToList();
        var criteria = await db.Criteria
            .AsNoTracking()
            .Where(c => groupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        // Build temporary answers for scoring
        var tempAnswers = request.Answers.Select(a => new Answer
        {
            CriteriaId = a.CriteriaId,
            NumericValue = a.NumericValue,
            Value = a.Value
        }).ToList();

        // Verify score
        var verification = scorer.Verify(request.ClientScore, tempAnswers, groups, criteria);

        // S5: Score verification mode — enforce (reject) or observe (log only)
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
            // Observe mode: log mismatch but allow submission with server score
        }

        // Snapshot auditor info
        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == auditorId, ct);

        // Create submission
        var now = DateTimeOffset.UtcNow;
        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = request.TemplateId,
            StoreId = request.StoreId,
            AuditorId = auditorId,
            Status = "completed",
            TotalScore = verification.ServerScore,
            SectionScores = request.SectionScores,
            Notes = request.Notes,
            GpsLat = request.GpsLat,
            GpsLng = request.GpsLng,
            GpsVerifiedAt = request.GpsLat.HasValue ? now : null,
            CompletedAt = now,
            StartedAt = now,
            CreatedAt = now,
            UpdatedAt = now,
            // Snapshot fields
            AuditorName = profile?.FullName,
            AuditorEmail = profile?.Email,
            StoreName = store.Name,
            TemplateTitle = template.Title,
            IdempotencyKey = request.IdempotencyKey
        };

        // Create answers
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

        // Single transaction
        db.Submissions.Add(submission);
        db.Answers.AddRange(answers);
        await db.SaveChangesAsync(ct);

        // --- S1: Auto-create action plans for failed answers ---
        var failedAnswers = answers.Where(a => a.Value == "non_conform").ToList();

        if (failedAnswers.Count > 0)
        {
            // Idempotency: skip if APs already exist for this submission
            var existingAPs = await db.ActionPlans
                .AnyAsync(ap => ap.SubmissionId == submission.Id, ct);

            if (!existingAPs)
            {
                // Look up current SM for this store (live lookup per CORE_WORKFLOWS L103)
                var smProfile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.StoreId == store.Id, ct);

                // Deadline: default 7 days
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
                        StoreName = store.Name,
                        StoreManagerName = smProfile?.FullName,
                        CreatedAt = now,
                        UpdatedAt = now
                    });
                }

                await db.SaveChangesAsync(ct);
            }
        }

        return TypedResults.Created($"/api/submissions/{submission.Id}", new SubmissionDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.CreatedAt, submission.CompletedAt, submission.ScheduledAt));
    }
}
