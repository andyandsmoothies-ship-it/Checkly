using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// A named requirement carrying the capability string to check.
/// Example: new CapabilityRequirement("templates:create")
/// </summary>
public sealed record CapabilityRequirement(string Capability) : IAuthorizationRequirement;

/// <summary>
/// Resolves CapabilityRequirement by reading the caller's role from ClaimTypes.Role
/// and checking if PbacDictionaryCache contains the required capability.
/// Fail-safe: if cache is not ready (cold start), denies the request.
/// </summary>
public sealed class CapabilityAuthorizationHandler(PbacDictionaryCache cache)
    : AuthorizationHandler<CapabilityRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        CapabilityRequirement requirement)
    {
        // Fail-safe: deny ALL requests if cache has not been initialized yet.
        if (!cache.IsReady)
            return Task.CompletedTask;

        var role = context.User.FindFirstValue(ClaimTypes.Role);
        if (role is null)
            return Task.CompletedTask;

        var capabilities = cache.GetCapabilities(role);
        if (capabilities.Contains(requirement.Capability))
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}
