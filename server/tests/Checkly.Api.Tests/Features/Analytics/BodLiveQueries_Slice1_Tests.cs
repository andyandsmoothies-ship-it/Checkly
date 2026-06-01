using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Analytics
{
    [Collection("Sequential")]
    public class BodLiveQueries_Slice1_Tests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodLiveQueries_Slice1_Tests(TestWebApplicationFactory factory)
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
        public async Task GetGlobalReport_EmptyDatabase_ReturnsZeroedKpisAndIsLiveTrue()
        {
            // TC-SL1-04 (Failure Modes & Empty State): Empty database returns 200 OK with zeroed KPIs and isLiveData: true
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/bod");

            // Assert
            if (response.StatusCode != HttpStatusCode.OK)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected HTTP 200 OK for live query fallback on empty DB, but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.True(json.GetProperty("isLiveData").GetBoolean(), "Expected isLiveData to be true");

            var kpis = json.GetProperty("kpis");
            Assert.Equal(0, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(0.0m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(0.0m, kpis.GetProperty("completionRate").GetDecimal());
            Assert.Equal(0, kpis.GetProperty("openActionPlans").GetInt32());
            Assert.Equal(0, kpis.GetProperty("activeStores").GetInt32());
            Assert.Equal(0, kpis.GetProperty("totalAuditors").GetInt32());

            var allowedActions = json.GetProperty("allowedActions");
            Assert.Equal(JsonValueKind.Array, allowedActions.ValueKind);
            // Verify allowedActions does not contain "refresh"
            foreach (var action in allowedActions.EnumerateArray())
            {
                Assert.NotEqual("refresh", action.GetString());
            }
        }

        [Fact]
        public async Task GetGlobalReport_SeededSubmissions_ReturnsLiveComputedValues()
        {
            // TC-SL1-04: Active store, completed submissions and action plans dynamically calculate global report
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var storeId = Guid.NewGuid();
            var auditorId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);

                var store = new Store
                {
                    Id = storeId,
                    Name = "Hanoi Express Store",
                    IsActive = true,
                    Address2 = new StoreAddress { Province = "Hanoi", District = "Hoan Kiem" },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var submission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    StoreName = "Hanoi Express Store",
                    AuditorId = auditorId,
                    AuditorName = "John Doe",
                    Status = "completed",
                    TotalScore = 90.0m,
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    CompletedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    UpdatedAt = DateTimeOffset.UtcNow.AddDays(-2)
                };
                db.Submissions.Add(submission);

                var actionPlan = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    Deadline = DateTimeOffset.UtcNow.AddDays(5)
                };
                db.ActionPlans.Add(actionPlan);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/bod");

            // Assert
            if (response.StatusCode != HttpStatusCode.OK)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected HTTP 200 OK for live query calculation, but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.True(json.GetProperty("isLiveData").GetBoolean(), "Expected isLiveData to be true");

            var kpis = json.GetProperty("kpis");
            Assert.Equal(1, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(90.0m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(1, kpis.GetProperty("openActionPlans").GetInt32());
            Assert.Equal(1, kpis.GetProperty("activeStores").GetInt32());
            Assert.Equal(1, kpis.GetProperty("totalAuditors").GetInt32());

            var allowedActions = json.GetProperty("allowedActions");
            Assert.Equal(JsonValueKind.Array, allowedActions.ValueKind);
            foreach (var action in allowedActions.EnumerateArray())
            {
                Assert.NotEqual("refresh", action.GetString());
            }
        }

        [Fact]
        public async Task PostRefreshReport_ReturnsNotFound()
        {
            // TC-SL1-03: POST /api/analytics/bod/refresh returns 404 Not Found
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            // Act
            var response = await adminClient.PostAsync("/api/analytics/bod/refresh", null);

            // Assert
            if (response.StatusCode != HttpStatusCode.NotFound)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected HTTP 404 Not Found for deleted refresh endpoint, but got {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }
    }
}
