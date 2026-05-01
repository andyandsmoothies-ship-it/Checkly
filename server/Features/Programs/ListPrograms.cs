using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// GET /api/programs — paginated list of programs.
/// Access control: admin sees all programs.
/// Pagination: same overflow guard pattern as ListTemplates.
/// </summary>
public static class ListPrograms
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        // All callers must have programs:list capability (enforced at route level).
        // For MVP, admins see all programs.
        var query = db.Programs.AsQueryable();

        // Pagination (defaults: page 1, 50 items, max 200)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        var total = await query.CountAsync(ct);

        // Overflow guard: if the requested skip exceeds total rows, return empty page without hitting DB
        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new ProgramsPagedResponse([], total, page, pageSize));

        var programs = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new ProgramSummaryDto(
                p.Id,
                p.Title,
                p.Category,
                p.Deadline,
                p.Status,
                p.Assignments.Count,
                p.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new ProgramsPagedResponse(programs, total, page, pageSize));
    }

    /// <summary>
    /// Pagination envelope for GET /api/programs.
    /// Uses 'totalCount' to match the TC5 ATDD test contract.
    /// NOTE: Other endpoints use PagedResult which serializes as 'total'.
    /// </summary>
    public record ProgramsPagedResponse(
        List<ProgramSummaryDto> Items,
        int TotalCount,
        int Page,
        int PageSize);
}
