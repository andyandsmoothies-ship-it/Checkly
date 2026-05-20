using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.Analytics;

public static class AnalyticsEndpoints
{
    public static void MapAnalyticsEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/analytics")
            .WithTags("Analytics")
            .RequireAuthorization();

        group.MapGet("/my-stats", GetMyStats.HandleAsync)
            .WithName("GetMyStats");

        group.MapGet("/top-failures", GetTopFailures.HandleAsync)
            .WithName("GetTopFailures")
            .RequireCapability(AppCapabilities.AnalyticsAdmin);

        group.MapGet("/", GetAnalytics.HandleAsync)
            .WithName("GetAnalytics")
            .RequireCapability(AppCapabilities.AnalyticsView);
    }
}
