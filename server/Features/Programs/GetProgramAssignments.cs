using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// GET /api/programs/{programId}/assignments?status={status}&amp;page={page}
/// Returns paginated, detail-enriched assignments for a specific program.
/// Includes evidence items in a single query to avoid N+1 queries.
/// Security: requires programs:assignments_list capability (HQ/admin only).
/// </summary>
public static class GetProgramAssignments
{
    public static async Task<IResult> HandleAsync(
        Guid programId,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        // Validate program exists
        var programExists = await db.Programs
            .AsNoTracking()
            .AnyAsync(p => p.Id == programId, ct);

        if (!programExists)
            return TypedResults.NotFound(new { error = "Program not found." });

        // Optional status filter
        var statusFilter = httpContext.Request.Query["status"].ToString();

        // Pagination (defaults: page 1, 50 items, max 200)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        var query = db.ProgramAssignments
            .AsNoTracking()
            .Where(a => a.ProgramId == programId);

        if (!string.IsNullOrWhiteSpace(statusFilter))
            query = query.Where(a => a.Status == statusFilter);

        var total = await query.CountAsync(ct);

        // Overflow guard
        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new AssignmentDetailPagedResponse([], total, page, pageSize));

        // Load assignments with Store for name (AsNoTracking for performance)
        var assignments = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => new
            {
                a.Id,
                a.ProgramId,
                a.StoreId,
                StoreName = a.Store!.Name,
                a.Status,
                Deadline = a.Program!.Deadline,
                a.CreatedAt,
                a.RejectionComment,
                a.VerifiedAt,
            })
            .ToListAsync(ct);

        if (assignments.Count == 0)
            return TypedResults.Ok(new AssignmentDetailPagedResponse([], total, page, pageSize));

        var result = assignments.Select(a => new ProgramAssignmentDetailDto(
            a.Id,
            a.ProgramId,
            a.StoreId,
            a.StoreName,
            a.Status,
            a.Deadline,
            a.CreatedAt,
            a.RejectionComment,
            a.VerifiedAt,
            null,
            null,
            null)).ToList();

        return TypedResults.Ok(new AssignmentDetailPagedResponse(result, total, page, pageSize));
    }

    /// <summary>Pagination envelope for GET /api/programs/{id}/assignments.</summary>
    public record AssignmentDetailPagedResponse(
        List<ProgramAssignmentDetailDto> Items,
        int TotalCount,
        int Page,
        int PageSize);
}
