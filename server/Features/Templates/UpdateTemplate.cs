using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// PUT /api/templates/{id} — update template metadata (AdminOnly).
/// Uses optimistic concurrency (RowVersion/xmin) to detect conflicts.
/// </summary>
public static class UpdateTemplate
{
    public record Request(
        string? Title,
        string? Description,
        string? Type,
        string? ScoringLogicConfig);

    public static async Task<IResult> HandleAsync(Guid id, Request request, AppDbContext db)
    {
        var template = await db.Templates.FindAsync(id);
        if (template is null)
            return Results.NotFound();

        if (!template.IsActive)
            return Results.BadRequest(new { error = "Cannot update an archived template" });

        if (request.Title != null)
            template.Title = request.Title.Trim();
        if (request.Description != null)
            template.Description = request.Description.Trim();
        if (request.Type != null)
            template.Type = request.Type.Trim();
        if (request.ScoringLogicConfig != null)
            template.ScoringLogicConfig = request.ScoringLogicConfig;

        template.Version++;
        template.UpdatedAt = DateTimeOffset.UtcNow;

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            return Results.Conflict(new
            {
                error = "Template was modified by another user. Please refresh and try again."
            });
        }

        return Results.Ok(new
        {
            id = template.Id,
            title = template.Title,
            version = template.Version,
            updatedAt = template.UpdatedAt,
        });
    }
}
