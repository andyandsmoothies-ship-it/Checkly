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
    }
}
