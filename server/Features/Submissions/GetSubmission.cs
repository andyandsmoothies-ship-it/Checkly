using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Auth;
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
        PbacDictionaryCache pbacCache,
        CancellationToken ct)
    {
        var submission = await db.Submissions
            .AsNoTracking()
            .Include(s => s.Answers)
            .Include(s => s.ActionPlans)
            .AsSplitQuery()
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (submission is null)
            return TypedResults.NotFound();

        // --- IDOR Protection: Verify the user has access to this submission ---
        var hasAccess = await ResourceAccessGuard.CanAccessAsync(
            user, new ResourceScope(StoreId: submission.StoreId, OwnerId: submission.AuditorId), db, ct);

        if (!hasAccess)
            return TypedResults.Forbid();

        // --- Compute AllowedActions ---
        // RULE: Extract role + capabilities BEFORE any mapping. PbacDictionaryCache
        // cannot be called inside a LINQ/EF expression tree.
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
        var capabilities = pbacCache.GetCapabilities(role);

        _ = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var callerId);
        var isOwner = submission.AuditorId == callerId;

        var canFinalize = capabilities.Contains(AppCapabilities.SubmissionsReview);
        var canEdit = capabilities.Contains(AppCapabilities.SubmissionsCreate) && isOwner;

        var allowedActions = new List<string> { SubmissionActions.View };

        if (canEdit && (submission.Status == SubmissionStatus.Draft || submission.Status == SubmissionStatus.Scheduled))
            allowedActions.Add(SubmissionActions.Edit);

        if (canFinalize && submission.Status == SubmissionStatus.Completed)
            allowedActions.Add(SubmissionActions.Finalize);

        if (canFinalize && submission.Status != ReviewStatus.Approved && submission.Status != ReviewStatus.Rejected)
            allowedActions.Add(SubmissionActions.Void);

        var dto = new SubmissionDetailDto(
            submission.Id, submission.TemplateId, submission.TemplateTitle, submission.TemplateType, submission.DisplayNoun,
            submission.StoreId, submission.StoreName, submission.AuditorId,
            submission.AuditorName, submission.Status, submission.TotalScore,
            submission.SectionScores, submission.Notes,
            submission.GpsLat, submission.GpsLng,
            submission.CreatedAt, submission.CompletedAt,
            submission.Answers.Select(a => new AnswerDto(
                a.Id, a.CriteriaId, a.CriteriaLabel,
                a.Value, a.NumericValue, a.Note,
                a.PhotoUrl, a.IsRepeatedError,
                a.IsCcp, a.IsRisk,
                submission.ActionPlans.FirstOrDefault(ap => ap.AnswerId == a.Id)?.Id)).ToList(),
            submission.TemplateSnapshot,
            submission.TemplateVersion,
            submission.RawEarnedPoints, submission.RawMaxPoints, submission.IsWeighted,
            submission.ScoringMode,
            AllowedActions: allowedActions,
            IsGeofenceBypassed: submission.IsGeofenceBypassed,
            DistanceMetersOff: submission.DistanceMetersOff,
            AreaManagerId: submission.AreaManagerId,
            AreaManagerName: submission.AreaManagerName,
            StoreManagerId: submission.StoreManagerId,
            StoreManagerName: submission.StoreManagerName);

        return TypedResults.Ok(dto);
    }
}

