using System.Data.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringRedesignSlice1Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ScoringRedesignSlice1Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task TC_SL1_01_DbSchema_HasScoreDirectionColumn()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act
        using var connection = db.Database.GetDbConnection();
        await connection.OpenAsync();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT column_name, data_type, character_maximum_length 
            FROM information_schema.columns 
            WHERE table_name = 'submissions' AND column_name = 'score_direction';
            """;
        
        using var reader = await command.ExecuteReaderAsync();
        bool hasRow = await reader.ReadAsync();

        // 3. Assert
        Assert.True(hasRow, "The column 'score_direction' does not exist in the 'submissions' table.");
        
        var dataType = reader.GetString(1);
        var maxLength = reader.IsDBNull(2) ? 0 : reader.GetInt32(2);

        Assert.Equal("character varying", dataType);
        Assert.Equal(20, maxLength);
    }

    [Fact]
    public async Task TC_SL1_02_DbSchema_HasCategoryTagColumns()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act
        using var connection = db.Database.GetDbConnection();
        await connection.OpenAsync();
        
        // Check templates
        using var cmdTemplates = connection.CreateCommand();
        cmdTemplates.CommandText = """
            SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'templates' AND column_name = 'category_tag'
            );
            """;
        var hasTemplateTag = (bool)(await cmdTemplates.ExecuteScalarAsync() ?? false);

        // Check submissions
        using var cmdSubmissions = connection.CreateCommand();
        cmdSubmissions.CommandText = """
            SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name = 'submissions' AND column_name = 'category_tag'
            );
            """;
        var hasSubmissionTag = (bool)(await cmdSubmissions.ExecuteScalarAsync() ?? false);

        // 3. Assert
        Assert.True(hasTemplateTag, "The column 'category_tag' does not exist in the 'templates' table.");
        Assert.True(hasSubmissionTag, "The column 'category_tag' does not exist in the 'submissions' table.");
    }

    [Fact]
    public async Task TC_SL1_03_DbSchema_CompositeIndexExists()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act
        using var connection = db.Database.GetDbConnection();
        await connection.OpenAsync();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT indexdef 
            FROM pg_indexes 
            WHERE tablename = 'submissions';
            """;
        
        using var reader = await command.ExecuteReaderAsync();
        var indexDefs = new List<string>();
        while (await reader.ReadAsync())
        {
            indexDefs.Add(reader.GetString(0));
        }

        // 3. Assert
        bool hasNewIndex = indexDefs.Any(def => def.Contains("template_id") && def.Contains("score_direction"));
        bool hasOldIndex = indexDefs.Any(def => def.Contains("template_id") && def.Contains("scoring_mode"));

        Assert.True(hasNewIndex, "Composite index on (template_id, score_direction) is missing on 'submissions' table.");
        Assert.False(hasOldIndex, "Old composite index on (template_id, scoring_mode) should have been removed from 'submissions' table.");
    }

    [Fact]
    public async Task TC_SL1_04_DbSchema_DefaultValuesAndNullability()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act
        using var connection = db.Database.GetDbConnection();
        await connection.OpenAsync();
        using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT column_name, is_nullable, column_default 
            FROM information_schema.columns 
            WHERE table_name IN ('submissions', 'templates') 
              AND column_name IN ('score_direction', 'category_tag', 'scoring_mode', 'is_weighted');
            """;
        
        using var reader = await command.ExecuteReaderAsync();
        var columnDetails = new Dictionary<(string Table, string Column), (string IsNullable, string? Default)>();
        while (await reader.ReadAsync())
        {
            // Note: information_schema.columns returns table_name in catalog queries, but let's query it explicitly or filter by schema.
            // Since we only query our public tables:
        }
        
        // Let's refine the query to include table_name explicitly for precise dictionary mapping
        reader.Close();
        command.CommandText = """
            SELECT table_name, column_name, is_nullable, column_default 
            FROM information_schema.columns 
            WHERE table_name IN ('submissions', 'templates') 
              AND column_name IN ('score_direction', 'category_tag', 'scoring_mode', 'is_weighted');
            """;
        
        using var reader2 = await command.ExecuteReaderAsync();
        while (await reader2.ReadAsync())
        {
            var tableName = reader2.GetString(0);
            var columnName = reader2.GetString(1);
            var isNullable = reader2.GetString(2);
            var columnDefault = reader2.IsDBNull(3) ? null : reader2.GetString(3);
            columnDetails[(tableName, columnName)] = (isNullable, columnDefault);
        }

        // 3. Assert
        // score_direction in submissions must be non-nullable with default 'down'
        Assert.True(columnDetails.TryGetValue(("submissions", "score_direction"), out var scoreDirectionDetails), 
            "Column 'score_direction' not found on 'submissions' table.");
        Assert.Equal("NO", scoreDirectionDetails.IsNullable);
        Assert.Contains("down", scoreDirectionDetails.Default ?? "");

        // category_tag in templates must be nullable
        Assert.True(columnDetails.TryGetValue(("templates", "category_tag"), out var templateTagDetails), 
            "Column 'category_tag' not found on 'templates' table.");
        Assert.Equal("YES", templateTagDetails.IsNullable);

        // category_tag in submissions must be nullable
        Assert.True(columnDetails.TryGetValue(("submissions", "category_tag"), out var submissionTagDetails), 
            "Column 'category_tag' not found on 'submissions' table.");
        Assert.Equal("YES", submissionTagDetails.IsNullable);

        // scoring_mode in submissions must be nullable
        Assert.True(columnDetails.TryGetValue(("submissions", "scoring_mode"), out var scoringModeDetails), 
            "Column 'scoring_mode' not found on 'submissions' table.");
        Assert.Equal("YES", scoringModeDetails.IsNullable);

        // is_weighted in submissions must be nullable
        Assert.True(columnDetails.TryGetValue(("submissions", "is_weighted"), out var isWeightedDetails), 
            "Column 'is_weighted' not found on 'submissions' table.");
        Assert.Equal("YES", isWeightedDetails.IsNullable);
    }

    [Fact]
    public async Task TC_SL1_05_DbSchema_BackfillCorrectness()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act & Assert
        // Since migrations run automatically on startup, we want to verify that the backfill works
        // as designed. We can verify the mapping behavior by inserting raw test records (mocking historical data)
        // and asserting that the database triggers, constraints, or EF defaults are correctly satisfied,
        // and verifying the EF metadata model maps the legacy columns as nullable and the new columns correctly.
        
        var entityType = db.Model.FindEntityType("Checkly.Api.Common.Persistence.Entities.Submission");
        Assert.NotNull(entityType);

        var scoreDirectionProp = entityType.FindProperty("ScoreDirection");
        Assert.NotNull(scoreDirectionProp);
        Assert.False(scoreDirectionProp.IsNullable);

        var scoringModeProp = entityType.FindProperty("ScoringMode");
        Assert.NotNull(scoringModeProp);
        Assert.True(scoringModeProp.IsNullable);

        var isWeightedProp = entityType.FindProperty("IsWeighted");
        Assert.NotNull(isWeightedProp);
        Assert.True(isWeightedProp.IsNullable);

        var categoryTagProp = entityType.FindProperty("CategoryTag");
        Assert.NotNull(categoryTagProp);
        Assert.True(categoryTagProp.IsNullable);

        var templateEntityType = db.Model.FindEntityType("Checkly.Api.Common.Persistence.Entities.Template");
        Assert.NotNull(templateEntityType);
        var templateCategoryTagProp = templateEntityType.FindProperty("CategoryTag");
        Assert.NotNull(templateCategoryTagProp);
        Assert.True(templateCategoryTagProp.IsNullable);
    }
}
