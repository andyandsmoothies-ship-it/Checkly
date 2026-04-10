using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.UserGroups;

/// <summary>
/// Maps the /api/user-groups route group.
/// All endpoints require the users:manage capability.
/// </summary>
public static class UserGroupEndpoints
{
    public static void MapUserGroupEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/user-groups")
            .WithTags("UserGroups")
            .RequireAuthorization();

        group.MapPost("/", CreateUserGroup.HandleAsync)
            .WithName("CreateUserGroup")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapGet("/", ListUserGroups.HandleAsync)
            .WithName("ListUserGroups")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapPut("/{id}/members", UpdateMembers.HandleAsync)
            .WithName("UpdateGroupMembers")
            .RequireCapability(AppCapabilities.UsersManage);
    }
}
