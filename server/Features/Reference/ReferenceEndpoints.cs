namespace Checkly.Api.Features.Reference;

/// <summary>
/// Route registration for the Reference feature slice.
/// </summary>
public static class ReferenceEndpoints
{
    public static void MapReferenceEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/reference")
            .RequireAuthorization();

        group.MapGet("/locations", GetLocations.HandleAsync);
        group.MapGet("/districts", GetDistricts.HandleAsync);
    }
}
