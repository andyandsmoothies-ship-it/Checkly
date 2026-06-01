using System;
using System.Collections.Generic;
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
    public class BodAnalyticsExtendedSlice2Tests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodAnalyticsExtendedSlice2Tests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public async Task GetStoreBodSummary_AsStoreManager_OwnStore_ReturnsStoreSummary()
        {
            // Arrange
            var client = _factory.CreateClient();
            var (token, managerUserId) = await _factory.RegisterUserAsync(client, "sm-own@checkly.test", "Manager123!@", "SM Own Store", "store_manager");
            var managerClient = _factory.CreateAuthenticatedClient(token);

            Guid storeId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Seed store with manager profile
                var store = new Store
                {
                    Id = storeId,
                    Name = "SM Own Store Target",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == managerUserId);
                if (profile != null)
                {
                    profile.StoreId = storeId;
                    db.Entry(profile).State = EntityState.Modified;
                }

                await db.SaveChangesAsync();
            }

            // Act
            var response = await managerClient.GetAsync($"/api/analytics/stores/{storeId}/bod-summary");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("SM Own Store Target", json.GetProperty("storeName").GetString());
        }

        [Fact]
        public async Task GetStoreBodSummary_AsStoreManager_DifferentStore_ReturnsForbidden()
        {
            // Arrange
            var client = _factory.CreateClient();
            var (token, managerUserId) = await _factory.RegisterUserAsync(client, "sm-diff@checkly.test", "Manager123!@", "SM Diff Store", "store_manager");
            var managerClient = _factory.CreateAuthenticatedClient(token);

            Guid storeIdA = Guid.NewGuid();
            Guid storeIdB = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var storeA = new Store
                {
                    Id = storeIdA,
                    Name = "Store A",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                var storeB = new Store
                {
                    Id = storeIdB,
                    Name = "Store B",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.AddRange(storeA, storeB);

                var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == managerUserId);
                if (profile != null)
                {
                    profile.StoreId = storeIdA;
                    db.Entry(profile).State = EntityState.Modified;
                }

                await db.SaveChangesAsync();
            }

            // Act
            var response = await managerClient.GetAsync($"/api/analytics/stores/{storeIdB}/bod-summary");

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetStoreBodSummary_AsAreaManager_AssignedStore_ReturnsStoreSummary()
        {
            // Arrange
            var client = _factory.CreateClient();
            var (token, managerUserId) = await _factory.RegisterUserAsync(client, "am-assigned@checkly.test", "Manager123!@", "AM Assigned Store", "area_manager");
            var amClient = _factory.CreateAuthenticatedClient(token);

            Guid storeId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "AM Assigned Store Target",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var assignment = new ProfileStoreAssignment
                {
                    ProfileId = managerUserId,
                    StoreId = storeId,
                    CreatedAt = DateTimeOffset.UtcNow
                };
                db.ProfileStoreAssignments.Add(assignment);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await amClient.GetAsync($"/api/analytics/stores/{storeId}/bod-summary");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("AM Assigned Store Target", json.GetProperty("storeName").GetString());
        }

        [Fact]
        public async Task GetStoreBodSummary_AsAreaManager_UnassignedStore_ReturnsForbidden()
        {
            // Arrange
            var client = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(client, "am-unassigned@checkly.test", "Manager123!@", "AM Unassigned Store", "area_manager");
            var amClient = _factory.CreateAuthenticatedClient(token);

            Guid storeId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "AM Unassigned Store Target",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await amClient.GetAsync($"/api/analytics/stores/{storeId}/bod-summary");

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetStoreBodSummary_QuartileCalculation_FourPeers_ReturnsCorrectQuartileLabel()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid targetStoreId = Guid.NewGuid();
            string provinceName = $"Province-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Create 4 active stores in the same province
                // Store A: 90.0m
                var storeA = new Store { Id = Guid.NewGuid(), Name = "Regional Store A", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                // Store B (Target): 80.0m
                var storeB = new Store { Id = targetStoreId, Name = "Regional Store Target B", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                // Store C: 70.0m
                var storeC = new Store { Id = Guid.NewGuid(), Name = "Regional Store C", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                // Store D: 60.0m
                var storeD = new Store { Id = Guid.NewGuid(), Name = "Regional Store D", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

                db.Stores.AddRange(storeA, storeB, storeC, storeD);

                // Add snapshots
                db.StoreAnalyticsSnapshots.AddRange(
                    new StoreAnalyticsSnapshot { StoreId = storeA.Id, AvgScore30d = 90.0m, UpdatedAt = DateTimeOffset.UtcNow },
                    new StoreAnalyticsSnapshot { StoreId = storeB.Id, AvgScore30d = 80.0m, UpdatedAt = DateTimeOffset.UtcNow },
                    new StoreAnalyticsSnapshot { StoreId = storeC.Id, AvgScore30d = 70.0m, UpdatedAt = DateTimeOffset.UtcNow },
                    new StoreAnalyticsSnapshot { StoreId = storeD.Id, AvgScore30d = 60.0m, UpdatedAt = DateTimeOffset.UtcNow }
                );

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/stores/{targetStoreId}/bod-summary");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal("Top 50% in Region", json.GetProperty("quartileLabel").GetString());
            // Regional average: (90 + 80 + 70 + 60) / 4 = 75.0
            Assert.Equal(75.0m, json.GetProperty("regionalAvgScore").GetDecimal());
        }

        [Fact]
        public async Task GetStoreBodSummary_QuartileCalculation_LessThanFourPeers_ReturnsNullQuartileLabel()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid targetStoreId = Guid.NewGuid();
            string provinceName = $"Province-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Create only 3 active stores in the province
                var storeA = new Store { Id = Guid.NewGuid(), Name = "Regional Store A", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                var storeB = new Store { Id = targetStoreId, Name = "Regional Store Target B", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                var storeC = new Store { Id = Guid.NewGuid(), Name = "Regional Store C", Address2 = new StoreAddress { Province = provinceName }, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

                db.Stores.AddRange(storeA, storeB, storeC);

                db.StoreAnalyticsSnapshots.AddRange(
                    new StoreAnalyticsSnapshot { StoreId = storeA.Id, AvgScore30d = 90.0m, UpdatedAt = DateTimeOffset.UtcNow },
                    new StoreAnalyticsSnapshot { StoreId = storeB.Id, AvgScore30d = 80.0m, UpdatedAt = DateTimeOffset.UtcNow },
                    new StoreAnalyticsSnapshot { StoreId = storeC.Id, AvgScore30d = 70.0m, UpdatedAt = DateTimeOffset.UtcNow }
                );

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/stores/{targetStoreId}/bod-summary");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Null(json.GetProperty("quartileLabel").GetString());
            // Regional average: (90 + 80 + 70) / 3 = 80.0
            Assert.Equal(80.0m, json.GetProperty("regionalAvgScore").GetDecimal());
        }

        [Fact]
        public async Task GetStoreBodSummary_SlaOverdueActionPlans_BucketsOpenOverdueAPs()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid storeId = Guid.NewGuid();
            var now = DateTimeOffset.UtcNow;

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "Store Action Plans",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                // Overdue 0-7 days: deadline 5 days ago
                var ap1 = new ActionPlan { Id = Guid.NewGuid(), StoreId = storeId, Status = "open", Deadline = now.AddDays(-5), CreatedAt = now.AddDays(-10), UpdatedAt = now };
                // Overdue 8-30 days: deadline 15 days ago
                var ap2 = new ActionPlan { Id = Guid.NewGuid(), StoreId = storeId, Status = "open", Deadline = now.AddDays(-15), CreatedAt = now.AddDays(-20), UpdatedAt = now };
                // Overdue 31+ days: deadline 45 days ago
                var ap3 = new ActionPlan { Id = Guid.NewGuid(), StoreId = storeId, Status = "open", Deadline = now.AddDays(-45), CreatedAt = now.AddDays(-50), UpdatedAt = now };
                // Excluded: deadline in the future
                var ap4 = new ActionPlan { Id = Guid.NewGuid(), StoreId = storeId, Status = "open", Deadline = now.AddDays(5), CreatedAt = now.AddDays(-5), UpdatedAt = now };
                // Excluded: status is closed
                var ap5 = new ActionPlan { Id = Guid.NewGuid(), StoreId = storeId, Status = "closed", Deadline = now.AddDays(-5), CreatedAt = now.AddDays(-10), UpdatedAt = now };

                db.ActionPlans.AddRange(ap1, ap2, ap3, ap4, ap5);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/stores/{storeId}/bod-summary");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            var buckets = json.GetProperty("slaOverdueBuckets");
            Assert.Equal(JsonValueKind.Array, buckets.ValueKind);
            Assert.Equal(3, buckets.GetArrayLength());

            // 0-7d, 8-30d, 31+d
            var bucket0To7 = buckets[0];
            Assert.Equal("0-7d", bucket0To7.GetProperty("bucket").GetString());
            Assert.Equal(1, bucket0To7.GetProperty("count").GetInt32());

            var bucket8To30 = buckets[1];
            Assert.Equal("8-30d", bucket8To30.GetProperty("bucket").GetString());
            Assert.Equal(1, bucket8To30.GetProperty("count").GetInt32());

            var bucket31Plus = buckets[2];
            Assert.Equal("31+d", bucket31Plus.GetProperty("bucket").GetString());
            Assert.Equal(1, bucket31Plus.GetProperty("count").GetInt32());
        }
    }
}
