using Microsoft.AspNetCore.Authorization;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// Extension methods for clean RequireCapability(...) usage on Minimal API route builders.
/// Example: group.MapPost("/", Handler).RequireCapability("templates:create");
/// </summary>
public static class CapabilityExtensions
{
    /// <summary>
    /// Requires the calling user's role to possess the specified capability string
    /// in the PbacDictionaryCache. Builds an inline authorization policy
    /// backed by CapabilityAuthorizationHandler.
    /// </summary>
    public static TBuilder RequireCapability<TBuilder>(
        this TBuilder builder, string capability)
        where TBuilder : IEndpointConventionBuilder
        => builder.RequireAuthorization(policy =>
            policy.AddRequirements(new CapabilityRequirement(capability)));
}
