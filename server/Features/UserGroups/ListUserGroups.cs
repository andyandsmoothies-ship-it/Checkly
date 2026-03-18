using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// GET /api/user-groups — list all user groups (AdminOnly).
/// </summary>
public static class ListUserGroups
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        CancellationToken ct)
    {
        var groups = await db.UserGroups
            .OrderBy(g => g.Name)
            .Select(g => new
            {
                id = g.Id,
                name = g.Name,
                description = g.Description
            })
            .Take(200)
            .ToListAsync(ct);

        return TypedResults.Ok(groups);
    }
}
