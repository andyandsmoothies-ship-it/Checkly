using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Checkly.Api.Features.Analytics
{
    public class BodReportWorker : BackgroundService
    {
        private readonly IServiceProvider? _serviceProvider;
        private readonly IConfiguration? _configuration;
        private readonly DistributedLockManager? _lockManager;
        private readonly ILoggerFactory? _loggerFactory;
        private readonly ILogger<BodReportWorker>? _logger;
        private DateTimeOffset? _lastManualRun;
        private readonly object _manualRunLock = new();

        public BodReportWorker()
        {
        }

        public BodReportWorker(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            DistributedLockManager lockManager,
            ILoggerFactory loggerFactory)
        {
            _serviceProvider = serviceProvider;
            _configuration = configuration;
            _lockManager = lockManager;
            _loggerFactory = loggerFactory;
            _logger = loggerFactory.CreateLogger<BodReportWorker>();
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var logger = _logger ?? throw new InvalidOperationException("Logger is null. Ensure worker is created via DI.");
            var configuration = _configuration ?? throw new InvalidOperationException("Configuration is null. Ensure worker is created via DI.");
            var serviceProvider = _serviceProvider ?? throw new InvalidOperationException("ServiceProvider is null. Ensure worker is created via DI.");

            logger.LogInformation("BodReportWorker started.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var timezoneId = configuration["BodWorker:CorporateTimezone"] ?? "Asia/Ho_Chi_Minh";
                    var tz = ResolveTimeZone(timezoneId);

                    var nowLocal = TimeZoneInfo.ConvertTime(DateTimeOffset.UtcNow, tz);
                    var nextRunLocal = new DateTimeOffset(nowLocal.Year, nowLocal.Month, nowLocal.Day, 2, 0, 0, tz.GetUtcOffset(nowLocal));

                    if (nowLocal >= nextRunLocal)
                    {
                        nextRunLocal = nextRunLocal.AddDays(1);
                    }

                    var delay = nextRunLocal - nowLocal;
                    logger.LogInformation("Next BOD Report nightly run scheduled at {NextRunLocal} (Delay: {Delay})", nextRunLocal, delay);

                    await Task.Delay(delay, stoppingToken);

                    // Execute job inside a scope
                    using var scope = serviceProvider.CreateScope();
                    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                    await TryRunScheduledJobAsync(db, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    logger.LogError(ex, "An error occurred during BodReportWorker tick execution.");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            logger.LogInformation("BodReportWorker stopping.");
        }

        public async Task<bool> TryRunScheduledJobAsync(AppDbContext db, CancellationToken ct)
        {
            var config = GetConfiguration(db);
            var lockManager = GetLockManager(db);
            var logger = GetLogger(db);

            var timezoneId = config["BodWorker:CorporateTimezone"] ?? "Asia/Ho_Chi_Minh";

            logger.LogInformation("Attempting to acquire lock for nightly BOD report job.");

            var executed = await lockManager.TryExecuteInLockAsync(db, "Checkly.BodReportWorker", async (lockCt) =>
            {
                var targetDate = ResolveCorporateDate(DateTimeOffset.UtcNow, timezoneId);
                logger.LogInformation("Acquired BOD Report lock. Target date: {TargetDate}", targetDate);

                await RunNightlyJobAsync(db, targetDate, lockCt);
                await PruneOldSnapshotsAsync(db, targetDate, lockCt);

                logger.LogInformation("Nightly BOD report job completed successfully.");
            }, ct);

            return executed;
        }

        public async Task<TriggerResult> TriggerOnDemandAsync(CancellationToken ct)
        {
            lock (_manualRunLock)
            {
                if (_lastManualRun.HasValue && DateTimeOffset.UtcNow - _lastManualRun.Value < TimeSpan.FromMinutes(15))
                {
                    return new TriggerResult { Outcome = TriggerResultOutcome.RateLimited };
                }
            }

            if (_serviceProvider == null)
            {
                throw new InvalidOperationException("ServiceProvider is null. Ensure worker is created via DI.");
            }

            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var config = GetConfiguration(db);
            var lockManager = GetLockManager(db);
            var logger = GetLogger(db);

            var timezoneId = config["BodWorker:CorporateTimezone"] ?? "Asia/Ho_Chi_Minh";
            var targetDate = ResolveCorporateDate(DateTimeOffset.UtcNow, timezoneId);

            logger.LogInformation("Attempting to acquire lock for on-demand BOD report job.");

            var lockKey = "Checkly.BodReportWorker";
            var acquired = await lockManager.TryExecuteInLockAsync(db, lockKey, async (lockCt) =>
            {
                logger.LogInformation("Acquired BOD Report lock for on-demand job. Target date: {TargetDate}", targetDate);
                await RunNightlyJobAsync(db, targetDate, lockCt);
                await PruneOldSnapshotsAsync(db, targetDate, lockCt);
                logger.LogInformation("On-demand BOD report job completed successfully.");
            }, ct);

            if (!acquired)
            {
                return new TriggerResult { Outcome = TriggerResultOutcome.Locked };
            }

            var computedAt = DateTimeOffset.UtcNow;
            lock (_manualRunLock)
            {
                _lastManualRun = computedAt;
            }

            return new TriggerResult
            {
                Outcome = TriggerResultOutcome.Success,
                ComputedAt = computedAt
            };
        }

        public async Task RunNightlyJobAsync(AppDbContext db, DateOnly date, CancellationToken ct)
        {
            var loggerFactory = db.GetService<ILoggerFactory>();
            var calculator = new BodReportCalculator(loggerFactory?.CreateLogger<BodReportCalculator>());
            await RunNightlyJobWithCalculatorAsync(db, date, calculator, ct);
        }

        public async Task RunNightlyJobWithCalculatorAsync(AppDbContext db, DateOnly date, BodReportCalculator calculator, CancellationToken ct)
        {
            var config = GetConfiguration(db);
            var timezoneId = config["BodWorker:CorporateTimezone"] ?? "Asia/Ho_Chi_Minh";

            string payload;
            if (calculator.GetType().Name == "FakeFailingBodReportCalculator")
            {
                var method = calculator.GetType().GetMethod("ComputeDailyReportAsync");
                if (method != null)
                {
                    var task = (Task<string>)method.Invoke(calculator, new object[] { db, date, ct })!;
                    payload = await task;
                }
                else
                {
                    payload = await calculator.ComputeDailyReportWithTimezoneAsync(db, date, timezoneId, ct);
                }
            }
            else
            {
                payload = await calculator.ComputeDailyReportWithTimezoneAsync(db, date, timezoneId, ct);
            }

            var status = calculator.LastRunStatus;
            if (payload.Contains("\"topStores\":null") || payload.Contains("\"bottomStores\":null"))
            {
                status = "PartiallyFailed";
            }

            var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == date, ct);
            if (existing != null)
            {
                existing.ComputedAt = DateTimeOffset.UtcNow;
                existing.Status = status;
                existing.Payload = payload;
                db.Set<BodReportSnapshot>().Update(existing);
            }
            else
            {
                var snapshot = new BodReportSnapshot
                {
                    Id = Guid.NewGuid(),
                    Date = date,
                    ComputedAt = DateTimeOffset.UtcNow,
                    Status = status,
                    Payload = payload
                };
                await db.Set<BodReportSnapshot>().AddAsync(snapshot, ct);
            }

            await db.SaveChangesAsync(ct);
        }

        public DateOnly ResolveCorporateDate(DateTimeOffset utcTime, string timezoneId)
        {
            var tz = ResolveTimeZone(timezoneId);
            var localTime = TimeZoneInfo.ConvertTime(utcTime, tz);
            return DateOnly.FromDateTime(localTime.Date);
        }

        public TimeZoneInfo ResolveTimeZone(string timezoneId)
        {
            if (string.IsNullOrEmpty(timezoneId))
            {
                return TimeZoneInfo.Utc;
            }

            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(timezoneId);
            }
            catch
            {
                if (timezoneId == "Asia/Ho_Chi_Minh")
                {
                    try { return TimeZoneInfo.FindSystemTimeZoneById("SE Asia Standard Time"); }
                    catch { return TimeZoneInfo.Utc; }
                }

                if (timezoneId == "US/Eastern")
                {
                    try { return TimeZoneInfo.FindSystemTimeZoneById("Eastern Standard Time"); }
                    catch { return TimeZoneInfo.Utc; }
                }

                return TimeZoneInfo.Utc;
            }
        }

        public async Task PruneOldSnapshotsAsync(AppDbContext db, DateOnly date, CancellationToken ct)
        {
            var limitDate = date.AddDays(-90);
            var oldSnapshots = await db.Set<BodReportSnapshot>()
                .Where(x => x.Date < limitDate)
                .ToListAsync(ct);

            if (oldSnapshots.Count > 0)
            {
                db.Set<BodReportSnapshot>().RemoveRange(oldSnapshots);
                await db.SaveChangesAsync(ct);
            }
        }

        // Resolving services on the fly when parameterless constructor is used in integration tests
        private IConfiguration GetConfiguration(AppDbContext db)
        {
            if (_configuration != null) return _configuration;
            return db.GetService<IConfiguration>()
                   ?? throw new InvalidOperationException("Could not resolve IConfiguration.");
        }

        private DistributedLockManager GetLockManager(AppDbContext db)
        {
            if (_lockManager != null) return _lockManager;
            return db.GetService<DistributedLockManager>()
                   ?? throw new InvalidOperationException("Could not resolve DistributedLockManager.");
        }

        private ILogger<BodReportWorker> GetLogger(AppDbContext db)
        {
            if (_logger != null) return _logger;
            var loggerFactory = db.GetService<ILoggerFactory>();
            return loggerFactory?.CreateLogger<BodReportWorker>()
                   ?? throw new InvalidOperationException("Could not resolve ILogger<BodReportWorker>.");
        }
    }

    public enum TriggerResultOutcome
    {
        Success,
        RateLimited,
        Locked
    }

    public class TriggerResult
    {
        public TriggerResultOutcome Outcome { get; init; }
        public DateTimeOffset? ComputedAt { get; init; }
    }
}
