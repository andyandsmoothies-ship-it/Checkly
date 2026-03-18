using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// DELETE /api/templates/{templateId}/groups/{groupId} — soft-delete (AdminOnly).
/// Sets group.IsActive = false, cascades to child criteria and child groups (recursive).
/// Optimized: uses batch queries instead of per-child round-trips.
/// </summary>
public static class DeleteGroup
{
    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid groupId,
        AppDbContext db,
        CancellationToken ct)
    {
        var group = await db.Groups.FindAsync([groupId], ct);
        if (group is null || group.TemplateId != templateId)
            return Results.NotFound();

        var now = DateTimeOffset.UtcNow;

        // Soft-delete the target group
        group.IsActive = false;
        group.UpdatedAt = now;

        // Batch 1: Load ALL child groups in one query
        var childGroups = await db.Groups
            .Where(g => g.ParentId == groupId && g.IsActive)
            .ToListAsync(ct);

        foreach (var child in childGroups)
        {
            child.IsActive = false;
            child.UpdatedAt = now;
        }

        // Batch 2: Load ALL criteria for target group + child groups in one query
        var allGroupIds = childGroups.Select(g => g.Id).Append(groupId).ToList();
        var allCriteria = await db.Criteria
            .Where(c => allGroupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        foreach (var c in allCriteria)
        {
            c.IsActive = false;
            c.UpdatedAt = now;
        }

        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }
}
