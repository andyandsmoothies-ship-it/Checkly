using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// PUT /api/user-groups/{id}/members — replace all members of a group (AdminOnly).
/// Accepts { profileIds: Guid[] }.
/// </summary>
public static class UpdateMembers
{
    public sealed record Request(Guid[] ProfileIds);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        var group = await db.UserGroups
            .Include(g => g.Members)
            .FirstOrDefaultAsync(g => g.Id == id, ct);

        if (group is null)
            return TypedResults.NotFound();

        // Remove all existing members
        db.UserGroupMembers.RemoveRange(group.Members);

        // Add new members
        var now = DateTimeOffset.UtcNow;
        foreach (var profileId in request.ProfileIds)
        {
            db.UserGroupMembers.Add(new UserGroupMember
            {
                Id = Guid.NewGuid(),
                UserGroupId = id,
                ProfileId = profileId,
                CreatedAt = now
            });
        }

        group.UpdatedAt = now;
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok();
    }
}
