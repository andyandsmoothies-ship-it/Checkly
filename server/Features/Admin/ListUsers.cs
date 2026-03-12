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

        var query = from p in db.Profiles.AsNoTracking()
                    join r in db.AppUserRoles.AsNoTracking() on p.Id equals r.UserId
                    select new { p, r };

        if (!string.IsNullOrEmpty(roleFilter))
            query = query.Where(x => x.r.Role == roleFilter);

        var users = await query
            .OrderBy(x => x.p.FullName)
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

        return TypedResults.Ok(users);
    }
}
