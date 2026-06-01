using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Analytics
{
    [Collection("Sequential")]
    public class BodLiveQueries_Slice2_Tests : IClassFixture<TestWebApplicationFactory>
    {
        private readonly TestWebApplicationFactory _factory;

        private const string StatusProperty = "Status";
        private const string CompletedAtProperty = "CompletedAt";
        private const string StoreIdProperty = "StoreId";
        private const string CreatedAtProperty = "CreatedAt";
        private const string DeadlineProperty = "Deadline";

        public BodLiveQueries_Slice2_Tests(TestWebApplicationFactory factory)
        {
            _factory = factory;
            _factory.EnsureDatabaseCreated();
        }

        [Fact]
        public void VerifyEfCoreModel_SubmissionsIndexes_ExistAndAreNonUnique()
        {
            // AC-GAP-1: Assert that composite indexes exist in EF Core metadata and are non-unique
            // Arrange
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var model = Microsoft.EntityFrameworkCore.Infrastructure.AccessorExtensions.GetService<Microsoft.EntityFrameworkCore.Metadata.IDesignTimeModel>(db).Model;
            var submissionType = model.FindEntityType(typeof(Submission));

            Assert.NotNull(submissionType);

            // Index 1: { Status, CompletedAt } (CompletedAt DESC)
            var statusProp = submissionType.FindProperty(StatusProperty);
            var completedAtProp = submissionType.FindProperty(CompletedAtProperty);

            Assert.NotNull(statusProp);
            Assert.NotNull(completedAtProp);

            var index1 = submissionType.FindIndex(new[] { statusProp, completedAtProp });
            Assert.True(index1 != null, "Composite index on { Status, CompletedAt } was not found in EF Core metadata.");
            Assert.False(index1.IsUnique, "Index on { Status, CompletedAt } must not be unique.");
            Assert.NotNull(index1.IsDescending);
            Assert.Equal(2, index1.IsDescending.Count);
            Assert.False(index1.IsDescending[0], "First column (Status) should be ascending.");
            Assert.True(index1.IsDescending[1], "Second column (CompletedAt) should be descending.");

            // Index 2: { Status, StoreId, CompletedAt }
            var storeIdProp = submissionType.FindProperty(StoreIdProperty);
            Assert.NotNull(storeIdProp);

            var index2 = submissionType.FindIndex(new[] { statusProp, storeIdProp, completedAtProp });
            Assert.True(index2 != null, "Composite index on { Status, StoreId, CompletedAt } was not found in EF Core metadata.");
            Assert.False(index2.IsUnique, "Index on { Status, StoreId, CompletedAt } must not be unique.");
        }

        [Fact]
        public void VerifyEfCoreModel_SubmissionSectionScoresIndex_ExistsAndIsNonUnique()
        {
            // AC-GAP-1: Assert that composite indexes exist in EF Core metadata and are non-unique
            // Arrange
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var model = db.Model;
            var sectionScoreType = model.FindEntityType(typeof(SubmissionSectionScore));

            Assert.NotNull(sectionScoreType);

            // Index 3: { CreatedAt, StoreId }
            var createdAtProp = sectionScoreType.FindProperty(CreatedAtProperty);
            var storeIdProp = sectionScoreType.FindProperty(StoreIdProperty);

            Assert.NotNull(createdAtProp);
            Assert.NotNull(storeIdProp);

            var index3 = sectionScoreType.FindIndex(new[] { createdAtProp, storeIdProp });
            Assert.True(index3 != null, "Composite index on { CreatedAt, StoreId } was not found in EF Core metadata on SubmissionSectionScore.");
            Assert.False(index3.IsUnique, "Index on { CreatedAt, StoreId } must not be unique.");
        }

        [Fact]
        public void VerifyEfCoreModel_ActionPlansIndex_ExistsAndIsNonUnique()
        {
            // AC-GAP-1: Assert that composite indexes exist in EF Core metadata and are non-unique
            // Arrange
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var model = db.Model;
            var actionPlanType = model.FindEntityType(typeof(ActionPlan));

            Assert.NotNull(actionPlanType);

            // Index 4: { Status, Deadline }
            var statusProp = actionPlanType.FindProperty(StatusProperty);
            var deadlineProp = actionPlanType.FindProperty(DeadlineProperty);

            Assert.NotNull(statusProp);
            Assert.NotNull(deadlineProp);

            var index4 = actionPlanType.FindIndex(new[] { statusProp, deadlineProp });
            Assert.True(index4 != null, "Composite index on { Status, Deadline } was not found in EF Core metadata on ActionPlan.");
            Assert.False(index4.IsUnique, "Index on { Status, Deadline } must not be unique.");
        }

        [Fact]
        public async Task VerifyPostgresCatalog_IndexesExist()
        {
            // AC-GAP-2: Assert index existence directly in PostgreSQL catalog tables to guarantee migration scripts are applied correctly
            // Arrange
            using var scope = _factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            using var conn = db.Database.GetDbConnection();
            await conn.OpenAsync();

            using var cmd = conn.CreateCommand();
            cmd.CommandText = @"
                SELECT 
                    t.relname AS table_name,
                    i.relname AS index_name,
                    pg_get_indexdef(ix.indexrelid) AS index_def
                FROM pg_class t
                JOIN pg_index ix ON t.oid = ix.indrelid
                JOIN pg_class i ON i.oid = ix.indexrelid
                WHERE t.relname IN ('submissions', 'submission_section_scores', 'action_plans');";

            var indexes = new List<(string TableName, string IndexName, string IndexDef)>();
            using (var reader = await cmd.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    indexes.Add((
                        reader.GetString(0),
                        reader.GetString(1),
                        reader.GetString(2)
                    ));
                }
            }

            // Assert that the physical database indexes exist and contain the required column patterns
            var submissionsIndexes = indexes.Where(x => x.TableName == "submissions").ToList();
            var sectionScoresIndexes = indexes.Where(x => x.TableName == "submission_section_scores").ToList();
            var actionPlansIndexes = indexes.Where(x => x.TableName == "action_plans").ToList();

            // 1. submissions: status + completed_at DESC
            var hasStatusCompletedAtDesc = submissionsIndexes.Any(x => 
                x.IndexDef.Contains("status") && 
                x.IndexDef.Contains("completed_at") && 
                x.IndexDef.Contains("DESC"));
            Assert.True(hasStatusCompletedAtDesc, "Physical index for submissions { status, completed_at DESC } was not found in PostgreSQL catalog.");

            // 2. submissions: status + store_id + completed_at
            var hasStatusStoreIdCompletedAt = submissionsIndexes.Any(x => 
                x.IndexDef.Contains("status") && 
                x.IndexDef.Contains("store_id") && 
                x.IndexDef.Contains("completed_at"));
            Assert.True(hasStatusStoreIdCompletedAt, "Physical index for submissions { status, store_id, completed_at } was not found in PostgreSQL catalog.");

            // 3. submission_section_scores: created_at + store_id
            var hasCreatedAtStoreId = sectionScoresIndexes.Any(x => 
                x.IndexDef.Contains("created_at") && 
                x.IndexDef.Contains("store_id"));
            Assert.True(hasCreatedAtStoreId, "Physical index for submission_section_scores { created_at, store_id } was not found in PostgreSQL catalog.");

            // 4. action_plans: status + deadline
            var hasStatusDeadline = actionPlansIndexes.Any(x => 
                x.IndexDef.Contains("status") && 
                x.IndexDef.Contains("deadline"));
            Assert.True(hasStatusDeadline, "Physical index for action_plans { status, deadline } was not found in PostgreSQL catalog.");
        }
    }
}
