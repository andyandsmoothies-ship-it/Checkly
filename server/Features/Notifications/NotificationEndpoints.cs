namespace Checkly.Api.Features.Notifications;

/// <summary>
/// Maps notification endpoints and SignalR hub.
/// </summary>
public static class NotificationEndpoints
{
    public static void MapNotificationEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/notifications")
            .WithTags("Notifications")
            .RequireAuthorization();

        group.MapGet("/", ListNotifications.HandleAsync)
            .WithName("ListNotifications");

        group.MapPost("/{id}/read", MarkRead.HandleAsync)
            .WithName("MarkNotificationRead");

        // OBS-1: Implement the missing mark-all-read endpoint.
        // Flutter client calls POST /notifications/read-all. Without this, markAllRead() returns
        // a 404 that is silently swallowed by the catch(_) in notification_manager.dart:133.
        group.MapPost("/read-all", MarkAllRead.HandleAsync)
            .WithName("MarkAllNotificationsRead");

        // SignalR hub
        app.MapHub<NotificationHub>("/hub/notifications");
    }
}
