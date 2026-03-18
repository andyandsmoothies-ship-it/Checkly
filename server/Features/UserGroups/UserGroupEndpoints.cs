namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// Maps the /api/user-groups route group.
/// All endpoints require admin authorization.
/// </summary>
public static class UserGroupEndpoints
{
    public static void MapUserGroupEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/user-groups")
            .WithTags("UserGroups")
            .RequireAuthorization("AdminOnly");

        group.MapPost("/", CreateUserGroup.HandleAsync)
            .WithName("CreateUserGroup");

        group.MapGet("/", ListUserGroups.HandleAsync)
            .WithName("ListUserGroups");

        group.MapPut("/{id}/members", UpdateMembers.HandleAsync)
            .WithName("UpdateGroupMembers");
    }
}
