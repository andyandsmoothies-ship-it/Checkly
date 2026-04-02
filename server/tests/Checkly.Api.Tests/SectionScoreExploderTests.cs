using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")] // Using sequential collection if it exists, otherwise just default
public class SectionScoreExploderTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public SectionScoreExploderTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Explode_AddsRowsToDbContext()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var submissionId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var templateId = Guid.NewGuid();
        var now = DateTimeOffset.UtcNow;
        
        var json = @"{
            ""Kitchen Hygiene"": { ""score"": 90, ""maxScore"": 100 },
            ""Staff Training"": { ""score"": 50, ""maxScore"": 50 }
        }";

        db.Templates.Add(new Common.Persistence.Entities.Template { Id = templateId, Title = "T", Version = 1 });
        db.Stores.Add(new Common.Persistence.Entities.Store { Id = storeId, Name = "S" });
        db.Submissions.Add(new Common.Persistence.Entities.Submission { Id = submissionId, TemplateId = templateId, StoreId = storeId, Status = "completed", TemplateTitle = "T" });
        await db.SaveChangesAsync();

        // Act
        await SectionScoreExploder.ExplodeAsync(submissionId, storeId, templateId, json, db, now, CancellationToken.None);
        await db.SaveChangesAsync();

        // Assert
        var scores = await db.SubmissionSectionScores
            .Where(s => s.SubmissionId == submissionId)
            .OrderBy(s => s.SectionTitle)
            .ToListAsync();

        Assert.Equal(2, scores.Count);
        
        Assert.Equal("Kitchen Hygiene", scores[0].SectionTitle);
        Assert.Equal(90m, scores[0].Score);
        Assert.Equal(100m, scores[0].MaxScore);
        Assert.Equal(0.9m, scores[0].Ratio);
        
        Assert.Equal("Staff Training", scores[1].SectionTitle);
        Assert.Equal(50m, scores[1].Score);
        Assert.Equal(50m, scores[1].MaxScore);
        Assert.Equal(1.0m, scores[1].Ratio);
    }

    [Fact]
    public async Task Explode_SkipsOnMalformedJson()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var submissionId = Guid.NewGuid();
        var now = DateTimeOffset.UtcNow;
        
        var malformedJson = @"{ ""Kitchen Hygiene"": broken_json ";

        // Act
        await SectionScoreExploder.ExplodeAsync(submissionId, null, Guid.NewGuid(), malformedJson, db, now, CancellationToken.None);
        await db.SaveChangesAsync();

        // Assert
        var scoresCount = await db.SubmissionSectionScores
            .CountAsync(s => s.SubmissionId == submissionId);

        Assert.Equal(0, scoresCount);
    }
}
