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
    private readonly DistributedLockManager _lockManager;
    private readonly ILogger<ReminderService> _logger;
    private static readonly TimeSpan Interval = TimeSpan.FromHours(12);
    private static readonly TimeSpan RetentionPeriod = TimeSpan.FromDays(90);
    private static readonly TimeSpan TickTimeout = TimeSpan.FromMinutes(5);
    private DateTimeOffset _lastCleanupAt = DateTimeOffset.MinValue;

    public ReminderService(
        IServiceScopeFactory scopeFactory,
        DistributedLockManager lockManager,
        ILogger<ReminderService> logger)
    {
        _scopeFactory = scopeFactory;
        _lockManager = lockManager;
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

                // Tick-level timeout: if the job exceeds 5 minutes, cancel this tick
                // and wait for the next 12-hour window. Uses a linked token so pod
                // shutdown (stoppingToken) still cancels immediately.
                using var tickCts = new CancellationTokenSource(TickTimeout);
                using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken, tickCts.Token);
                var tickToken = linkedCts.Token;

                // Acquire the distributed lock. Only ONE pod across the cluster will proceed.
                // Other pods receive null and skip this tick gracefully.
                await using var systemLock = await _lockManager.TryAcquireAsync(db, "Checkly.ReminderService", tickToken);
                if (systemLock is null)
                {
                    _logger.LogDebug("JobSkipped: Tick skipped for {Service}", nameof(ReminderService));
                    // Fall through to Task.Delay — wait for next tick.
                }
                else
                {
                    _logger.LogInformation("ReminderService: Distributed lock acquired for tick.");

                    await SendDeadlineReminders(db, tickToken);
                    await SendScheduleReminders(db, tickToken);

                    // Only run retention cleanup once per 24 hours
                    if (DateTimeOffset.UtcNow - _lastCleanupAt >= TimeSpan.FromHours(24))
                    {
                        await RunRetentionCleanup(db, tickToken);
                        _lastCleanupAt = DateTimeOffset.UtcNow;
                    }
                    // await using disposes here → AcquiredLock.CommitAsync() called → lock released
                }
            }
            catch (OperationCanceledException) when (!stoppingToken.IsCancellationRequested)
            {
                // Tick-level timeout fired (5-minute TickTimeout CTS).
                // This is NOT a pod shutdown — log as a warning and continue to the next cycle.
                _logger.LogWarning("ReminderService tick timed out after {Timeout}. Waiting for next interval.", TickTimeout);
            }
            catch (OperationCanceledException)
            {
                // stoppingToken cancelled — normal pod shutdown.
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ReminderService tick failed");
            }

            try
            {
                await Task.Delay(Interval, stoppingToken); // Always raw stoppingToken (not tickToken)
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
    internal async Task SendDeadlineReminders(AppDbContext db, CancellationToken ct)
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
            .GroupJoin(
                db.Notifications.AsNoTracking().Where(n => n.Type == "ap_deadline_reminder"),
                // The ActionUrl in notifications is formatted as "/action-plans/{id}".
                // EF Core 8+ translates this string concatenation correctly in the LEFT JOIN.
                x => "/action-plans/" + x.AP.Id.ToString(),
                n => n.ActionUrl,
                (x, notifs) => new { x.AP, x.ScoringLogicConfig, Notifs = notifs })
            .SelectMany(
                x => x.Notifs.DefaultIfEmpty(),
                (x, n) => new { x.AP, x.ScoringLogicConfig, Notification = n })
            .Where(x => x.Notification == null)
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

            // Idempotency: the db-side LEFT JOIN has already filtered out APs that have a notification.
            var apUrl = $"/action-plans/{ap.Id}";

            db.Notifications.Add(new Notification
            {
                Id = Guid.NewGuid(),
                UserId = ap.StoreManagerId.Value,
                Type = "ap_deadline_reminder",
                Title = "Action Plan Deadline Approaching",
                Message = $"AP for \"{ap.CriteriaLabel}\" at {ap.StoreName} is due within {reminderDays} day(s).",
                ActionUrl = apUrl,
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
    /// Hard-deletes notifications and system logs older than 90 days.
    /// Uses ExecuteDeleteAsync for a single SQL DELETE with zero object allocation.
    /// The 24h throttle guard lives in ExecuteAsync — this method always performs
    /// cleanup when called directly (e.g. in tests).
    /// </summary>
    /// <remarks>internal for testability — do not call directly from outside ReminderService.</remarks>
    internal async Task RunRetentionCleanup(AppDbContext db, CancellationToken ct)
    {
        var cutoff = DateTimeOffset.UtcNow - RetentionPeriod;

        // Single SQL: DELETE FROM notifications WHERE created_at < @cutoff
        var deletedNotifications = await db.Notifications
            .Where(n => n.CreatedAt < cutoff)
            .ExecuteDeleteAsync(ct);
        if (deletedNotifications > 0)
            _logger.LogInformation("Retention: purged {Count} notifications older than 90 days", deletedNotifications);

        // Single SQL: DELETE FROM system_logs WHERE created_at < @cutoff
        var deletedLogs = await db.SystemLogs
            .Where(l => l.CreatedAt < cutoff)
            .ExecuteDeleteAsync(ct);
        if (deletedLogs > 0)
            _logger.LogInformation("Retention: purged {Count} system logs older than 90 days", deletedLogs);
    }
}

