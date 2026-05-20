using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Checkly.Api.Features.Notifications;

/// <summary>
/// POST /api/notifications/{id}/read — marks a notification as read.
/// SECURITY: The notification must belong to the calling user.
/// Returns 404 (not 403) for both missing and unauthorized notifications (OWASP IDOR pattern).
/// </summary>
public static class MarkRead
{
    private static readonly string _logCategory =
        typeof(MarkRead).FullName ?? nameof(MarkRead);

    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        ILoggerFactory loggerFactory,
        CancellationToken ct)
    {
        var logger = loggerFactory.CreateLogger(_logCategory);
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // F4 Fix: Combined ownership + existence filter.
        // Returns null for both "not found" and "wrong user" — caller cannot distinguish.
        var notification = await db.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == callerId, ct);

        if (notification is null)
        {
            logger.LogWarning(
                "MarkRead: notification {NotificationId} not found or not owned by caller {CallerId}",
                id, callerId);
            return TypedResults.NotFound();
        }

        notification.ReadAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation(
            "MarkRead: notification {NotificationId} marked read by {CallerId}",
            id, callerId);

        return TypedResults.NoContent();
    }
}
