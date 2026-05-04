using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")]
public class CreateSubmissionDirectTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public CreateSubmissionDirectTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateSubmission_StatusCompleted_TriggersSectionScoresAndAnalytics()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "createcomp@test.com", "Aa1234567@", "Create Test", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Direct Completes", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Direct Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 100m,
            SectionScores = "{\"Section 1\":{\"score\":10,\"maxScore\":10}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            throw new Exception($"Request failed with {response.StatusCode} and body: {contentString}");
        }
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        // Verify that the SectionScoreExploder ran
        var sectionScores = await db.SubmissionSectionScores
            .Where(s => s.SubmissionId == submissionId)
            .ToListAsync();

        Assert.Single(sectionScores);
        Assert.Equal("Section 1", sectionScores[0].SectionTitle);
        Assert.Equal(10m, sectionScores[0].Score);

        // Verify that the StoreAnalyticsUpdater ran
        var snapshot = await db.StoreAnalyticsSnapshots
            .FirstOrDefaultAsync(s => s.StoreId == storeId);

        Assert.NotNull(snapshot);
        Assert.Equal(1, snapshot.TotalAudits30d); // This direct submission is the first one
        Assert.Equal(100m, snapshot.LastAuditScore);
    }
}
