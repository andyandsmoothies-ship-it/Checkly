namespace Checkly.Api.Features.Admin;

/// <summary>
/// Maps the /api/admin route group (requires authentication + admin role).
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
            .WithName("ListUsers");

        group.MapPut("/users/{id}", UpdateUser.HandleAsync)
            .WithName("UpdateUser");

        group.MapPost("/users/{id}/ban", BanUser.HandleAsync)
            .WithName("BanUser");

        // S8: SM Transfer
        group.MapPost("/stores/{storeId}/transfer", TransferStoreManager.HandleAsync)
            .WithName("TransferStoreManager");

        // S12: System Logs
        group.MapGet("/logs", ListSystemLogs.HandleAsync)
            .WithName("ListSystemLogs");
    }
}
