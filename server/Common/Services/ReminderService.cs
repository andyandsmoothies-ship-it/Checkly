using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Services;

/// <summary>
/// S6+S7: Background service that sends deadline and schedule reminders.
/// Also handles daily retention cleanup for notifications and system logs.
/// Runs every 12 hours. Uses IServiceScopeFactory to safely access scoped DbContext.
/// </summary>
public sealed class ReminderService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReminderService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromHours(12);
    private static readonly TimeSpan RetentionPeriod = TimeSpan.FromDays(90);
    private DateTimeOffset _lastCleanupAt = DateTimeOffset.MinValue;

    public ReminderService(IServiceScopeFactory scopeFactory, ILogger<ReminderService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("ReminderService started — interval: {Interval}", Interval);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                await SendDeadlineReminders(db, stoppingToken);
                await SendScheduleReminders(db, stoppingToken);
                await RunRetentionCleanup(db, stoppingToken);
            }
            catch (Exception ex) when (ex is not OperationCanceledException)
            {
                _logger.LogError(ex, "ReminderService tick failed");
            }

            await Task.Delay(Interval, stoppingToken);
        }
    }

    /// <summary>
    /// S6: Send notifications for open APs with deadline within 48 hours.
    /// </summary>
    private async Task SendDeadlineReminders(AppDbContext db, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var cutoff = now.AddHours(48);

        var dueSoonAPs = await db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.Status == "open"
                && ap.Deadline.HasValue
                && ap.Deadline.Value <= cutoff
                && ap.Deadline.Value > now)
            .ToListAsync(ct);

        var count = 0;
        foreach (var ap in dueSoonAPs)
        {
            if (ap.StoreManagerId == null) continue;

            // Idempotency: skip if notification already sent for this AP deadline
            var alreadySent = await db.Notifications
                .AnyAsync(n => n.UserId == ap.StoreManagerId
                    && n.ActionUrl != null && n.ActionUrl.Contains(ap.Id.ToString())
                    && n.Type == "ap_deadline_reminder", ct);
            if (alreadySent) continue;

            db.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = ap.StoreManagerId.Value,
                Type = "ap_deadline_reminder",
                Title = "Action Plan Deadline Approaching",
                Message = $"AP for \"{ap.CriteriaLabel}\" at {ap.StoreName} is due within 48 hours.",
                ActionUrl = $"/action-plans/{ap.Id}",
                ReadAt = null,
                CreatedAt = now,
            });
            count++;
        }

        if (count > 0)
        {
            await db.SaveChangesAsync(ct);
            _logger.LogInformation("S6: Sent {Count} deadline reminders", count);
        }
    }

    /// <summary>
    /// S7: Placeholder for scheduled audit reminders.
    /// Actual scheduled audits feature requires a ScheduledAudit entity — deferred.
    /// </summary>
    private Task SendScheduleReminders(AppDbContext db, CancellationToken ct)
    {
        _logger.LogDebug("S7: Schedule reminders — no scheduled audits entity yet");
        return Task.CompletedTask;
    }

    /// <summary>
    /// Retention cleanup: hard-deletes notifications and system logs older than 90 days.
    /// Runs once per day (tracked by _lastCleanupAt).
    /// </summary>
    private async Task RunRetentionCleanup(AppDbContext db, CancellationToken ct)
    {
        // Only run once per day
        if (DateTimeOffset.UtcNow - _lastCleanupAt < TimeSpan.FromHours(24))
            return;

        var cutoff = DateTimeOffset.UtcNow - RetentionPeriod;

        // Hard-delete old notifications
        var oldNotifications = await db.Notifications
            .Where(n => n.CreatedAt < cutoff)
            .ToListAsync(ct);
        if (oldNotifications.Count > 0)
        {
            db.Notifications.RemoveRange(oldNotifications);
            _logger.LogInformation("Retention: purged {Count} notifications older than 90 days", oldNotifications.Count);
        }

        // Hard-delete old system logs
        var oldLogs = await db.SystemLogs
            .Where(l => l.CreatedAt < cutoff)
            .ToListAsync(ct);
        if (oldLogs.Count > 0)
        {
            db.SystemLogs.RemoveRange(oldLogs);
            _logger.LogInformation("Retention: purged {Count} system logs older than 90 days", oldLogs.Count);
        }

        if (oldNotifications.Count > 0 || oldLogs.Count > 0)
            await db.SaveChangesAsync(ct);

        _lastCleanupAt = DateTimeOffset.UtcNow;
    }
}

