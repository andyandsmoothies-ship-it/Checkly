using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// DELETE /api/templates/{templateId}/criteria/{criterionId} — soft-delete (AdminOnly).
/// Sets criterion.IsActive = false.
/// </summary>
public static class DeleteCriterion
{
    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid criterionId,
        AppDbContext db)
    {
        var criterion = await db.Criteria.FindAsync(criterionId);
        if (criterion is null)
            return Results.NotFound();

        // Verify criterion belongs to a group in this template
        var group = await db.Groups.FindAsync(criterion.GroupId);
        if (group is null || group.TemplateId != templateId)
            return Results.NotFound();

        criterion.IsActive = false;
        criterion.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        return Results.NoContent();
    }
}
