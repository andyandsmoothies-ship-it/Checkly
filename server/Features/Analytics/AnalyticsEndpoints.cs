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
            .WithName("GetMyStats")
            .RequireCapability(AppCapabilities.AnalyticsMyStats);

        group.MapGet("/top-failures", GetTopFailures.HandleAsync)
            .WithName("GetTopFailures")
            .RequireCapability(AppCapabilities.AnalyticsAdmin);

        group.MapGet("/", GetAnalytics.HandleAsync)
            .WithName("GetAnalytics")
            .RequireCapability(AppCapabilities.AnalyticsView);

        group.MapGet("/bod", GetBodReport.HandleAsync)
            .WithName("GetBodReport")
            .RequireCapability(AppCapabilities.AnalyticsBod);

        group.MapGet("/bod/area", GetAreaBodReport.HandleAsync)
            .WithName("GetAreaBodReport")
            .RequireCapability(AppCapabilities.AnalyticsArea);

        group.MapGet("/bod/ap/{bucket}", GetApBucketDetail.HandleAsync)
            .WithName("GetApBucketDetail")
            .RequireCapability(AppCapabilities.AnalyticsBod);

        group.MapGet("/auditors/productivity", GetAuditorProductivity.HandleAsync)
            .WithName("GetAuditorProductivity")
            .RequireCapability(AppCapabilities.AnalyticsBod);


        group.MapGet("/stores/{storeId:guid}/bod-summary", GetStoreBodSummary.HandleAsync)
            .WithName("GetStoreBodSummary");

        group.MapGet("/bod/category/{name}", GetCategoryDetail.HandleAsync)
            .WithName("GetCategoryDetail")
            .RequireCapability(AppCapabilities.AnalyticsBod);
    }
}
