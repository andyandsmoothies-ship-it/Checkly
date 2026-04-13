using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
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
        ClaimsPrincipal user,
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

        AuditLogger.Log(
            db, user,
            action: "user_group_members_updated",
            entityType: "UserGroup",
            entityId: id,
            message: $"{request.ProfileIds.Length} member(s) assigned",
            userEmail: user.FindFirstValue(ClaimTypes.Email));

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok();
    }
}
