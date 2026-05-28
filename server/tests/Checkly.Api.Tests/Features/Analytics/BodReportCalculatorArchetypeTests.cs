using System;
using System.Linq;
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
    public class BodReportCalculatorArchetypeTests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        public BodReportCalculatorArchetypeTests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public async Task ComputeDailyReport_QCStore_IncludedInTopBottomCalculation()
        {
            // Arrange
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var templateQcId = Guid.NewGuid();
            var storeQCId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Template
                var templateQc = new Template
                {
                    Id = templateQcId,
                    Title = "QC Audit",
                    Type = "QC",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateQc);

                // Store
                var storeQc = new Store
                {
                    Id = storeQCId,
                    Name = $"QC Calc Store {Guid.NewGuid():N}",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeQc);

                // Submission
                var submA = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeQCId,
                    TemplateId = templateQcId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 88.5m,
                    TemplateType = "QC",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submA);

                await db.SaveChangesAsync();

                // Act
                var calculator = new BodReportCalculator();
                var payloadJson = await calculator.ComputeDailyReportWithTimezoneAsync(db, today, "Asia/Ho_Chi_Minh", CancellationToken.None);

                // Assert
                var json = JsonDocument.Parse(payloadJson);
                var topStores = json.RootElement.GetProperty("topStores");
                bool qcStoreFound = false;

                for (int i = 0; i < topStores.GetArrayLength(); i++)
                {
                    var storeIdStr = topStores[i].GetProperty("storeId").GetString();
                    if (!string.IsNullOrEmpty(storeIdStr) && Guid.Parse(storeIdStr) == storeQCId)
                    {
                        qcStoreFound = true;
                        break;
                    }
                }

                Assert.True(qcStoreFound, "Expected QC store to be included in nightly leaderboard calculations.");
            }
        }

        [Fact]
        public async Task ComputeDailyReport_GeneralStore_ExcludedFromTopBottomCalculation()
        {
            // Arrange
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var templateGeneralId = Guid.NewGuid();
            var storeGeneralId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Template
                var templateGeneral = new Template
                {
                    Id = templateGeneralId,
                    Title = "General Tasks Audit",
                    Type = "General",
                    IsActive = true,
                    Version = 1,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Templates.Add(templateGeneral);

                // Store
                var storeGeneral = new Store
                {
                    Id = storeGeneralId,
                    Name = $"General Calc Store {Guid.NewGuid():N}",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeGeneral);

                // Submission
                var submB = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeGeneralId,
                    TemplateId = templateGeneralId,
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 95.0m,
                    TemplateType = "General",
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submB);

                await db.SaveChangesAsync();

                // Act
                var calculator = new BodReportCalculator();
                var payloadJson = await calculator.ComputeDailyReportWithTimezoneAsync(db, today, "Asia/Ho_Chi_Minh", CancellationToken.None);

                // Assert
                var json = JsonDocument.Parse(payloadJson);
                var topStores = json.RootElement.GetProperty("topStores");
                var bottomStores = json.RootElement.GetProperty("bottomStores");
                
                bool generalStoreFound = false;

                for (int i = 0; i < topStores.GetArrayLength(); i++)
                {
                    var storeIdStr = topStores[i].GetProperty("storeId").GetString();
                    if (!string.IsNullOrEmpty(storeIdStr) && Guid.Parse(storeIdStr) == storeGeneralId)
                    {
                        generalStoreFound = true;
                    }
                }

                for (int i = 0; i < bottomStores.GetArrayLength(); i++)
                {
                    var storeIdStr = bottomStores[i].GetProperty("storeId").GetString();
                    if (!string.IsNullOrEmpty(storeIdStr) && Guid.Parse(storeIdStr) == storeGeneralId)
                    {
                        generalStoreFound = true;
                    }
                }

                Assert.False(generalStoreFound, "Expected General template store to be excluded from nightly leaderboard calculations.");
            }
        }

        [Fact]
        public async Task ComputeDailyReport_NullTemplateId_TreatedAsQCFallback()
        {
            // Arrange
            var today = DateOnly.FromDateTime(DateTime.UtcNow);
            var storeNullId = Guid.NewGuid();

            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

                // Store
                var storeNull = new Store
                {
                    Id = storeNullId,
                    Name = $"Null Template Store {Guid.NewGuid():N}",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Stores.Add(storeNull);

                // Submission (Null TemplateId)
                var submNull = new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = storeNullId,
                    TemplateId = null, // Null to trigger legacy/missing fallback
                    Status = "completed",
                    ScoringMode = "penalty",
                    TotalScore = 87.0m,
                    TemplateType = null,
                    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
                    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2),
                    UpdatedAt = DateTimeOffset.UtcNow
                };
                db.Submissions.Add(submNull);

                await db.SaveChangesAsync();

                // Act
                var calculator = new BodReportCalculator();
                var payloadJson = await calculator.ComputeDailyReportWithTimezoneAsync(db, today, "Asia/Ho_Chi_Minh", CancellationToken.None);

                // Assert
                var json = JsonDocument.Parse(payloadJson);
                var topStores = json.RootElement.GetProperty("topStores");
                bool nullTemplateStoreFound = false;

                for (int i = 0; i < topStores.GetArrayLength(); i++)
                {
                    var storeIdStr = topStores[i].GetProperty("storeId").GetString();
                    if (!string.IsNullOrEmpty(storeIdStr) && Guid.Parse(storeIdStr) == storeNullId)
                    {
                        nullTemplateStoreFound = true;
                        break;
                    }
                }

                Assert.True(nullTemplateStoreFound, "Expected submission with null TemplateId to be treated as QC and included in top/bottom calculations.");
            }
        }
    }
}
