using System;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
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
        public async Task GetApBucketDetail_WithValidBucket_ReturnsOpenActionPlans()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var uniqueProvince = $"ProvinceAP-{Guid.NewGuid():N}";
            Guid ap90Id;
            Guid ap30Id;

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "Action Plan Flagship Store",
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

                // Seed open Action Plan created 100 days ago (Bucket: 90d+)
                ap90Id = Guid.NewGuid();
                var ap90 = new ActionPlan
                {
                    Id = ap90Id,
                    StoreId = store.Id,
                    SubmissionId = submission.Id,
                    Status = "open",
                    CriteriaLabel = "Electrical Safety Compliance",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-100),
                    ClosedAt = null
                };
                db.ActionPlans.Add(ap90);

                // Seed open Action Plan created 10 days ago (Bucket: 0-30d)
                ap30Id = Guid.NewGuid();
                var ap30 = new ActionPlan
                {
                    Id = ap30Id,
                    StoreId = store.Id,
                    SubmissionId = submission.Id,
                    Status = "open",
                    CriteriaLabel = "Fire Alarm Systems Check",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-10),
                    ClosedAt = null
                };
                db.ActionPlans.Add(ap30);

                await db.SaveChangesAsync();
            }

            // Act: Query AP bucket drill-down for 90d+
            var response = await adminClient.GetAsync("/api/analytics/bod/ap/90d+");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(JsonValueKind.Array, json.ValueKind);

            // Verify that only the 90d+ action plan is returned
            bool found90 = false;
            bool found30 = false;

            foreach (var item in json.EnumerateArray())
            {
                var id = Guid.Parse(item.GetProperty("id").GetString()!);
                if (id == ap90Id)
                {
                    found90 = true;
                    Assert.Equal("Electrical Safety Compliance", item.GetProperty("criteriaLabel").GetString());
                    Assert.Equal("Action Plan Flagship Store", item.GetProperty("storeName").GetString());
                    Assert.True(item.GetProperty("ageInDays").GetInt32() >= 100, "Age in days should be calculated properly");
                }
                if (id == ap30Id)
                {
                    found30 = true;
                }
            }

            Assert.True(found90, "Expected open action plan from 90d+ bucket to be returned");
            Assert.False(found30, "Action plan from 0-30d bucket should not be returned in 90d+ endpoint");
        }

        [Fact]
        public async Task GetApBucketDetail_WithInvalidBucket_ReturnsBadRequest()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            // Act: Query with an invalid bucket name to trigger validation/bad request
            var response = await adminClient.GetAsync("/api/analytics/bod/ap/invalid_bucket_value");

            // Assert (Gap Analysis validation AC)
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }

        [Fact]
        public async Task GetAuditorProductivity_ReturnsAuditorsWithBiasCalibration()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            var strictAuditorId = Guid.NewGuid();
            var easyAuditorId = Guid.NewGuid();
            var balancedAuditorId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = Guid.NewGuid(),
                    Name = "Audit Center Store",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                // Seed strict auditor (Avg score = 75.0%)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    Status = "completed",
                    TotalScore = 75.0m,
                    AuditorId = strictAuditorId,
                    AuditorName = "Strict Auditor",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });

                // Seed easy auditor (Avg score = 95.0%)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    Status = "completed",
                    TotalScore = 95.0m,
                    AuditorId = easyAuditorId,
                    AuditorName = "Easy Auditor",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });

                // Seed balanced auditor (Avg score = 85.0%)
                db.Submissions.Add(new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store.Id,
                    Status = "completed",
                    TotalScore = 85.0m,
                    AuditorId = balancedAuditorId,
                    AuditorName = "Balanced Auditor",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync("/api/analytics/auditors/productivity");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(JsonValueKind.Array, json.ValueKind);

            bool strictChecked = false;
            bool easyChecked = false;
            bool balancedChecked = false;

            foreach (var auditor in json.EnumerateArray())
            {
                var auditorId = Guid.Parse(auditor.GetProperty("auditorId").GetString()!);
                if (auditorId == strictAuditorId)
                {
                    strictChecked = true;
                    Assert.Equal("Strict Auditor", auditor.GetProperty("auditorName").GetString());
                    Assert.Equal(1, auditor.GetProperty("completedAudits").GetInt32());
                    Assert.Equal(75.0m, auditor.GetProperty("avgScore").GetDecimal());
                    Assert.Equal("Strict", auditor.GetProperty("biasRating").GetString());
                }
                else if (auditorId == easyAuditorId)
                {
                    easyChecked = true;
                    Assert.Equal("Easy Auditor", auditor.GetProperty("auditorName").GetString());
                    Assert.Equal(1, auditor.GetProperty("completedAudits").GetInt32());
                    Assert.Equal(95.0m, auditor.GetProperty("avgScore").GetDecimal());
                    Assert.Equal("Generous", auditor.GetProperty("biasRating").GetString());
                }
                else if (auditorId == balancedAuditorId)
                {
                    balancedChecked = true;
                    Assert.Equal("Balanced Auditor", auditor.GetProperty("auditorName").GetString());
                    Assert.Equal(1, auditor.GetProperty("completedAudits").GetInt32());
                    Assert.Equal(85.0m, auditor.GetProperty("avgScore").GetDecimal());
                    Assert.Equal("Balanced", auditor.GetProperty("biasRating").GetString());
                }
            }

            Assert.True(strictChecked, "Strict Auditor not found or rated incorrectly");
            Assert.True(easyChecked, "Easy/Generous Auditor not found or rated incorrectly");
            Assert.True(balancedChecked, "Balanced Auditor not found or rated incorrectly");
        }

        [Fact]
        public async Task GetAuditorProductivity_ZeroSubmissions_Safeguard()
        {
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            // We do not seed any submissions. The database should be clear of submissions for this test instance.
            // Act
            var response = await adminClient.GetAsync("/api/analytics/auditors/productivity");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(JsonValueKind.Array, json.ValueKind);
            Assert.Equal(0, json.GetArrayLength()); // Should gracefully return an empty array with 0 errors
        }
    }
}
