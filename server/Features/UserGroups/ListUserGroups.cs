using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// GET /api/user-groups — list all user groups (AdminOnly).
/// </summary>
public static class ListUserGroups
{
    public sealed record UserGroupListItem(Guid Id, string Name, string? Description);

    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var page = int.TryParse(httpContext.Request.Query["page"], out var pg) ? Math.Max(1, pg) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        var query = db.UserGroups.OrderBy(g => g.Name);

        var total = await query.CountAsync(ct);

        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<UserGroupListItem>([], total, page, pageSize));

        var groups = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(g => new UserGroupListItem(g.Id, g.Name, g.Description))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<UserGroupListItem>(groups, total, page, pageSize));
    }
}
