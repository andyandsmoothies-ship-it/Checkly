using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// DELETE /api/templates/{templateId}/groups/{groupId} — soft-delete (AdminOnly).
/// Sets group.IsActive = false, cascades to child criteria and child groups (recursive).
/// </summary>
public static class DeleteGroup
{
    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid groupId,
        AppDbContext db)
    {
        var group = await db.Groups.FindAsync(groupId);
        if (group is null || group.TemplateId != templateId)
            return Results.NotFound();

        // Soft-delete the group itself
        group.IsActive = false;
        group.UpdatedAt = DateTimeOffset.UtcNow;

        // Cascade: soft-delete all criteria in this group
        var criteria = await db.Criteria
            .Where(c => c.GroupId == groupId && c.IsActive)
            .ToListAsync();
        foreach (var c in criteria)
        {
            c.IsActive = false;
            c.UpdatedAt = DateTimeOffset.UtcNow;
        }

        // Cascade: soft-delete child groups (recursive via self-referencing ParentGroupId)
        var childGroups = await db.Groups
            .Where(g => g.ParentId == groupId && g.IsActive)
            .ToListAsync();
        foreach (var child in childGroups)
        {
            child.IsActive = false;
            child.UpdatedAt = DateTimeOffset.UtcNow;

            // Also soft-delete criteria of child groups
            var childCriteria = await db.Criteria
                .Where(c => c.GroupId == child.Id && c.IsActive)
                .ToListAsync();
            foreach (var cc in childCriteria)
            {
                cc.IsActive = false;
                cc.UpdatedAt = DateTimeOffset.UtcNow;
            }
        }

        await db.SaveChangesAsync();
        return Results.NoContent();
    }
}
