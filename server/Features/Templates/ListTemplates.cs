using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/templates — flat list of active templates.
///
/// Access control: non-admin users only see templates that are either
/// unassigned (global) or assigned to a group they belong to.
/// </summary>
public static class ListTemplates
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var isAdmin = user.IsInRole("admin");

        var query = db.Templates.Where(t => t.IsActive);

        // Non-admin: filter by group membership
        if (!isAdmin)
        {
            var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var userGroupIds = await db.UserGroupMembers
                .Where(m => m.ProfileId == userId)
                .Select(m => m.UserGroupId)
                .ToListAsync(ct);

            query = query.Where(t =>
                !t.Assignments.Any() ||
                t.Assignments.Any(a => userGroupIds.Contains(a.UserGroupId)));
        }

        var templates = await query
            .OrderBy(t => t.Title)
            .Take(200)
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.DisplayNoun, t.IsActive, t.CreatedAt, t.UpdatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(templates);
    }
}
