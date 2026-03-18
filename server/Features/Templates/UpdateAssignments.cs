using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// PUT /api/templates/{id}/assignments — replace all group assignments (AdminOnly).
/// Accepts { userGroupIds: Guid[] }.
/// Empty array = template becomes global (visible to all).
/// </summary>
public static class UpdateAssignments
{
    public sealed record Request(Guid[] UserGroupIds);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        var template = await db.Templates.FindAsync([id], ct);
        if (template is null)
            return TypedResults.NotFound();

        // Remove all existing assignments
        var existing = await db.TemplateAssignments
            .Where(a => a.TemplateId == id)
            .ToListAsync(ct);
        db.TemplateAssignments.RemoveRange(existing);

        // Add new assignments
        var now = DateTimeOffset.UtcNow;
        foreach (var groupId in request.UserGroupIds)
        {
            db.TemplateAssignments.Add(new TemplateAssignment
            {
                Id = Guid.NewGuid(),
                TemplateId = id,
                UserGroupId = groupId,
                CreatedAt = now
            });
        }

        template.UpdatedAt = now;
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok();
    }
}
