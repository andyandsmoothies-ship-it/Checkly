using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions — role-scoped paginated list.
/// Ownership scoping (admin/auditor/store_manager/area_manager) is delegated to
/// OwnershipScopeFilter.ApplyAsync — see Common/Auth/OwnershipScopeFilter.cs.
/// Capability gate: submissions:list (enforced at route level via RequireCapability).
/// </summary>
public static class ListSubmissions
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        PbacDictionaryCache pbacCache,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var query = db.Submissions.AsNoTracking().AsQueryable();

        // Apply role-based ownership scope (admin → all, auditor → own, etc.)
        query = await OwnershipScopeFilter.ApplyAsync(query, user, db, ct);

        // Optional status filter: ?status=draft|scheduled|in_progress|completed|finalized|void
        var statusFilter = httpContext.Request.Query["status"].ToString();
        if (!string.IsNullOrEmpty(statusFilter))
            query = query.Where(s => s.Status == statusFilter);

        // Pagination (defaults: page 1, 50 items, max 100)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 100) : 50;

        var total = await query.CountAsync(ct);

        // Overflow guard: if the requested skip exceeds total rows, return empty page without hitting DB
        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<SubmissionDto>([], total, page, pageSize));

        // --- Compute AllowedActions flags ---
        // RULE: Evaluate BEFORE the .Select() lambda — EF cannot translate PbacDictionaryCache calls.
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
        var capabilities = pbacCache.GetCapabilities(role);
        _ = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var callerId);

        var canFinalize = capabilities.Contains(AppCapabilities.SubmissionsReview);
        var canCreate = capabilities.Contains(AppCapabilities.SubmissionsCreate);

        var rows = await query
            .OrderByDescending(s => s.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new
            {
                s.Id,
                s.TemplateId,
                s.TemplateTitle,
                s.TemplateType,
                s.DisplayNoun,
                s.StoreId,
                s.StoreName,
                s.AuditorId,
                s.AuditorName,
                s.Status,
                s.TotalScore,
                s.SectionScores,
                s.Notes,
                s.CreatedAt,
                s.CompletedAt,
                s.ScheduledAt,
                s.TemplateVersion,
                s.RawEarnedPoints,
                s.RawMaxPoints,
                s.IsWeighted,
                s.ScoringMode
            })
            .ToListAsync(ct);

        // Post-query in-memory mapping: AllowedActions is computed from pre-evaluated bool flags.
        // This is a single DB round-trip — no N+1.
        var submissions = rows.Select(s =>
        {
            var isOwner = s.AuditorId == callerId;
            var actions = new List<string> { SubmissionActions.View };

            if (canCreate && isOwner && (s.Status == "draft" || s.Status == "scheduled"))
                actions.Add(SubmissionActions.Edit);

            if (canFinalize && s.Status == "completed")
                actions.Add(SubmissionActions.Finalize);

            if (canFinalize && s.Status != "approved" && s.Status != "rejected")
                actions.Add(SubmissionActions.Void);

            return new SubmissionDto(
                s.Id, s.TemplateId, s.TemplateTitle, s.TemplateType, s.DisplayNoun,
                s.StoreId, s.StoreName, s.AuditorId,
                s.AuditorName, s.Status, s.TotalScore,
                s.SectionScores, s.Notes,
                s.CreatedAt, s.CompletedAt, s.ScheduledAt,
                s.TemplateVersion,
                s.RawEarnedPoints, s.RawMaxPoints, s.IsWeighted,
                s.ScoringMode,
                AllowedActions: actions);
        }).ToList();

        return TypedResults.Ok(new PagedResult<SubmissionDto>(submissions, total, page, pageSize));
    }
}

