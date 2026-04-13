using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;

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
        ClaimsPrincipal user,
        CancellationToken ct)
    {
        // Validation: Name is required and must not exceed 200 chars (consistent with CreateStore.cs pattern)
        if (string.IsNullOrWhiteSpace(request.Name))
            return TypedResults.BadRequest(new { error = "Group name is required." });
        if (request.Name.Length > 200)
            return TypedResults.BadRequest(new { error = "Group name must not exceed 200 characters." });

        var group = new UserGroup
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.UserGroups.Add(group);

        AuditLogger.Log(
            db, user,
            action: "user_group_created",
            entityType: "UserGroup",
            entityId: group.Id,
            message: $"User group '{group.Name}' created",
            userEmail: user.FindFirstValue(ClaimTypes.Email));

        await db.SaveChangesAsync(ct);

        return TypedResults.Created($"/api/user-groups/{group.Id}", new
        {
            id = group.Id,
            name = group.Name,
            description = group.Description
        });
    }
}
