using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/templates — flat list of active templates.
/// </summary>
public static class ListTemplates
{
    public static async Task<IResult> HandleAsync(AppDbContext db, CancellationToken ct)
    {
        var templates = await db.Templates
            .Where(t => t.IsActive)
            .OrderBy(t => t.Title)
            .Take(200)
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.IsActive, t.CreatedAt, t.UpdatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(templates);
    }
}
