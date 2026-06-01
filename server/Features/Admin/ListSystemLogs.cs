using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// GET /api/admin/logs — paginated system logs with optional filters.
/// Supports: level, category, search (ILike across message/action/email),
/// startDate, endDate (DateTimeOffset), traceId (exact match).
/// </summary>
public static class ListSystemLogs
{
    public record SystemLogDto(
        Guid Id,
        Guid? UserId,
        string Action,
        string Category,
        string? Message,
        string? Path,
        string Level,
        string? EntityType,
        Guid? EntityId,
        string? TraceId,
        string? UserEmail,
        DateTimeOffset CreatedAt);

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {


        var q = httpContext.Request.Query;
        var levelFilter = q["level"].FirstOrDefault();
        var categoryFilter = q["category"].FirstOrDefault();
        var search = q["search"].FirstOrDefault();
        var startDateStr = q["startDate"].FirstOrDefault();
        var endDateStr = q["endDate"].FirstOrDefault();
        var traceIdFilter = q["traceId"].FirstOrDefault();
        var pageStr = q["page"].FirstOrDefault();
        var page = int.TryParse(pageStr, out var p) ? Math.Max(1, p) : 1;
        const int pageSize = 50;

        var query = db.SystemLogs.AsNoTracking().AsQueryable();

        if (!string.IsNullOrEmpty(levelFilter) && levelFilter != "all")
            query = query.Where(l => l.Level == levelFilter);

        if (!string.IsNullOrEmpty(categoryFilter) && categoryFilter != "all")
            query = query.Where(l => l.Category == categoryFilter);

        if (!string.IsNullOrEmpty(traceIdFilter))
            query = query.Where(l => l.TraceId == traceIdFilter);

        // C-02 Guard: Bound search length to prevent ILike DoS wildcard attacks
        if (!string.IsNullOrEmpty(search) && search.Length >= 2 && search.Length <= 100)
            query = query.Where(l =>
                EF.Functions.ILike(l.Message ?? "", $"%{search}%") ||
                EF.Functions.ILike(l.Action, $"%{search}%") ||
                EF.Functions.ILike(l.UserEmail ?? "", $"%{search}%") ||
                l.EntityId.ToString() == search);

        if (DateTimeOffset.TryParse(startDateStr, out var startDate))
            query = query.Where(l => l.CreatedAt >= startDate.ToUniversalTime());

        if (DateTimeOffset.TryParse(endDateStr, out var endDate))
            query = query.Where(l => l.CreatedAt <= endDate.ToUniversalTime());

        var totalCount = await query.CountAsync(ct);

        var logs = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new SystemLogDto(
                l.Id, l.UserId, l.Action, l.Category,
                l.Message, l.Path, l.Level,
                l.EntityType, l.EntityId,
                l.TraceId, l.UserEmail, l.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new
        {
            page,
            pageSize,
            totalCount,
            items = logs,
        });
    }
}
