using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// GET /api/admin/logs — paginated system logs with optional level/category filter.
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
        DateTimeOffset CreatedAt);

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        var levelFilter = httpContext.Request.Query["level"].FirstOrDefault();
        var categoryFilter = httpContext.Request.Query["category"].FirstOrDefault();
        var pageStr = httpContext.Request.Query["page"].FirstOrDefault();
        var page = int.TryParse(pageStr, out var p) ? Math.Max(1, p) : 1;
        const int pageSize = 50;

        var query = db.SystemLogs.AsNoTracking().AsQueryable();

        if (!string.IsNullOrEmpty(levelFilter) && levelFilter != "all")
            query = query.Where(l => l.Level == levelFilter);

        if (!string.IsNullOrEmpty(categoryFilter) && categoryFilter != "all")
            query = query.Where(l => l.Category == categoryFilter);

        var totalCount = await query.CountAsync(ct);

        var logs = await query
            .OrderByDescending(l => l.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(l => new SystemLogDto(
                l.Id, l.UserId, l.Action, l.Category,
                l.Message, l.Path, l.Level,
                l.EntityType, l.EntityId, l.CreatedAt))
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
