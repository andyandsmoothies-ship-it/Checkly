using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Notifications;

/// <summary>
/// GET /api/notifications?since={ISO} — returns notifications for the current user.
/// Optional: ?since= filter for delta sync.
/// </summary>
public static class ListNotifications
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        DateTimeOffset? since,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var query = db.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId);

        if (since.HasValue)
            query = query.Where(n => n.CreatedAt > since.Value);

        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Take(100)
            .Select(n => new NotificationDto(
                n.Id, n.UserId, n.Type, n.Title, n.Message,
                n.ReadAt, n.ActionUrl, n.Metadata, n.CreatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(notifications);
    }
}
