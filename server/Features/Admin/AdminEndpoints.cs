using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// Maps the /api/admin route group (requires authentication).
/// Individual endpoints enforce granular PBAC capability gates.
/// </summary>
public static class AdminEndpoints
{
    public static void MapAdminEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/admin")
            .WithTags("Admin")
            .RequireAuthorization();

        // S11: User CRUD
        group.MapGet("/users", ListUsers.HandleAsync)
            .WithName("ListUsers")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapPost("/users", CreateUser.HandleAsync)
            .WithName("CreateUser")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapPut("/users/{id}", UpdateUser.HandleAsync)
            .WithName("UpdateUser")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapPost("/users/{id}/ban", BanUser.HandleAsync)
            .WithName("BanUser")
            .RequireCapability(AppCapabilities.UsersManage);

        group.MapPost("/users/{id}/reset-password", ResetPassword.HandleAsync)
            .WithName("ResetPassword")
            .RequireCapability(AppCapabilities.UsersManage);

        // S8: SM Transfer
        group.MapPost("/stores/{storeId}/transfer", TransferStoreManager.HandleAsync)
            .WithName("TransferStoreManager")
            .RequireCapability(AppCapabilities.StoresWrite);

        // S12: System Logs
        group.MapGet("/logs", ListSystemLogs.HandleAsync)
            .WithName("ListSystemLogs")
            .RequireCapability(AppCapabilities.AnalyticsAdmin);

        // PBAC Slice Admin-1: Roles & Capability Management
        group.MapGet("/roles", Roles.GetRoles.HandleAsync)
            .WithName("GetRoles")
            .RequireCapability(AppCapabilities.AdminManageRoles);

        group.MapGet("/capabilities/catalog", Roles.GetCapabilityCatalog.HandleAsync)
            .WithName("GetCapabilityCatalog");
        // No extra capability gate — any authenticated admin may read the catalog.

        group.MapPost("/roles/{role}/capabilities/{capability}", Roles.GrantCapability.HandleAsync)
            .WithName("GrantCapability")
            .RequireCapability(AppCapabilities.AdminManageRoles);

        group.MapDelete("/roles/{role}/capabilities/{capability}", Roles.RevokeCapability.HandleAsync)
            .WithName("RevokeCapability")
            .RequireCapability(AppCapabilities.AdminManageRoles);
    }
}
