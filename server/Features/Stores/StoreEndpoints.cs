namespace Checkly.Api.Features.Stores;

/// <summary>
/// Maps the /api/stores route group (requires authentication).
/// </summary>
public static class StoreEndpoints
{
    public static void MapStoreEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/stores")
            .WithTags("Stores")
            .RequireAuthorization();

        group.MapGet("/", ListStores.HandleAsync)
            .WithName("ListStores");

        group.MapGet("/{id:guid}/dashboard", GetStoreDashboard.HandleAsync)
            .WithName("GetStoreDashboard");

        group.MapPost("/", CreateStore.HandleAsync)
            .WithName("CreateStore")
            .RequireAuthorization("AdminOnly");

        group.MapPut("/{id:guid}", UpdateStore.HandleAsync)
            .WithName("UpdateStore")
            .RequireAuthorization("AdminOnly");

        group.MapDelete("/{id:guid}", DeleteStore.HandleAsync)
            .WithName("DeleteStore")
            .RequireAuthorization("AdminOnly");
    }
}
