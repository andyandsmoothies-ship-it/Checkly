using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// GET /api/submissions/{submissionId}/risks
/// Lists all triggered risks for a submission.
/// Returns a raw JSON array (not PagedResult) — risks are a small bounded set per submission.
/// IDOR guard: caller must own the submission.
/// </summary>
public static class ListSubmissionRisks
{
    public static async Task<IResult> HandleAsync(
        Guid submissionId,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // 1. Load submission for IDOR check
        var submission = await db.Submissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId, ct);

        if (submission is null)
            return TypedResults.NotFound(new { message = "Submission not found." });

        // 2. IDOR guard
        if (!await SubmissionAccessGuard.CanAccessAsync(
                user, submission.StoreId, areaId: null, submission.AuditorId, db, ct))
            return TypedResults.Forbid();

        // 3. Query risks (join to GlobalRisk for label)
        var risks = await db.SubmissionRisks
            .AsNoTracking()
            .Where(r => r.SubmissionId == submissionId)
            .Join(db.GlobalRisks,
                sr => sr.GlobalRiskId,
                gr => gr.Id,
                (sr, gr) => new SubmissionRiskDto(
                    sr.Id,
                    sr.SubmissionId,
                    sr.GlobalRiskId,
                    gr.Label,
                    sr.TriggeredById,
                    sr.TriggeredAt,
                    sr.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(risks);
    }
}
