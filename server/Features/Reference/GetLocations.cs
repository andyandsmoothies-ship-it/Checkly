using Checkly.Api.Common.Reference;

namespace Checkly.Api.Features.Reference;

/// <summary>
/// GET /api/reference/locations — returns the list of 63 Vietnamese provinces.
/// Any authenticated user can call this. No specific capability required (reference data).
/// Source: VietnamLocations.Provinces (in-memory static — no DB query).
/// </summary>
public static class GetLocations
{
    public static IResult HandleAsync()
    {
        return Results.Ok(VietnamLocations.Provinces);
    }
}
