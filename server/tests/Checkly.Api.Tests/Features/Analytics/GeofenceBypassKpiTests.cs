using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Analytics;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Analytics
{
    [Collection("Sequential")]
    public class GeofenceBypassKpiTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public GeofenceBypassKpiTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        private async Task ClearDatabaseAsync(AppDbContext db)
        {
            await db.Database.ExecuteSqlRawAsync("DELETE FROM profile_store_assignments");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM program_assignments");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM action_plans");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM submission_section_scores");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM submission_risks");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM answers");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM submissions");
            await db.Database.ExecuteSqlRawAsync("DELETE FROM stores");
        }

        [Fact]
        public async Task GetBodReport_LiveQuery_ComputesGeofenceBypassesCorrectly()
        {
            // Arrange
            var client = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(client);
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var storeId = Guid.NewGuid();
            var targetProvince = $"Hanoi-{Guid.NewGuid():N}"; // Unique to isolate test run

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);

                var store = new Store
                {
                    Id = storeId,
                    Name = $"Store Hanoi {Guid.NewGuid():N}",
                    IsActive = true,
                    Address2 = new StoreAddress { Province = targetProvince, District = "Ba Dinh" },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var now = DateTimeOffset.UtcNow;

                // 1. Counted: Completed, Non-rejected, in last 30 days, IsGeofenceBypassed = true
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = true,
                    CompletedAt = now.AddDays(-5),
                    CreatedAt = now.AddDays(-5),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 2. Excluded: Completed, Non-rejected, in last 30 days, IsGeofenceBypassed = false
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = false,
                    CompletedAt = now.AddDays(-5),
                    CreatedAt = now.AddDays(-5),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 3. Excluded: Completed, Non-rejected, in last 30 days, IsGeofenceBypassed = null
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = null,
                    CompletedAt = now.AddDays(-5),
                    CreatedAt = now.AddDays(-5),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 4. Excluded: Completed, Rejected, in last 30 days, IsGeofenceBypassed = true
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = "rejected",
                    IsGeofenceBypassed = true,
                    CompletedAt = now.AddDays(-5),
                    CreatedAt = now.AddDays(-5),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 5. Excluded: Completed, Non-rejected, outside 30 days (35 days ago), IsGeofenceBypassed = true
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = true,
                    CompletedAt = now.AddDays(-35),
                    CreatedAt = now.AddDays(-35),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 6. Excluded: Draft, IsGeofenceBypassed = true, in last 30 days
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "draft",
                    ReviewStatus = null,
                    IsGeofenceBypassed = true,
                    CompletedAt = null,
                    CreatedAt = now.AddDays(-5),
                    UpdatedAt = now
                });

                await db.SaveChangesAsync();
            }

            // Act
            var response = await client.GetAsync($"/api/analytics/bod?province={Uri.EscapeDataString(targetProvince)}");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var responseJson = await response.Content.ReadFromJsonAsync<JsonElement>();
            var kpis = responseJson.GetProperty("kpis");

            // Dynamic key assertion
            Assert.True(kpis.TryGetProperty("geofenceBypassCount", out var bypassProp), "Expected 'geofenceBypassCount' property inside 'kpis'.");
            Assert.Equal(1, bypassProp.GetInt32());
        }

        [Fact]
        public async Task ComputeDailyReport_NightlySnapshot_ComputesGeofenceBypassesCorrectly()
        {
            // Arrange
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var storeId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);

                var store = new Store
                {
                    Id = storeId,
                    Name = $"Store Nightly {Guid.NewGuid():N}",
                    IsActive = true,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var now = DateTimeOffset.UtcNow;

                // 1. Counted: Completed, Non-rejected, IsGeofenceBypassed = true (nightly includes all up to target DateTime)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = true,
                    CompletedAt = now.AddHours(-1),
                    CreatedAt = now.AddHours(-2),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                // 2. Excluded: Completed, Non-rejected, IsGeofenceBypassed = false
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    ReviewStatus = null,
                    IsGeofenceBypassed = false,
                    CompletedAt = now.AddHours(-1),
                    CreatedAt = now.AddHours(-2),
                    UpdatedAt = now,
                    TotalScore = 80.0m
                });

                await db.SaveChangesAsync();
            }

            // Act
            var calculator = new BodReportCalculator();
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var payloadJson = await calculator.ComputeDailyReportWithTimezoneAsync(db, today, "Asia/Ho_Chi_Minh", CancellationToken.None);

                // Assert
                var json = JsonDocument.Parse(payloadJson);
                var kpis = json.RootElement.GetProperty("kpis");

                Assert.True(kpis.TryGetProperty("geofenceBypassCount", out var bypassProp), "Expected 'geofenceBypassCount' property inside cached 'kpis' payload.");
                Assert.Equal(1, bypassProp.GetInt32());
            }
        }
    }
}
