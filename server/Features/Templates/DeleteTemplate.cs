using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// DELETE /api/templates/{id} — soft-delete a template (AdminOnly).
/// </summary>
public static class DeleteTemplate
{
    public static async Task<IResult> HandleAsync(Guid id, AppDbContext db)
    {
        var template = await db.Templates.FindAsync(id);
        if (template is null)
            return Results.NotFound();

        template.IsActive = false;
        template.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        return Results.NoContent();
    }
}
