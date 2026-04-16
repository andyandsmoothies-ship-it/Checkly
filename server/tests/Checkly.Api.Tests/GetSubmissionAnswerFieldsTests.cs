using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

public class GetSubmissionAnswerFieldsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GetSubmissionAnswerFieldsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetSubmission_ReturnsIsCcpAndIsRiskFlags_InAnswerDto()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (token, auditorId) = await _factory.RegisterUserAsync(
            client, "sdet-auditor@test.test", "Sdet123!@", "SDET Auditor", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);

        var submissionId = Guid.NewGuid();
        var criteriaId = Guid.NewGuid();

        var templateId = Guid.NewGuid();

        // Seed submission directly via DbContext
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var template = new Template { Id = templateId, Title = "TDD Template", Version = 1, IsActive = true };
            db.Templates.Add(template);

            var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
            db.Groups.Add(group);

            var criteria = new Criterion { Id = criteriaId, GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
            db.Criteria.Add(criteria);

            var store = new Store { Id = Guid.NewGuid(), Name = "Test Store" };
            db.Stores.Add(store);

            var submission = new Submission
            {
                Id = submissionId,
                TemplateId = templateId,
                TemplateTitle = "TDD Template",
                DisplayNoun = "Audit",
                StoreId = store.Id,
                StoreName = store.Name,
                AuditorId = auditorId,
                AuditorName = "SDET Auditor",
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow,
                CompletedAt = DateTimeOffset.UtcNow,
                Answers = new List<Answer>
                {
                    new Answer
                    {
                        Id = Guid.NewGuid(),
                        CriteriaId = criteriaId,
                        Value = "non_conform",
                        IsCcp = true,  // Contract Expectation
                        IsRisk = true, // Contract Expectation
                        CreatedAt = DateTimeOffset.UtcNow,
                        UpdatedAt = DateTimeOffset.UtcNow
                    }
                }
            };

            db.Submissions.Add(submission);
            await db.SaveChangesAsync();
        }

        // Act
        var response = await authClient.GetAsync($"/api/submissions/{submissionId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Read Raw JSON to guarantee fields actually serialize down the wire
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var answers = json.GetProperty("answers").EnumerateArray().ToList();

        Assert.Single(answers);
        var firstAnswer = answers[0];

        // Should contain 'isCcp' and 'isRisk'
        Assert.True(firstAnswer.TryGetProperty("isCcp", out var isCcpProp), "The 'isCcp' field is missing from AnswerDto JSON response.");
        Assert.True(isCcpProp.GetBoolean());

        Assert.True(firstAnswer.TryGetProperty("isRisk", out var isRiskProp), "The 'isRisk' field is missing from AnswerDto JSON response.");
        Assert.True(isRiskProp.GetBoolean());
    }
}
