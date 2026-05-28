using System;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
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
    public class BodAnalyticsFilteredEndpointTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodAnalyticsFilteredEndpointTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_ReturnsDynamicLiveData()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvinceHanoi = $"Hanoi-{Guid.NewGuid():N}";
            var uniqueProvinceHcm = $"HCM-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Seed store in Hanoi
                var storeHanoi = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "Hanoi Express Store",
                    Address2 = new StoreAddress { Province = uniqueProvinceHanoi },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeHanoi);

                // Seed store in HCM
                var storeHcm = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "HCM Flagship Store",
                    Address2 = new StoreAddress { Province = uniqueProvinceHcm },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeHcm);

                // Seed a completed submission for Hanoi (score = 80)
                var submissionHanoi = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeHanoi.Id,
                    Status = "completed",
                    TotalScore = 80.0m,
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    UpdatedAt = DateTimeOffset.UtcNow.AddHours(-1)
                };
                db.Submissions.Add(submissionHanoi);

                // Seed a completed submission for HCM (score = 95)
                var submissionHcm = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeHcm.Id,
                    Status = "completed",
                    TotalScore = 95.0m,
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    UpdatedAt = DateTimeOffset.UtcNow.AddHours(-1)
                };
                db.Submissions.Add(submissionHcm);

                await db.SaveChangesAsync();
            }

            // Act: Query with filter ?province=Hanoi
            var response = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvinceHanoi}");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            // Assert dynamic live calculations
            Assert.True(json.GetProperty("isLiveData").GetBoolean(), "Expected isLiveData to be true when filtered");

            var kpis = json.GetProperty("kpis");
            Assert.Equal(1, kpis.GetProperty("totalAudits").GetInt32());
            Assert.Equal(80.0m, kpis.GetProperty("avgScore").GetDecimal());
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_ReturnsGoldenStoreBenchmark()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvinceHanoi = $"Hanoi-{Guid.NewGuid():N}";
            var uniqueProvinceHcm = $"HCM-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Store in Hanoi
                var storeHanoi = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "Hanoi Store",
                    Address2 = new StoreAddress { Province = uniqueProvinceHanoi },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeHanoi);

                // Store in HCM (Golden Store candidate!)
                var storeHcm = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "HCM Golden Store",
                    Address2 = new StoreAddress { Province = uniqueProvinceHcm },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeHcm);

                // Submission for Hanoi (score = 70)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeHanoi.Id,
                    Status = "completed",
                    TotalScore = 70.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });

                // Submission for HCM (score = 98 - top store!)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeHcm.Id,
                    Status = "completed",
                    TotalScore = 98.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvinceHanoi}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            Assert.True(json.TryGetProperty("goldenStore", out var goldenStore), "Response must contain goldenStore");
            Assert.Equal(JsonValueKind.Object, goldenStore.ValueKind);
            Assert.Equal("HCM Golden Store", goldenStore.GetProperty("storeName").GetString());
            Assert.Equal(98.0m, goldenStore.GetProperty("avgScore").GetDecimal());
            Assert.Equal(uniqueProvinceHcm, goldenStore.GetProperty("province").GetString());
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_CalculatesActionPlanTtr()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvince = $"ProvinceTtr-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "TTR Test Store",
                    Address2 = new StoreAddress { Province = uniqueProvince },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var submission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    Status = "completed",
                    TotalScore = 80.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submission);

                // Seed closed action plan with 4 days TTR
                var ap1 = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    SubmissionId = submission.Id,
                    Status = "closed",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
                    ClosedAt = DateTimeOffset.UtcNow.AddDays(-1)
                };
                db.ActionPlans.Add(ap1);

                // Seed closed action plan with 6 days TTR
                var ap2 = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    SubmissionId = submission.Id,
                    Status = "closed",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-10),
                    ClosedAt = DateTimeOffset.UtcNow.AddDays(-4)
                };
                db.ActionPlans.Add(ap2);

                // Seed open action plan (should be ignored in TTR average)
                var ap3 = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    SubmissionId = submission.Id,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-10),
                    ClosedAt = null
                };
                db.ActionPlans.Add(ap3);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvince}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            var kpis = json.GetProperty("kpis");
            Assert.True(kpis.TryGetProperty("avgTtrDays", out var avgTtrProperty), "kpis must contain avgTtrDays");
            Assert.Equal(5.0m, avgTtrProperty.GetDecimal());
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_ReturnsStoreLastSyncedAt()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvince = $"ProvinceSync-{Guid.NewGuid():N}";
            var storeId = Guid.NewGuid();
            var targetSyncTime = new DateTimeOffset(2026, 5, 24, 12, 0, 0, TimeSpan.Zero);

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "Sync Store",
                    Address2 = new StoreAddress { Province = uniqueProvince },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var submission = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    TotalScore = 90.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submission);

                await db.SaveChangesAsync();

                // Natively update the column `last_synced_at` via raw SQL to bypass compile checks on entity properties.
                // Throws expected DbUpdateException / PostgresException when column doesn't exist (RED).
                await db.Database.ExecuteSqlRawAsync(
                    "UPDATE stores SET last_synced_at = {0} WHERE id = {1}", 
                    targetSyncTime, storeId);
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvince}");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            var topStores = json.GetProperty("topStores");
            Assert.True(topStores.GetArrayLength() > 0, "topStores should contain seeded store");

            var firstStore = topStores[0];
            Assert.True(firstStore.TryGetProperty("lastSyncedAt", out var syncTimeProperty), "Store should contain lastSyncedAt");
            Assert.NotNull(syncTimeProperty.GetString());
            
            var parsedSyncTime = DateTimeOffset.Parse(syncTimeProperty.GetString()!);
            Assert.Equal(targetSyncTime, parsedSyncTime);
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_ServesFromCacheAndBypassesDatabase()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvince = $"ProvinceCache-{Guid.NewGuid():N}";
            var storeId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "Cache Store",
                    Address2 = new StoreAddress { Province = uniqueProvince },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                var sub1 = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    TotalScore = 90.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(sub1);

                await db.SaveChangesAsync();
            }

            // Act 1: Initial call to populate cache
            var response1 = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvince}");
            Assert.Equal(HttpStatusCode.OK, response1.StatusCode);
            var json1 = await response1.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(90.0m, json1.GetProperty("kpis").GetProperty("avgScore").GetDecimal());

            // Seed a new high score submission (60%) for the store
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    Status = "completed",
                    TotalScore = 60.0m,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });
                await db.SaveChangesAsync();
            }

            // Act 2: Immediate follow-up call should return cached data (90.0% instead of new average 75.0%)
            var response2 = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvince}");
            Assert.Equal(HttpStatusCode.OK, response2.StatusCode);
            var json2 = await response2.Content.ReadFromJsonAsync<JsonElement>();
            
            // Assert that cache was hit and returns the cached 90.0% score!
            Assert.Equal(90.0m, json2.GetProperty("kpis").GetProperty("avgScore").GetDecimal());
        }

        [Fact]
        public async Task GetBodReport_WithArchetypeFilter_QCStoreAppearsAndGeneralStoreExcludedInNightlySnapshot()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var templateQcId = Guid.NewGuid();
            var templateGeneralId = Guid.NewGuid();
            var storeQCId = Guid.NewGuid();
            var storeGeneralId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Clean up any existing snapshot for today to prevent leakage
                var existing = await db.Set<BodReportSnapshot>().FirstOrDefaultAsync(x => x.Date == today);
                if (existing != null)
                {
                    db.Set<BodReportSnapshot>().Remove(existing);
                    await db.SaveChangesAsync();
                }

                // Templates
                var templateQc = new Template
                {
                    Id = templateQcId,
                    Title = "QC Scored Audit",
                    Type = "QC",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateQc);

                var templateGeneral = new Template
                {
                    Id = templateGeneralId,
                    Title = "General Tasks",
                    Type = "General",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateGeneral);

                // Stores
                var storeQc = new Store
                {
                    Id = storeQCId,
                    Name = $"QC Store {Guid.NewGuid():N}",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeQc);

                var storeGeneral = new Store
                {
                    Id = storeGeneralId,
                    Name = $"General Store {Guid.NewGuid():N}",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeGeneral);

                // Submissions
                var submA = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeQCId,
                    TemplateId = templateQcId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 85.0m,
                    TemplateType = "QC",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submA);

                var submB = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeGeneralId,
                    TemplateId = templateGeneralId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 92.0m,
                    TemplateType = "General",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submB);

                await db.SaveChangesAsync();

                // Compute nightly snapshot
                var worker = new BodReportWorker();
                await worker.RunNightlyJobAsync(db, today, CancellationToken.None);
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

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            // The QC store MUST appear in the topStores leaderboard (or bottomStores, since there is only 1 QC store).
            var topStores = json.GetProperty("topStores");
            bool qcStoreFound = false;
            bool generalStoreFound = false;

            for (int i = 0; i < topStores.GetArrayLength(); i++)
            {
                var storeId = Guid.Parse(topStores[i].GetProperty("storeId").GetString()!);
                if (storeId == storeQCId) qcStoreFound = true;
                if (storeId == storeGeneralId) generalStoreFound = true;
            }

            Assert.True(qcStoreFound, "Expected the QC template store to be present in topStores.");
            Assert.False(generalStoreFound, "Expected the General template store to be excluded from topStores.");
        }

        [Fact]
        public async Task GetBodReport_WithProvinceFilter_ExcludesGeneralTemplateStoresFromLeaderboard()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvince = $"ProvinceArchetypeFilter-{Guid.NewGuid():N}";
            var templateQcId = Guid.NewGuid();
            var templateGeneralId = Guid.NewGuid();
            var storeQCId = Guid.NewGuid();
            var storeGeneralId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Templates
                var templateQc = new Template
                {
                    Id = templateQcId,
                    Title = "QC Scored Audit Live",
                    Type = "QC",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateQc);

                var templateGeneral = new Template
                {
                    Id = templateGeneralId,
                    Title = "General Tasks Live",
                    Type = "General",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateGeneral);

                // Stores in the same province
                var storeQc = new Store
                {
                    Id = storeQCId,
                    Name = $"QC Store Live {Guid.NewGuid():N}",
                    Address2 = new StoreAddress { Province = uniqueProvince },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeQc);

                var storeGeneral = new Store
                {
                    Id = storeGeneralId,
                    Name = $"General Store Live {Guid.NewGuid():N}",
                    Address2 = new StoreAddress { Province = uniqueProvince },
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeGeneral);

                // Submissions
                var submA = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeQCId,
                    TemplateId = templateQcId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 85.0m,
                    TemplateType = "QC",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submA);

                var submB = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeGeneralId,
                    TemplateId = templateGeneralId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 92.0m,
                    TemplateType = "General",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submB);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod?province={uniqueProvince}");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();

            // Assert dynamic live calculations
            var topStores = json.GetProperty("topStores");
            bool qcStoreFound = false;
            bool generalStoreFound = false;

            for (int i = 0; i < topStores.GetArrayLength(); i++)
            {
                var storeId = Guid.Parse(topStores[i].GetProperty("storeId").GetString()!);
                if (storeId == storeQCId) qcStoreFound = true;
                if (storeId == storeGeneralId) generalStoreFound = true;
            }

            Assert.True(qcStoreFound, "Expected the QC template store to be present in live topStores.");
            Assert.False(generalStoreFound, "Expected the General template store to be excluded from live topStores.");
        }
    }
}
