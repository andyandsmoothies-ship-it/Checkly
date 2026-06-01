using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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
    public class BodLiveQueries_Slice3_Tests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodLiveQueries_Slice3_Tests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        private static async Task ClearDatabaseAsync(AppDbContext db)
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
        public async Task GetGlobalReport_FiltersOutInactiveStoresSubmissionsAndActionPlans()
        {
            // AC-GlobalActiveStores: Bypasses memory contains list, but only active stores' data is processed
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var activeStoreId = Guid.NewGuid();
            var inactiveStoreId = Guid.NewGuid();
            var auditorId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);

                // Active store
                var activeStore = new Store
                {
                    Id = activeStoreId,
                    Name = "Active Hanoi Store",
                    IsActive = true,
                    Address2 = new StoreAddress { Province = "Hanoi", District = "Hoan Kiem" },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(activeStore);

                // Inactive store
                var inactiveStore = new Store
                {
                    Id = inactiveStoreId,
                    Name = "Inactive Saigon Store",
                    IsActive = false,
                    Address2 = new StoreAddress { Province = "Saigon", District = "District 1" },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(inactiveStore);

                // Submission on active store
                var activeSubmission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = activeStoreId,
                    StoreName = "Active Hanoi Store",
                    AuditorId = auditorId,
                    AuditorName = "John Doe",
                    Status = "completed",
                    TotalScore = 95.0m,
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    CompletedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    UpdatedAt = DateTimeOffset.UtcNow.AddDays(-2)
                };
                db.Submissions.Add(activeSubmission);

                // Submission on inactive store
                var inactiveSubmission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = inactiveStoreId,
                    StoreName = "Inactive Saigon Store",
                    AuditorId = auditorId,
                    AuditorName = "John Doe",
                    Status = "completed",
                    TotalScore = 80.0m,
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    CompletedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    UpdatedAt = DateTimeOffset.UtcNow.AddDays(-2)
                };
                db.Submissions.Add(inactiveSubmission);

                // Open action plan on active store
                var activeAp = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = activeStoreId,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    Deadline = DateTimeOffset.UtcNow.AddDays(5)
                };
                db.ActionPlans.Add(activeAp);

                // Open action plan on inactive store
                var inactiveAp = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = inactiveStoreId,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    Deadline = DateTimeOffset.UtcNow.AddDays(5)
                };
                db.ActionPlans.Add(inactiveAp);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/bod");

            // Assert
            if (response.StatusCode != HttpStatusCode.OK)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Expected HTTP 200 OK for global report, but got {response.StatusCode}. Body: {errorBody}");
            }

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            var kpis = json.GetProperty("kpis");

            // KPI assertions: Hanoi store is counted, Saigon store is NOT
            Assert.Equal(1, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(95.0m, kpis.GetProperty("avgScore").GetDecimal());
            Assert.Equal(1, kpis.GetProperty("openActionPlans").GetInt32());
            Assert.Equal(1, kpis.GetProperty("activeStores").GetInt32());
        }

        [Fact]
        public async Task GetReport_AllowedActionsrefreshBehavior_OmittedOnGlobalIncludedOnFiltered()
        {
            // AC-AllowedActions: Dynamically omits "refresh" from allowedActions when isGlobal == true (including empty string)
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await ClearDatabaseAsync(db);
            }

            // Scenario A: Global Query (both null/empty)
            {
                var response = await adminClient.GetAsync("/api/analytics/bod");
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);

                var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                var actions = json.GetProperty("allowedActions").EnumerateArray().Select(x => x.GetString()).ToList();
                Assert.DoesNotContain("refresh", actions);
            }

            // Scenario B: Global Query with empty string parameters
            {
                var response = await adminClient.GetAsync("/api/analytics/bod?province=&district=");
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);

                var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                var actions = json.GetProperty("allowedActions").EnumerateArray().Select(x => x.GetString()).ToList();
                Assert.DoesNotContain("refresh", actions);
            }

            // Scenario C: Filtered Query (has province)
            {
                var response = await adminClient.GetAsync("/api/analytics/bod?province=Hanoi");
                Assert.Equal(HttpStatusCode.OK, response.StatusCode);

                var json = await response.Content.ReadFromJsonAsync<JsonElement>();
                var actions = json.GetProperty("allowedActions").EnumerateArray().Select(x => x.GetString()).ToList();
                Assert.Contains("refresh", actions);
            }
        }

        [Fact]
        public void GetBodReportCode_DoesNotContainIndexUnfriendlyNullCoalescingOperator()
        {
            // AC-IndexFriendly: Replaces (CompletedAt ?? CreatedAt) range queries with index-friendly CompletedAt direct filters
            // Arrange
            var projectRoot = AppContext.BaseDirectory;
            string? codePath = null;

            // Resolve the source file location relative to build directory
            var currentDir = new DirectoryInfo(projectRoot);
            while (currentDir != null)
            {
                var pathToCheck = Path.Combine(currentDir.FullName, "server", "Features", "Analytics", "GetBodReport.cs");
                if (File.Exists(pathToCheck))
                {
                    codePath = pathToCheck;
                    break;
                }
                currentDir = currentDir.Parent;
            }

            Assert.NotNull(codePath);

            var codeContent = File.ReadAllText(codePath);

            // Assert that the null coalescing operator on CompletedAt / CreatedAt inside queries has been rewritten
            Assert.DoesNotContain("CompletedAt ?? CreatedAt", codeContent);
            Assert.DoesNotContain("CompletedAt ?? s.CreatedAt", codeContent);
            Assert.DoesNotContain("?? s.CreatedAt", codeContent);
            Assert.DoesNotContain("?? CreatedAt", codeContent);
        }
    }
}
