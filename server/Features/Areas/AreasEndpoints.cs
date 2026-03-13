namespace Checkly.Api.Features.Areas;

/// <summary>
/// Route mapping for Areas feature slice.
/// </summary>
public static class AreasEndpoints
{
    public static void MapAreaEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/areas")
            .RequireAuthorization();

        group.MapGet("/", ListAreas.HandleAsync);
        group.MapGet("/{id:guid}", GetArea.HandleAsync);
        group.MapPost("/", CreateArea.HandleAsync);
        group.MapPut("/{id:guid}", UpdateArea.HandleAsync);
    }
}
