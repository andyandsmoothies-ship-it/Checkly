using System.Security.Claims;
using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.SystemInfo;

/// <summary>
/// GET /api/system/capabilities
/// Returns the capability set for the calling user's role from PbacDictionaryCache.
/// Auth: RequireAuthorization() — any authenticated user.
/// Response shape: { role: string, capabilities: string[] }
/// </summary>
public static class GetCapabilities
{
    public static IResult HandleAsync(
        ClaimsPrincipal user,
        PbacDictionaryCache cache)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
        var capabilities = cache.GetCapabilities(role);

        return TypedResults.Ok(new CapabilitiesResponse(role, [.. capabilities]));
    }

    public sealed record CapabilitiesResponse(string Role, string[] Capabilities);
}
