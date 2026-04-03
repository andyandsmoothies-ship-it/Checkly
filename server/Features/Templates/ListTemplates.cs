using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/templates — paginated list of active templates.
///
/// Access control: non-admin users only see templates that are either
/// unassigned (global) or assigned to a group they belong to.
/// </summary>
public static class ListTemplates
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
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

        // Pagination (defaults: page 1, 50 items, max 200)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 200) : 50;

        var total = await query.CountAsync(ct);

        // Overflow guard: if the requested skip exceeds total rows, return empty page without hitting DB
        if ((long)(page - 1) * pageSize >= total)
            return TypedResults.Ok(new PagedResult<TemplateDto>([], total, page, pageSize));

        var templates = await query
            .OrderBy(t => t.Title)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.DisplayNoun, t.IsActive, t.CreatedAt, t.UpdatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<TemplateDto>(templates, total, page, pageSize));
    }
}
