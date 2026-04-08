namespace Checkly.Api.Features.SystemInfo;

/// <summary>
/// Maps infrastructure/system-level endpoints under /api/system.
/// </summary>
public static class SystemEndpoints
{
    public static void MapSystemEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/system")
            .WithTags("System")
            .RequireAuthorization();

        group.MapGet("/capabilities", GetCapabilities.HandleAsync)
            .WithName("GetCapabilities");
    }
}
