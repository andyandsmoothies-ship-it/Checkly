using System;
using System.Collections.Generic;
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
    public class GetAreaBodReportTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public GetAreaBodReportTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public async Task GetAreaBodReport_Unauthenticated_ReturnsUnauthorized()
        {
            // AC-1.1: GIVEN an unauthenticated client WHEN calling GET /api/analytics/bod/area THEN returns 401 Unauthorized
            // Arrange
            var client = _factory.CreateClient();

            // Act
            var response = await client.GetAsync("/api/analytics/bod/area");

            // Assert
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }

        [Fact]
        public async Task GetAreaBodReport_Auditor_ReturnsForbidden()
        {
            // AC-1.2: GIVEN an auditor without analytics:area capability WHEN calling GET /api/analytics/bod/area THEN returns 403 Forbidden
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(
                baseClient, 
                $"auditor-{Guid.NewGuid()}@checkly.test", 
                "Auditor123!@", 
                "Auditor User", 
                "auditor"
            );
            var client = _factory.CreateAuthenticatedClient(token);

            // Act
            var response = await client.GetAsync("/api/analytics/bod/area");

            // Assert
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetAreaBodReport_NoStoreAssignments_ReturnsEmptyReport()
        {
            // AC-2.1: GIVEN an Area Manager with no store assignments WHEN calling GET /api/analytics/bod/area THEN returns 200 OK with zeroed KPIs and empty lists
            // Arrange
            var baseClient = _factory.CreateClient();
            var (token, _) = await _factory.RegisterUserAsync(
                baseClient, 
                $"am-empty-{Guid.NewGuid()}@checkly.test", 
                "Manager123!@", 
                "Area Manager Empty", 
                "area_manager"
            );
            var client = _factory.CreateAuthenticatedClient(token);

            // Act
            var response = await client.GetAsync("/api/analytics/bod/area");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var report = await response.Content.ReadFromJsonAsync<AreaBodResponse>();
            Assert.NotNull(report);
            Assert.True(report.IsLiveData);
            Assert.Equal(0, report.Kpis.TotalAudits);
            Assert.Equal(0m, report.Kpis.AvgScore);
            Assert.Equal(0m, report.Kpis.CompletionRate);
            Assert.Equal(0, report.Kpis.OpenActionPlans);
            Assert.Equal(0, report.Kpis.OverdueActionPlans);
            Assert.Equal(0, report.Kpis.ActiveStores);
            Assert.Equal(0, report.Kpis.TotalAuditors);
            Assert.Equal(0m, report.Kpis.AvgTtrDays);
            Assert.Null(report.GoldenStore);
            Assert.Empty(report.Trend);
            Assert.Empty(report.TopStores);
            Assert.Empty(report.BottomStores);
            Assert.Empty(report.Weaknesses);
            Assert.Empty(report.AuditorProductivity);
        }

        [Fact]
        public async Task GetAreaBodReport_MultipleStores_IsolatesTenancyAndCalculatesMetrics()
        {
            // AC-3.1: GIVEN an Area Manager assigned to Store A but not Store B
            // WHEN calling GET /api/analytics/bod/area
            // THEN metrics are calculated ONLY using Store A's data, completely isolating Store B
            
            // Arrange
            var baseClient = _factory.CreateClient();
            
            // Create Area Manager 1
            var (amToken1, amUserId1) = await _factory.RegisterUserAsync(
                baseClient, 
                $"am-isolated1-{Guid.NewGuid()}@checkly.test", 
                "Manager123!@", 
                "Area Manager One", 
                "area_manager"
            );
            var client1 = _factory.CreateAuthenticatedClient(amToken1);

            // Seed unique store records
            var storeAId = Guid.NewGuid();
            var storeBId = Guid.NewGuid();
            var templateId = Guid.NewGuid();
            var auditorId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // 1. Seed Stores
                var storeA = new Store 
                { 
                    Id = storeAId, 
                    Name = $"Store A-{Guid.NewGuid()}", 
                    IsActive = true,
                    Address2 = new StoreAddress { Province = "Hanoi" }
                };
                var storeB = new Store 
                { 
                    Id = storeBId, 
                    Name = $"Store B-{Guid.NewGuid()}", 
                    IsActive = true,
                    Address2 = new StoreAddress { Province = "Saigon" }
                };
                await db.Stores.AddRangeAsync(storeA, storeB);

                // 2. Assign Store A to Area Manager 1 (but not Store B)
                var assignment = new ProfileStoreAssignment
                {
                    ProfileId = amUserId1,
                    StoreId = storeAId,
                    CreatedAt = DateTimeOffset.UtcNow
                };
                await db.ProfileStoreAssignments.AddAsync(assignment);

                // 3. Seed Template
                var template = new Template
                {
                    Id = templateId,
                    Title = "Standard Quality Audit",
                    Type = "QC",
                    IsActive = true,
                    CreatedAt = DateTimeOffset.UtcNow
                };
                await db.Templates.AddAsync(template);

                // 4. Seed Submissions (last 30 days) for both Store A and Store B
                var completedAt = DateTimeOffset.UtcNow.AddDays(-5);
                var subA = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeAId,
                    TemplateId = templateId,
                    TemplateTitle = template.Title,
                    AuditorId = auditorId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "weighted",
                    TotalScore = 90.0m,
                    CompletedAt = completedAt,
                    CreatedAt = completedAt.AddHours(-1)
                };

                var subB = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeBId,
                    TemplateId = templateId,
                    TemplateTitle = template.Title,
                    AuditorId = auditorId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "weighted",
                    TotalScore = 75.0m,
                    CompletedAt = completedAt,
                    CreatedAt = completedAt.AddHours(-1)
                };

                await db.Submissions.AddRangeAsync(subA, subB);

                // 5. Seed Submission Section Score for Store A (to calculate weaknesses)
                var sectionScore = new SubmissionSectionScore
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = subA.Id,
                    StoreId = storeAId,
                    SectionTitle = "Safety & Hygiene",
                    Score = 8.0m,
                    MaxScore = 10.0m,
                    CreatedAt = completedAt
                };
                await db.SubmissionSectionScores.AddAsync(sectionScore);

                // 6. Seed Action Plans for Store A and Store B
                var apA = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeAId,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    Deadline = DateTimeOffset.UtcNow.AddDays(5)
                };
                var apB = new ActionPlan
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeBId,
                    Status = "open",
                    CreatedAt = DateTimeOffset.UtcNow.AddDays(-2),
                    Deadline = DateTimeOffset.UtcNow.AddDays(5)
                };
                await db.ActionPlans.AddRangeAsync(apA, apB);

                await db.SaveChangesAsync();
            }

            // Act
            var response = await client1.GetAsync("/api/analytics/bod/area");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var report = await response.Content.ReadFromJsonAsync<AreaBodResponse>();
            Assert.NotNull(report);
            
            // Tenants metrics must isolate Store B's data completely
            Assert.Equal(1, report.Kpis.TotalAudits); // only subA
            Assert.Equal(90.0m, report.Kpis.AvgScore); // subA score
            Assert.Equal(1, report.Kpis.OpenActionPlans); // only apA
            Assert.Equal(1, report.Kpis.ActiveStores); // only storeA is active and assigned
            Assert.Equal(1, report.Kpis.TotalAuditors); // auditorId is distinct auditor
            
            Assert.NotNull(report.GoldenStore);
            Assert.Equal(90.0m, report.GoldenStore.AvgScore);
            
            Assert.Single(report.TopStores);
            Assert.Equal(storeAId, report.TopStores[0].StoreId);
            Assert.Equal(90.0m, report.TopStores[0].AvgScore);
            
            Assert.Empty(report.BottomStores); // BottomStores does not duplicate if there is only 1 store (or has correct sorting)
            
            Assert.Single(report.Weaknesses);
            Assert.Equal("Safety & Hygiene", report.Weaknesses[0].CategoryName);
            Assert.Equal(80.0m, report.Weaknesses[0].AvgScore); // 8 / 10 * 100% = 80%
        }

        [Fact]
        public async Task GetAreaBodReport_GapAC1_ReviewStatusNullAndApproved_IncludesCorrectSubmissions()
        {
            // Gap AC 1: PostgreSQL Null Inequality in Review Status
            // Verify that submissions with ReviewStatus = null and ReviewStatus = "approved" are included,
            // while those with ReviewStatus = "rejected" are excluded.
            
            // Arrange
            var baseClient = _factory.CreateClient();
            var (amToken, amUserId) = await _factory.RegisterUserAsync(
                baseClient, 
                $"am-gap1-{Guid.NewGuid()}@checkly.test", 
                "Manager123!@", 
                "Area Manager Gap One", 
                "area_manager"
            );
            var client = _factory.CreateAuthenticatedClient(amToken);

            var storeId = Guid.NewGuid();
            var templateId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Seed Store and assignment
                await db.Stores.AddAsync(new Store { Id = storeId, Name = $"Store Gap 1", IsActive = true });
                await db.ProfileStoreAssignments.AddAsync(new ProfileStoreAssignment
                {
                    ProfileId = amUserId,
                    StoreId = storeId,
                    CreatedAt = DateTimeOffset.UtcNow
                });

                // Seed Template
                await db.Templates.AddAsync(new Template { Id = templateId, Title = "QC Template", Type = "QC", IsActive = true });

                // Seed three submissions with different ReviewStatus
                var baseTime = DateTimeOffset.UtcNow.AddDays(-5);
                var subNullReview = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = templateId,
                    Status = "completed",
                    ReviewStatus = null, // null/unreviewed
                    ScoringMode = "weighted",
                    TotalScore = 80.0m,
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                var subApprovedReview = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = templateId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "weighted",
                    TotalScore = 90.0m,
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                var subRejectedReview = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = templateId,
                    Status = "completed",
                    ReviewStatus = "rejected", // should be excluded
                    ScoringMode = "weighted",
                    TotalScore = 50.0m,
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                await db.Submissions.AddRangeAsync(subNullReview, subApprovedReview, subRejectedReview);
                await db.SaveChangesAsync();
            }

            // Act
            var response = await client.GetAsync("/api/analytics/bod/area");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var report = await response.Content.ReadFromJsonAsync<AreaBodResponse>();
            Assert.NotNull(report);

            // TotalAudits should be 2 (null + approved), excluding the rejected one
            Assert.Equal(2, report.Kpis.TotalAudits);
            // AvgScore should be (80 + 90) / 2 = 85.0
            Assert.Equal(85.0m, report.Kpis.AvgScore);
        }

        [Fact]
        public async Task GetAreaBodReport_GapAC2_ExcludesSurveySubmissionsAndNonQCTemplates()
        {
            // Gap AC 2: Exclude survey scoring mode and non-QC templates in leaderboards
            // Verify that submissions with ScoringMode = "survey" are excluded from core metrics,
            // and templates of type = "survey" (not "QC") are excluded from leaderboards.
            
            // Arrange
            var baseClient = _factory.CreateClient();
            var (amToken, amUserId) = await _factory.RegisterUserAsync(
                baseClient, 
                $"am-gap2-{Guid.NewGuid()}@checkly.test", 
                "Manager123!@", 
                "Area Manager Gap Two", 
                "area_manager"
            );
            var client = _factory.CreateAuthenticatedClient(amToken);

            var storeId = Guid.NewGuid();
            var qcTemplateId = Guid.NewGuid();
            var surveyTemplateId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Seed Store and assignment
                await db.Stores.AddAsync(new Store { Id = storeId, Name = $"Store Gap 2", IsActive = true });
                await db.ProfileStoreAssignments.AddAsync(new ProfileStoreAssignment
                {
                    ProfileId = amUserId,
                    StoreId = storeId,
                    CreatedAt = DateTimeOffset.UtcNow
                });

                // Seed Templates
                await db.Templates.AddAsync(new Template { Id = qcTemplateId, Title = "QC Template", Type = "QC", IsActive = true });
                await db.Templates.AddAsync(new Template { Id = surveyTemplateId, Title = "Survey Template", Type = "survey", IsActive = true });

                // Seed QC submission
                var baseTime = DateTimeOffset.UtcNow.AddDays(-5);
                var subQc = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = qcTemplateId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "weighted",
                    TotalScore = 95.0m,
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                // Seed Survey scoring mode submission
                var subSurveyMode = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = qcTemplateId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "survey", // should be excluded from core metrics
                    TotalScore = 60.0m,
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                // Seed Non-QC template submission
                var subSurveyTemplate = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeId,
                    TemplateId = surveyTemplateId,
                    Status = "completed",
                    ReviewStatus = "approved",
                    ScoringMode = "weighted",
                    TotalScore = 40.0m, // should be excluded from leaderboard since template.Type != "QC"
                    CompletedAt = baseTime,
                    CreatedAt = baseTime.AddHours(-1)
                };

                await db.Submissions.AddRangeAsync(subQc, subSurveyMode, subSurveyTemplate);
                await db.SaveChangesAsync();
            }

            // Act
            var response = await client.GetAsync("/api/analytics/bod/area");

            // Assert
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
            }

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var report = await response.Content.ReadFromJsonAsync<AreaBodResponse>();
            Assert.NotNull(report);

            // TotalAudits in core metrics excludes subSurveyMode, but wait! Does it exclude subSurveyTemplate?
            // Yes, core metrics: s.ScoringMode != "survey". subSurveyTemplate has ScoringMode = "weighted", so it's included in total audits (1 + 1 = 2)
            Assert.Equal(2, report.Kpis.TotalAudits);
            // Leaderboard excludes non-QC template subSurveyTemplate.
            // So leaderboard should only have subQc score (95.0) for Store Gap 2
            Assert.Single(report.TopStores);
            Assert.Equal(storeId, report.TopStores[0].StoreId);
            Assert.Equal(95.0m, report.TopStores[0].AvgScore);
        }
    }
}
