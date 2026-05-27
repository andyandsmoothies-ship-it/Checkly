using System.Reflection;
using System.Text.Json;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Analytics;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Checkly.Api.Tests.Features.Analytics
{
    [Collection("Sequential")]
    public class BodReportWorkerTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodReportWorkerTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public void AppCapabilities_Has_AnalyticsBod_Constant_Reflected()
        {
            // [TC-SL1-06] Assert reflection to prove static constant is defined and matches specification
            var field = typeof(AppCapabilities).GetField("AnalyticsBod", BindingFlags.Public | BindingFlags.Static | BindingFlags.FlattenHierarchy);
            Assert.NotNull(field);
            Assert.Equal("analytics:bod", field.GetValue(null));
        }

        [Fact]
        public async Task Capability_AnalyticsBod_IsSeededForAdmin()
        {
            // [TC-SL1-06] Assert capability is seeded in database and mapped to Admin
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var count = await db.Database
                .SqlQuery<int>($"SELECT COUNT(*)::int AS \"Value\" FROM role_capabilities WHERE role = 'admin' AND capability = 'analytics:bod'")
                .SingleAsync();

            Assert.Equal(1, count);
        }

        [Fact]
        public async Task AppDbContext_Has_BodReportSnapshots_Property_Configured()
        {
            // Assert reflection to prove DB model matches technical mapping specification
            var property = typeof(AppDbContext).GetProperty("BodReportSnapshots");
            Assert.NotNull(property);

            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Confirm query runs without syntax errors against Postgres DB
            var count = await db.Set<BodReportSnapshot>().CountAsync();
            Assert.True(count >= 0);
        }

        [Fact]
        public async Task RunNightlyJobAsync_TwiceOnSameDate_IsIdempotent()
        {
            // [TC-SL1-01] Running nightly calculation twice on same date updates the single row (Count = 1)
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var worker = new BodReportWorker();

            var targetDate = new DateOnly(2026, 5, 24);

            // Clean up any existing snapshots for this date to avoid test leakage
            var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
            if (existing != null)
            {
                db.Set<BodReportSnapshot>().Remove(existing);
                await db.SaveChangesAsync();
            }

            // Act - first run
            await worker.RunNightlyJobAsync(db, targetDate, CancellationToken.None);

            var firstSnapshot = await db.Set<BodReportSnapshot>().FirstAsync(x => x.Date == targetDate);
            Assert.NotNull(firstSnapshot);
            Assert.Equal("Complete", firstSnapshot.Status);

            var originalComputedAt = firstSnapshot.ComputedAt;

            // Short delay to ensure timestamp changes
            await Task.Delay(10);

            // Act - second run
            await worker.RunNightlyJobAsync(db, targetDate, CancellationToken.None);

            // Assert
            var allSnapshots = await db.Set<BodReportSnapshot>().Where(x => x.Date == targetDate).ToListAsync();
            Assert.Single(allSnapshots); // Still only 1 row (Idempotency)

            var updatedSnapshot = allSnapshots.First();
            Assert.True(updatedSnapshot.ComputedAt > originalComputedAt, "ComputedAt was not updated on second run.");
        }

        [Fact]
        public async Task RunNightlyJobAsync_OneQueryFails_SavesWithPartiallyFailedStatus()
        {
            // [TC-SL1-02] A query throws exception -> snapshot saved with Status = "PartiallyFailed"
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var targetDate = new DateOnly(2026, 5, 25);

            // Clean up existing
            var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
            if (existing != null)
            {
                db.Set<BodReportSnapshot>().Remove(existing);
                await db.SaveChangesAsync();
            }

            // We use a custom failing calculator / mock to trigger query failure
            // Note: Since Sentinel is SDET, we define the failing calculator in test project
            var failingCalculator = new FakeFailingBodReportCalculator();

            // Act
            var worker = new BodReportWorker();
            // Expected signature for executing with customized calculator
            await worker.RunNightlyJobWithCalculatorAsync(db, targetDate, failingCalculator, CancellationToken.None);

            // Assert
            var snapshot = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
            Assert.NotNull(snapshot);
            Assert.Equal("PartiallyFailed", snapshot.Status);

            var json = JsonSerializer.Deserialize<JsonElement>(snapshot.Payload);
            // Verify other parts of the payload are safe/empty rather than completely null
            Assert.True(json.TryGetProperty("kpis", out _));
        }

        [Fact]
        public async Task PruneOldSnapshotsAsync_PrunesSnapshotsOlderThan90Days()
        {
            // [TC-SL1-03] Snapshot with date 91 days ago is deleted when worker runs
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var worker = new BodReportWorker();

            var today = new DateOnly(2026, 5, 24);
            var oldDate = today.AddDays(-91);
            var keepDate = today.AddDays(-89);

            // Seed snapshots
            var existingOld = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == oldDate);
            if (existingOld != null)
            {
                db.Set<BodReportSnapshot>().Remove(existingOld);
            }
            var existingKeep = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == keepDate);
            if (existingKeep != null)
            {
                db.Set<BodReportSnapshot>().Remove(existingKeep);
            }
            await db.SaveChangesAsync();

            var oldSnapshot = new BodReportSnapshot { Id = Guid.NewGuid(), Date = oldDate, ComputedAt = DateTimeOffset.UtcNow, Status = "Complete", Payload = "{}" };
            var keepSnapshot = new BodReportSnapshot { Id = Guid.NewGuid(), Date = keepDate, ComputedAt = DateTimeOffset.UtcNow, Status = "Complete", Payload = "{}" };

            db.Set<BodReportSnapshot>().AddRange(oldSnapshot, keepSnapshot);
            await db.SaveChangesAsync();

            // Act
            await worker.PruneOldSnapshotsAsync(db, today, CancellationToken.None);

            // Assert
            var oldExists = await db.Set<BodReportSnapshot>().AnyAsync(x => x.Date == oldDate);
            var keepExists = await db.Set<BodReportSnapshot>().AnyAsync(x => x.Date == keepDate);

            Assert.False(oldExists, "Snapshot older than 90 days was not pruned.");
            Assert.True(keepExists, "Snapshot newer than 90 days was incorrectly pruned.");
        }

        [Fact]
        public async Task BodReportWorker_AcquiresDistributedLock_AndPreventsParallelRuns()
        {
            // [TC-SL1-04] Distributed locking protects execution against parallel worker instances
            using var scope1 = _factory.Services.CreateScope();
            var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();

            var lockKey = DistributedLockManager.ComputeFnv1a64("Checkly.BodReportWorker");

            // Open a raw connection and transaction on connection 1 to hold the lock
            var conn = db1.Database.GetDbConnection();
            if (conn.State != System.Data.ConnectionState.Open)
                await conn.OpenAsync();

            using var transaction = await conn.BeginTransactionAsync();

            using var cmd = conn.CreateCommand();
            cmd.Transaction = transaction;
            cmd.CommandText = $"SELECT pg_try_advisory_xact_lock({lockKey}) AS \"Value\"";
            var acquired = (bool)(await cmd.ExecuteScalarAsync() ?? false);
            Assert.True(acquired, "Prerequisite lock acquisition on connection 1 failed.");

            // Act - trigger worker execution tick on connection 2
            using var scope2 = _factory.Services.CreateScope();
            var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();
            var worker = new BodReportWorker();

            var executed = await worker.TryRunScheduledJobAsync(db2, CancellationToken.None);

            // Assert
            Assert.False(executed, "Worker executed nightly job despite lock being held by another connection.");

            // Cleanup
            await transaction.RollbackAsync();
        }

        [Fact]
        public void DerivesDateOnly_UsingConfiguredCorporateTimezone()
        {
            // [TC-SL1-05] Corporate Timezone is configurable and parsed safely
            var utcTime = new DateTimeOffset(2026, 5, 24, 19, 30, 0, TimeSpan.Zero); // 19:30 UTC
            var worker = new BodReportWorker();

            // Act - resolve DateOnly for corporate timezone Asia/Ho_Chi_Minh (UTC+7) -> resolves to 2026-05-25
            var dateVietnam = worker.ResolveCorporateDate(utcTime, "Asia/Ho_Chi_Minh");
            
            // Act - resolve DateOnly for corporate timezone US/Eastern (UTC-4) -> resolves to 2026-05-24
            var dateEastern = worker.ResolveCorporateDate(utcTime, "US/Eastern");

            // Assert
            Assert.Equal(new DateOnly(2026, 5, 25), dateVietnam);
            Assert.Equal(new DateOnly(2026, 5, 24), dateEastern);
        }

        [Fact]
        public void ResolveTimeZone_InvalidTimeZoneName_FallsBackGracefully()
        {
            // [TC-SL1-07] If the timezone ID is invalid, falls back without throwing exception
            var worker = new BodReportWorker();

            // Act
            var tz = worker.ResolveTimeZone("Invalid/TimeZone_Name");

            // Assert
            Assert.NotNull(tz);
            Assert.Equal(TimeZoneInfo.Utc, tz); // Should fallback to UTC or local timezone
        }

        [Fact]
        public async Task RunNightlyJobAsync_EmptyDatabase_ExecutesWithoutCrashing()
        {
            // [TC-SL1-08] Empty database aggregation executes cleanly with safe default values
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var targetDate = new DateOnly(2020, 1, 1);

            // Clean up existing
            var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
            if (existing != null)
            {
                db.Set<BodReportSnapshot>().Remove(existing);
                await db.SaveChangesAsync();
            }

            var worker = new BodReportWorker();

            // Act
            await worker.RunNightlyJobAsync(db, targetDate, CancellationToken.None);

            // Assert
            var snapshot = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
            Assert.NotNull(snapshot);
            Assert.Equal("Complete", snapshot.Status);

            var json = JsonSerializer.Deserialize<JsonElement>(snapshot.Payload);
            var kpis = json.GetProperty("kpis");

            Assert.Equal(0, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(0m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(0, kpis.GetProperty("activeStores").GetInt32());
        }
    }

    // Helper fake class to test partial failures
    public class FakeFailingBodReportCalculator : BodReportCalculator
    {
        public new Task<string> ComputeDailyReportAsync(AppDbContext db, DateOnly date, CancellationToken ct)
        {
            // Simulate that Query 3 failed, so we output a partially filled payload
            var payload = new
            {
                kpis = new { totalAudits = 10, avgScore = 85.5, activeStores = 3 },
                trend = new[] { new { month = "Jan", score = 80.0 } },
                topStores = (object?)null, // Query 3 failed!
                bottomStores = (object?)null, // Query 3 failed!
                weaknesses = new[] { new { categoryName = "A", avgScore = 65.0 } },
                actionPlanAging = new[] { new { bucket = "0-7d", count = 2 } },
                auditorProductivity = new[] { new { auditorName = "Alice", completedAudits = 5 } }
            };

            return Task.FromResult(JsonSerializer.Serialize(payload));
        }
    }
}
