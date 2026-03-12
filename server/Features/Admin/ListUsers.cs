using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// GET /api/admin/users — list all users with profiles and roles.
/// Supports optional ?role= query filter.
/// </summary>
public static class ListUsers
{
    public record UserDto(
        Guid Id,
        string? FullName,
        string? Email,
        string? AvatarUrl,
        string Role,
        Guid? StoreId,
        string? AreaCode,
        bool IsLocked,
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

        var roleFilter = httpContext.Request.Query["role"].FirstOrDefault();
        var search = httpContext.Request.Query["search"].FirstOrDefault();

        var query = from p in db.Profiles.AsNoTracking()
                    join r in db.AppUserRoles.AsNoTracking() on p.Id equals r.UserId
                    select new { p, r };

        if (!string.IsNullOrEmpty(roleFilter))
            query = query.Where(x => x.r.Role == roleFilter);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(x =>
                (x.p.FullName != null && x.p.FullName.Contains(search)) ||
                (x.p.Email != null && x.p.Email.Contains(search)));

        // Pagination (defaults: page 1, 50 items, max 100)
        var page = int.TryParse(httpContext.Request.Query["page"], out var pg) ? Math.Max(1, pg) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 100) : 50;

        var total = await query.CountAsync(ct);

        var users = await query
            .OrderBy(x => x.p.FullName)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new UserDto(
                x.p.Id,
                x.p.FullName,
                x.p.Email,
                x.p.AvatarUrl,
                x.r.Role,
                x.p.StoreId,
                x.p.AreaCode,
                false, // LockoutEnd check deferred — not a direct Profile field
                x.p.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new { items = users, total, page, pageSize });
    }
}
