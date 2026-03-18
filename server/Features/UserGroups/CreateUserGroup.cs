using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// POST /api/user-groups — create a new user group (AdminOnly).
/// Returns 201 Created with the new group.
/// </summary>
public static class CreateUserGroup
{
    public sealed record Request(string Name, string? Description);

    public static async Task<IResult> HandleAsync(
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        var group = new UserGroup
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.UserGroups.Add(group);
        await db.SaveChangesAsync(ct);

        return TypedResults.Created($"/api/user-groups/{group.Id}", new
        {
            id = group.Id,
            name = group.Name,
            description = group.Description
        });
    }
}
