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

        var submissions = await query
            .OrderByDescending(s => s.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new SubmissionDto(
                s.Id, s.TemplateId, s.TemplateTitle, s.TemplateType, s.DisplayNoun,
                s.StoreId, s.StoreName, s.AuditorId,
                s.AuditorName, s.Status, s.TotalScore,
                s.SectionScores, s.Notes,
                s.CreatedAt, s.CompletedAt, s.ScheduledAt,
                s.TemplateVersion))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<SubmissionDto>(submissions, total, page, pageSize));
    }
}

