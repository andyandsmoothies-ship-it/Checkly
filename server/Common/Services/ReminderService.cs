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
            catch (OperationCanceledException)
            {
                // Expected on shutdown
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ReminderService tick failed");
            }

            try 
            {
                await Task.Delay(Interval, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }
    }

    /// <summary>
    /// S6: Send notifications for open APs with deadline approaching.
    /// Reads action_plan_reminder_days from template config (default: 2 days / 48h).
    /// </summary>
    private async Task SendDeadlineReminders(AppDbContext db, CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;

        // Load open APs that have a future deadline, joined to their submission's template config
        var openAPs = await db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.Status == "open"
                && ap.Deadline.HasValue
                && ap.Deadline.Value > now)
            .Join(db.Submissions.AsNoTracking(),
                ap => ap.SubmissionId,
                s => s.Id,
                (ap, s) => new { AP = ap, s.TemplateId })
            .Join(db.Templates.AsNoTracking(),
                x => x.TemplateId,
                t => t.Id,
                (x, t) => new { x.AP, t.ScoringLogicConfig })
            .ToListAsync(ct);

        var count = 0;
        foreach (var item in openAPs)
        {
            var ap = item.AP;
            if (ap.StoreManagerId == null) continue;

            // F3: Parse configurable reminder window (default: 2 days = 48h)
            var reminderDays = 2;
            if (!string.IsNullOrEmpty(item.ScoringLogicConfig))
            {
                try
                {
                    var configDoc = System.Text.Json.JsonDocument.Parse(item.ScoringLogicConfig);
                    if (configDoc.RootElement.TryGetProperty("features", out var features)
                        && features.TryGetProperty("action_plan_reminder_days", out var daysElem)
                        && daysElem.TryGetInt32(out var parsedDays))
                    {
                        reminderDays = Math.Clamp(parsedDays, 1, 30);
                    }
                }
                catch { /* malformed config → default to 2 days */ }
            }

            var cutoff = now.AddDays(reminderDays);
            if (ap.Deadline!.Value > cutoff) continue;

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
                Message = $"AP for \"{ap.CriteriaLabel}\" at {ap.StoreName} is due within {reminderDays} day(s).",
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

