using Checkly.Api.Common.Auth;

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

        // IMPORTANT: /{id:guid} must be BEFORE /{id:guid}/dashboard (Gotcha #3 — specific before catch-all)
        group.MapGet("/{id:guid}", GetStore.HandleAsync)
            .WithName("GetStore");

        group.MapGet("/{id:guid}/dashboard", GetStoreDashboard.HandleAsync)
            .WithName("GetStoreDashboard");

        group.MapPost("/", CreateStore.HandleAsync)
            .WithName("CreateStore")
            .RequireCapability(AppCapabilities.StoresWrite);

        group.MapPut("/{id:guid}", UpdateStore.HandleAsync)
            .WithName("UpdateStore")
            .RequireCapability(AppCapabilities.StoresWrite);

        group.MapDelete("/{id:guid}", DeleteStore.HandleAsync)
            .WithName("DeleteStore")
            .RequireCapability(AppCapabilities.StoresWrite);
    }
}
