using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Checkly.Api.Features.Notifications;

/// <summary>
/// POST /api/notifications/read-all — marks all unread notifications as read for the calling user.
/// OBS-1: Flutter client calls this endpoint. Without it, unread counts diverge silently between
/// server and client on every 'mark all read' action.
/// </summary>
public static class MarkAllRead
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        await db.Notifications
            .Where(n => n.UserId == callerId && n.ReadAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.ReadAt, DateTimeOffset.UtcNow), ct);

        return TypedResults.NoContent();
    }
}
