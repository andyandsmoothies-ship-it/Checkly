using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions/{id} — single submission with all answers.
/// Enforces role-based access: admin sees all, auditor sees own,
/// store_manager sees their store, area_manager sees their area.
/// </summary>
public static class GetSubmission
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var submission = await db.Submissions
            .AsNoTracking()
            .Include(s => s.Answers)
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (submission is null)
            return TypedResults.NotFound();

        // --- IDOR Protection: Verify the user has access to this submission ---
        var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
            user, submission.StoreId, areaId: null, auditorId: submission.AuditorId, db, ct);

        if (!hasAccess)
            return TypedResults.Forbid();

        var dto = new SubmissionDetailDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle, submission.DisplayNoun,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.GpsLat, submission.GpsLng,
            submission.CreatedAt, submission.CompletedAt,
            submission.Answers.Select(a => new AnswerDto(
                a.Id, a.CriteriaId, a.CriteriaLabel,
                a.Value, a.NumericValue, a.Note,
                a.PhotoUrl, a.IsRepeatedError,
                a.IsCcp, a.IsRisk)).ToList(),
            submission.TemplateSnapshot,
            submission.TemplateVersion);

        return TypedResults.Ok(dto);
    }
}

