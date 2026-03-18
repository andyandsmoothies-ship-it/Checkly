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
            .RequireAuthorization("AreaManagerAccess");

        group.MapGet("/my-stats", GetMyStats.HandleAsync)
            .WithName("GetMyStats");

        group.MapGet("/top-failures", GetTopFailures.HandleAsync)
            .WithName("GetTopFailures")
            .RequireAuthorization("AdminOnly");

        group.MapGet("/", GetAnalytics.HandleAsync)
            .WithName("GetAnalytics");
    }
}
