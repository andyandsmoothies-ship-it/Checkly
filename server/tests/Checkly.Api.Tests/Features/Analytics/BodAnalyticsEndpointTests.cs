using System;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Analytics;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Analytics
{
    [Collection("Sequential")]
    public class BodAnalyticsEndpointTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodAnalyticsEndpointTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                db.Database.ExecuteSqlRaw("DELETE FROM bod_report_snapshots");
            }
        }

        [Fact]
        public async Task GetBodReport_AsAdmin_ReturnsSuccessAndPayload()
        {
            // TC-SL2-01 & TC-SL2-04: Admin fetches the latest complete BOD snapshot successfully
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Clear any pre-existing snapshot for our specific test date to prevent database pollution
                var targetDate = new DateOnly(2026, 5, 24);
                var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == targetDate);
                if (existing != null)
                {
                    db.Set<BodReportSnapshot>().Remove(existing);
                    await db.SaveChangesAsync();
                }

                // Seed a completed snapshot payload
                var fakePayload = new
                {
                    date = "2026-05-24",
                    computedAt = "2026-05-24T02:15:00Z",
                    status = "Complete",
                    kpis = new
                    {
                        totalAudits = 45,
                        avgScore = 84.5,
                        avgScoreDelta = 2.1,
                        completionRate = 92.5,
                        completionRateDelta = -1.2,
                        openAPs = 12,
                        overdueAPs = 3,
                        activeStores = 8,
                        totalAuditors = 4
                    },
                    trend = new[]
                    {
                        new { month = "2026-01", avgScore = 80.0, auditCount = 35 }
                    },
                    topStores = new[]
                    {
                        new { storeName = "Store A", province = "Danang", avgScore = 92.0, auditCount = 12, rank = 1 }
                    },
                    bottomStores = new[]
                    {
                        new { storeName = "Store B", province = "Danang", avgScore = 75.0, auditCount = 8, rank = 8 }
                    },
                    weaknesses = new[]
                    {
                        new { categoryName = "Cleanliness", failCount = 18, totalChecks = 120, failRate = 15.0 }
                    },
                    actionPlanAging = new[]
                    {
                        new { bucket = "0-7 days", count = 5 }
                    },
                    auditorProductivity = new[]
                    {
                        new { auditorName = "John Doe", auditCount = 15, avgScore = 86.0 }
                    }
                };

                var snapshot = new BodReportSnapshot
                {
                    Id = Guid.NewGuid(),
                    Date = targetDate,
                    ComputedAt = DateTimeOffset.UtcNow,
                    Status = "Complete",
                    Payload = JsonSerializer.Serialize(fakePayload)
                };

                await db.Set<BodReportSnapshot>().AddAsync(snapshot);
                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/bod");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var responseJson = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("Complete", responseJson.GetProperty("status").GetString());
            Assert.Equal("2026-05-24", responseJson.GetProperty("date").GetString());
            
            var kpis = responseJson.GetProperty("kpis");
            Assert.Equal(45, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(84.5m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(12, kpis.GetProperty("openAPs").GetInt32());
        }

        [Fact]
        public async Task GetBodReport_AsAuditor_ReturnsForbidden()
        {
            // TC-SL2-02: Non-admin user gets 403 Forbidden on fetch
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(baseClient, "auditor-fetch@checkly.test", "Auditor123!@", "Auditor Fetch User", "auditor");
            var auditorClient = _factory.CreateAuthenticatedClient(token);

            // Act
            var response = await auditorClient.GetAsync("/api/analytics/bod");

            // Assert
            if (response.StatusCode != HttpStatusCode.Forbidden)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected Forbidden (403), but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task RefreshBodReport_AsAuditor_ReturnsForbidden()
        {
            // TC-SL2-02: Non-admin user gets 403 Forbidden on refresh
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(baseClient, "auditor-refresh@checkly.test", "Auditor123!@", "Auditor Refresh User", "auditor");
            var auditorClient = _factory.CreateAuthenticatedClient(token);

            // Act
            var response = await auditorClient.PostAsync("/api/analytics/bod/refresh", null);

            // Assert
            if (response.StatusCode != HttpStatusCode.Forbidden)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected Forbidden (403), but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetBodReport_EmptyDatabase_ReturnsNotFound()
        {
            // TC-SL2-03: Fetch returns 404 with custom payload when database has no snapshots
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // WIPE ALL SNAPSHOTS so database has zero reports
                await db.Database.ExecuteSqlRawAsync("DELETE FROM bod_report_snapshots");
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/bod");

            // Assert
            if (response.StatusCode != HttpStatusCode.NotFound)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected NotFound (404), but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

            var errorResponse = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.True(errorResponse.TryGetProperty("error", out var errorMsg));
            Assert.Equal("No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM.", errorMsg.GetString());
        }

        [Fact]
        public async Task RefreshBodReport_AsAdmin_TriggersRefresh()
        {
            // TC-SL2-05: Refresh triggers computation and returns 200 OK on first call
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Access the singleton background worker using standard DI lookup in the application
            var worker = _factory.Services.GetService<BodReportWorker>();
            if (worker != null)
            {
                // Reset internal worker timer state using reflection for reliable integration test runs
                var field = typeof(BodReportWorker).GetField("_lastManualRun", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                if (field != null)
                {
                    field.SetValue(worker, null);
                }
            }

            // Act
            var response = await adminClient.PostAsync("/api/analytics/bod/refresh", null);

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"First manual refresh trigger failed ({response.StatusCode}): {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var responseJson = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("triggered", responseJson.GetProperty("status").GetString());
            Assert.True(responseJson.TryGetProperty("computedAt", out _));
        }

        [Fact]
        public async Task RefreshBodReport_RateLimitsConsecutiveRequests()
        {
            // TC-SL2-05: Subsequent refresh calls within 15 minutes return 429 Too Many Requests
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Access background worker and reset rate limit
            var worker = _factory.Services.GetRequiredService<BodReportWorker>();
            var field = typeof(BodReportWorker).GetField("_lastManualRun", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            if (field != null)
            {
                field.SetValue(worker, null);
            }

            // Act 1: First trigger (success)
            var response1 = await adminClient.PostAsync("/api/analytics/bod/refresh", null);
            if (!response1.IsSuccessStatusCode)
            {
                var body1 = await response1.Content.ReadAsStringAsync();
                Assert.Fail($"Prerequisite first trigger failed: {body1}");
            }

            // Act 2: Immediate second trigger (should fail with 429)
            var response2 = await adminClient.PostAsync("/api/analytics/bod/refresh", null);

            // Assert
            if (response2.StatusCode != HttpStatusCode.TooManyRequests)
            {
                var body2 = await response2.Content.ReadAsStringAsync();
                Assert.Fail($"Expected TooManyRequests (429), but got {response2.StatusCode}. Body: {body2}");
            }

            Assert.Equal(HttpStatusCode.TooManyRequests, response2.StatusCode);

            var errorBody = await response2.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("rate_limited", errorBody.GetProperty("status").GetString());
            Assert.Equal("15 min", errorBody.GetProperty("retryAfter").GetString());
        }

        [Fact]
        public async Task RefreshBodReport_ConcurrentTriggers_RespectsLock()
        {
            // TC-SL2-06: Refresh respects advisory lock; concurrent executions reject with conflict
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Access background worker and reset rate limit
            var worker = _factory.Services.GetRequiredService<BodReportWorker>();
            var field = typeof(BodReportWorker).GetField("_lastManualRun", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            if (field != null)
            {
                field.SetValue(worker, null);
            }

            using (var scope1 = _factory.Services.CreateScope())
            {
                var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();

                // Acquire the postgres advisory lock in another transaction/session
                var lockKey = DistributedLockManager.ComputeFnv1a64("Checkly.BodReportWorker");
                var conn = db1.Database.GetDbConnection();
                if (conn.State != System.Data.ConnectionState.Open)
                    await conn.OpenAsync();

                using (var transaction = await conn.BeginTransactionAsync())
                {
                    using (var cmd = conn.CreateCommand())
                    {
                        cmd.Transaction = transaction;
                        cmd.CommandText = $"SELECT pg_try_advisory_xact_lock({lockKey}) AS \"Value\"";
                        var acquired = (bool)(await cmd.ExecuteScalarAsync() ?? false);
                        Assert.True(acquired, "Prerequisite lock acquisition failed.");

                        // Act - attempt to trigger refresh while the lock is held
                        var response = await adminClient.PostAsync("/api/analytics/bod/refresh", null);

                        // Assert - should return either 400 Bad Request or 409 Conflict with the standard message
                        Assert.True(response.StatusCode == HttpStatusCode.BadRequest || response.StatusCode == HttpStatusCode.Conflict,
                            $"Expected BadRequest (400) or Conflict (409), but got {response.StatusCode}");

                        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                        Assert.True(json.TryGetProperty("error", out var errorProperty));
                        Assert.Equal("Another refresh job is already in progress.", errorProperty.GetString());
                    }

                    await transaction.RollbackAsync();
                }
            }
        }
    }
}
