using System;
using System.Net;
using System.Net.Http.Headers;
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
    public class BodAnalyticsEndpointTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodAnalyticsEndpointTests(TestWebApplicationFactory factory)
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
        public async Task GetBodReport_AsAdmin_ReturnsSuccessAndPayload()
        {
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var storeId = Guid.NewGuid();
            var auditorId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);

                var store = new Store
                {
                    Id = storeId,
                    Name = "Store A",
                    IsActive = true,
                    Address2 = new StoreAddress { Province = "Danang", District = "District 1" },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var submission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    StoreName = "Store A",
                    AuditorId = auditorId,
                    AuditorName = "John Doe",
                    Status = "completed",
                    TotalScore = 84.5m,
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
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var responseJson = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.True(responseJson.GetProperty("isLiveData").GetBoolean());
            
            var kpis = responseJson.GetProperty("kpis");
            Assert.Equal(1, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(84.5m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(1, kpis.GetProperty("openActionPlans").GetInt32());
        }

        [Fact]
        public async Task GetBodReport_AsAuditor_ReturnsForbidden()
        {
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
        public async Task GetBodReport_EmptyDatabase_ReturnsZeroedKpisAndIsLiveTrue()
        {
            // Arrange
            var adminClient = _factory.CreateClient();
            var token = await _factory.LoginBootstrapAdminAsync(adminClient);
            adminClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);
                
                var cache = scope.ServiceProvider.GetService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
                if (cache is Microsoft.Extensions.Caching.Memory.MemoryCache memCache)
                {
                    memCache.Compact(1.0);
                }
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
            Assert.True(json.GetProperty("isLiveData").GetBoolean());

            var kpis = json.GetProperty("kpis");
            Assert.Equal(0, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(0.0m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(0.0m, kpis.GetProperty("completionRate").GetDecimal());
            Assert.Equal(0, kpis.GetProperty("openActionPlans").GetInt32());
            Assert.Equal(0, kpis.GetProperty("activeStores").GetInt32());
            Assert.Equal(0, kpis.GetProperty("totalAuditors").GetInt32());
        }
    }
}
