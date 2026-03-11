using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Notifications;

/// <summary>
/// POST /api/notifications/{id}/read — marks a notification as read.
/// </summary>
public static class MarkRead
{
    public static async Task<IResult> HandleAsync(Guid id, AppDbContext db, CancellationToken ct)
    {
        var notification = await db.Notifications.FindAsync(id);
        if (notification is null)
            return TypedResults.NotFound();

        notification.ReadAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        return TypedResults.NoContent();
    }
}
