using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Services;

/// <summary>
/// Static helper for writing audit log entries to system_logs.
/// Uses Category = "audit" to distinguish from admin/system logs.
/// Participates in the caller's SaveChangesAsync transaction.
/// </summary>
public static class AuditLogger
{
    public static void Log(
        AppDbContext db, ClaimsPrincipal user,
        string action, string entityType, Guid entityId,
        string? message = null, string? path = null)
    {
        _ = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var uid);

        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = uid == Guid.Empty ? null : uid,
            Action = action,
            Category = "audit",
            EntityType = entityType,
            EntityId = entityId,
            Message = message,
            Path = path,
            Level = "info",
            CreatedAt = DateTimeOffset.UtcNow
        });
    }
}
