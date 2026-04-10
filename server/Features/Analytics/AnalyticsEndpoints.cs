using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.Analytics;

public static class AnalyticsEndpoints
{
    public static void MapAnalyticsEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/analytics")
            .WithTags("Analytics")
            .RequireAuthorization();

        // Specific routes BEFORE catch-all (Gotcha #3)
        group.MapGet("/area-leaderboard", GetAreaLeaderboard.HandleAsync)
            .WithName("GetAreaLeaderboard")
            .RequireCapability(AppCapabilities.AnalyticsArea);

        group.MapGet("/my-stats", GetMyStats.HandleAsync)
            .WithName("GetMyStats");

        group.MapGet("/top-failures", GetTopFailures.HandleAsync)
            .WithName("GetTopFailures")
            .RequireCapability(AppCapabilities.AnalyticsAdmin);

        group.MapGet("/", GetAnalytics.HandleAsync)
            .WithName("GetAnalytics");
    }
}
