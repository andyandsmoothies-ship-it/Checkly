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

        // SignalR hub
        app.MapHub<NotificationHub>("/hub/notifications");
    }
}
