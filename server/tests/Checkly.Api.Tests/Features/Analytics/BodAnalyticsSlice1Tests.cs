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
    public class BodAnalyticsSlice1Tests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodAnalyticsSlice1Tests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public async Task GetStoreBodSummary_AsAdmin_ReturnsStoreSummary()
        {
            // TC-S1-TEST-01 & TC-S1-TEST-03
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid storeId = Guid.NewGuid();
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "Store BOD Test Store",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);

                // Seed 7 completed audits/submissions
                for (int i = 1; i <= 7; i++)
                {
                    var submission = new Submission
                    {
                        Id = Guid.NewGuid(),
                        StoreId = storeId,
                        StoreName = "Store BOD Test Store",
                        AuditorId = Guid.NewGuid(),
                        AuditorName = $"Auditor {i}",
                        Status = "completed",
                        TotalScore = 80.0m + i,
                        // Incrementing CompletedAt so we can assert ordering
                        CompletedAt = DateTimeOffset.UtcNow.AddHours(i),
                        CreatedAt = DateTimeOffset.UtcNow.AddHours(i),
                        UpdatedAt = DateTimeOffset.UtcNow.AddHours(i)
                    };
                    db.Submissions.Add(submission);

                    // Seed some category scores for these submissions
                    db.SubmissionSectionScores.Add(new SubmissionSectionScore
                    {
                        Id = Guid.NewGuid(),
                        SubmissionId = submission.Id,
                        StoreId = storeId,
                        SectionTitle = "Food Safety",
                        Score = 80.0m + i,
                        MaxScore = 100.0m,
                        IsCcpFailed = i % 3 == 0, // Failure count will be checked
                        CreatedAt = DateTimeOffset.UtcNow.AddHours(i)
                    });
                }

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
            Assert.Equal("Store BOD Test Store", json.GetProperty("storeName").GetString());

            var recentAudits = json.GetProperty("recentAudits");
            Assert.Equal(JsonValueKind.Array, recentAudits.ValueKind);
            // Cap at 5 audits
            Assert.Equal(5, recentAudits.GetArrayLength());

            // Order by date DESC (audit 7 is the newest, then 6, 5, 4, 3)
            var newestAudit = recentAudits[0];
            Assert.Equal(87.0m, newestAudit.GetProperty("score").GetDecimal());
            Assert.Equal("Auditor 7", newestAudit.GetProperty("auditorName").GetString());

            var secondNewest = recentAudits[1];
            Assert.Equal(86.0m, secondNewest.GetProperty("score").GetDecimal());
            Assert.Equal("Auditor 6", secondNewest.GetProperty("auditorName").GetString());

            var categoryBreakdown = json.GetProperty("categoryBreakdown");
            Assert.Equal(JsonValueKind.Array, categoryBreakdown.ValueKind);
            Assert.True(categoryBreakdown.GetArrayLength() > 0);

            var foodSafetySection = categoryBreakdown[0];
            Assert.Equal("Food Safety", foodSafetySection.GetProperty("categoryName").GetString());
            // Total score is Sum(81..87) = 588. Max score is 700. Average is 84%
            Assert.True(foodSafetySection.GetProperty("avgScore").GetDecimal() > 0);
        }

        [Fact]
        public async Task GetStoreBodSummary_AsAuditor_ReturnsForbidden()
        {
            // TC-S1-TEST-01: Capability Guard
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(baseClient, "auditor-bod@checkly.test", "Auditor123!@", "Auditor BOD User", "auditor");
            var auditorClient = _factory.CreateAuthenticatedClient(token);

            Guid storeId = Guid.NewGuid();

            // Act
            var response = await auditorClient.GetAsync($"/api/analytics/stores/{storeId}/bod-summary");

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetStoreBodSummary_EmptyStore_Returns200WithEmptyLists()
        {
            // TC-S1-TEST-04
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid storeId = Guid.NewGuid();
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                var store = new Store
                {
                    Id = storeId,
                    Name = "Empty BOD Test Store",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(store);
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
            Assert.Equal("Empty BOD Test Store", json.GetProperty("storeName").GetString());
            Assert.Equal(0, json.GetProperty("recentAudits").GetArrayLength());
            Assert.Equal(0, json.GetProperty("categoryBreakdown").GetArrayLength());
        }

        [Fact]
        public async Task GetStoreBodSummary_NonExistentStore_ReturnsNotFound()
        {
            // TC-S1-TEST-04 (Gap 1): Non-existent store ID returns NotFound
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            Guid nonExistentStoreId = Guid.NewGuid();

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/stores/{nonExistentStoreId}/bod-summary");

            // Assert
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }

        [Fact]
        public async Task GetCategoryDetail_AsAdmin_ReturnsCategoryDetails()
        {
            // TC-S1-TEST-02 & TC-S1-TEST-05 & TC-S1-TEST-06
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            string categoryName = $"Category-{Guid.NewGuid():N}";

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Seed stores and section scores
                // Store A: Average score 95%
                var storeA = new Store { Id = Guid.NewGuid(), Name = "Worst Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                // Store B: Average score 60%
                var storeB = new Store { Id = Guid.NewGuid(), Name = "Worst Store B", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                // Store C: Average score 80%
                var storeC = new Store { Id = Guid.NewGuid(), Name = "Worst Store C", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

                db.Stores.AddRange(storeA, storeB, storeC);

                var subA = new Submission { Id = Guid.NewGuid(), StoreId = storeA.Id, StoreName = "Worst Store A", Status = "completed", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                var subB = new Submission { Id = Guid.NewGuid(), StoreId = storeB.Id, StoreName = "Worst Store B", Status = "completed", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
                var subC = new Submission { Id = Guid.NewGuid(), StoreId = storeC.Id, StoreName = "Worst Store C", Status = "completed", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

                db.Submissions.AddRange(subA, subB, subC);

                // Section scores: Store A (95%)
                db.SubmissionSectionScores.Add(new SubmissionSectionScore
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = subA.Id,
                    StoreId = storeA.Id,
                    SectionTitle = categoryName,
                    Score = 95.0m,
                    MaxScore = 100.0m,
                    IsCcpFailed = false,
                    CreatedAt = DateTimeOffset.UtcNow
                });

                // Section scores: Store B (60%)
                db.SubmissionSectionScores.Add(new SubmissionSectionScore
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = subB.Id,
                    StoreId = storeB.Id,
                    SectionTitle = categoryName,
                    Score = 60.0m,
                    MaxScore = 100.0m,
                    IsCcpFailed = true,
                    CreatedAt = DateTimeOffset.UtcNow
                });

                // Section scores: Store C (80%)
                db.SubmissionSectionScores.Add(new SubmissionSectionScore
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = subC.Id,
                    StoreId = storeC.Id,
                    SectionTitle = categoryName,
                    Score = 80.0m,
                    MaxScore = 100.0m,
                    IsCcpFailed = false,
                    CreatedAt = DateTimeOffset.UtcNow
                });

                await db.SaveChangesAsync();
            }

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod/category/{Uri.EscapeDataString(categoryName)}");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(JsonValueKind.Array, json.ValueKind);
            Assert.Equal(3, json.GetArrayLength());

            // Worst first sorting (Store B: 60%, Store C: 80%, Store A: 95%)
            Assert.Equal("Worst Store B", json[0].GetProperty("storeName").GetString());
            Assert.Equal(60.0m, json[0].GetProperty("avgScore").GetDecimal());
            Assert.Equal(1, json[0].GetProperty("failureCount").GetInt32());

            Assert.Equal("Worst Store C", json[1].GetProperty("storeName").GetString());
            Assert.Equal(80.0m, json[1].GetProperty("avgScore").GetDecimal());
            Assert.Equal(0, json[1].GetProperty("failureCount").GetInt32());

            Assert.Equal("Worst Store A", json[2].GetProperty("storeName").GetString());
            Assert.Equal(95.0m, json[2].GetProperty("avgScore").GetDecimal());
            Assert.Equal(0, json[2].GetProperty("failureCount").GetInt32());
        }

        [Fact]
        public async Task GetCategoryDetail_AsAuditor_ReturnsForbidden()
        {
            // TC-S1-TEST-02: Capability Guard
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(baseClient, "auditor-cat@checkly.test", "Auditor123!@", "Auditor Category User", "auditor");
            var auditorClient = _factory.CreateAuthenticatedClient(token);

            string categoryName = "Food Safety";

            // Act
            var response = await auditorClient.GetAsync($"/api/analytics/bod/category/{Uri.EscapeDataString(categoryName)}");

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetCategoryDetail_EmptyCategory_Returns200WithEmptyList()
        {
            // TC-S1-TEST-06 (No data matches)
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            string randomCategory = $"NonExistentCategory-{Guid.NewGuid():N}";

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod/category/{Uri.EscapeDataString(randomCategory)}");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            Assert.Equal(JsonValueKind.Array, json.ValueKind);
            Assert.Equal(0, json.GetArrayLength());
        }

        [Fact]
        public async Task GetCategoryDetail_InvalidName_ReturnsBadRequest()
        {
            // TC-S1-TEST-06 (Gap 2): Whitespace or invalid category name returns BadRequest
            // Arrange
            var client = _factory.CreateClient();
            var adminToken = await _factory.LoginBootstrapAdminAsync(client);
            var adminClient = _factory.CreateAuthenticatedClient(adminToken);

            string invalidCategory = "   ";

            // Act
            var response = await adminClient.GetAsync($"/api/analytics/bod/category/{Uri.EscapeDataString(invalidCategory)}");

            // Assert
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }

        [Fact]
        public async Task DumpRealDatabaseContent()
        {
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@");
            using var db = new AppDbContext(optionsBuilder.Options);

            var sections = await db.SubmissionSectionScores
                .Select(x => new { x.SectionTitle, x.Score, x.MaxScore, x.SubmissionId })
                .ToListAsync();

            var submissions = await db.Submissions
                .Select(x => new { x.Id, x.Status, x.StoreName, x.TotalScore })
                .ToListAsync();

            var message = $"SECTIONS ({sections.Count}):\n" + 
                          string.Join("\n", sections.Select(s => $"- Title: '{s.SectionTitle}', Score: {s.Score}, MaxScore: {s.MaxScore}, SubmissionId: {s.SubmissionId}")) +
                          $"\n\nSUBMISSIONS ({submissions.Count}):\n" +
                          string.Join("\n", submissions.Select(s => $"- Id: {s.Id}, Status: '{s.Status}', Store: '{s.StoreName}', Score: {s.TotalScore}"));

            Assert.Fail(message);
        }
    }
}
