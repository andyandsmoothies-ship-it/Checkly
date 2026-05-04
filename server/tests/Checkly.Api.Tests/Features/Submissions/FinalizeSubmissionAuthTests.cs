using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class FinalizeSubmissionAuthTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public FinalizeSubmissionAuthTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task FinalizeSubmission_WhenAdminFinalizesAnotherAuditorsSubmission_ReturnsOk()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        // Create the auditor (the one assigned to the submission)
        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        // Create the admin (the one attempting to finalize it)
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(_factory.CreateClient());
        var adminReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"admin_{Guid.NewGuid()}@test.com", "Aa1234567@", "Admin User", "admin", bootstrapToken);

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Auth Test", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Auth Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = 1.0m };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorReg.UserId, // Assigned to Auditor
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = $"{{\"groups\":[{{\"id\":\"{group.Id}\",\"title\":\"G1\",\"criteria\":[{{\"id\":\"{criteria.Id}\",\"groupId\":\"{group.Id}\",\"label\":\"C1\",\"inputType\":\"pass_fail\",\"pointsWeight\":10}}]}}]}}"
        });

        await db.SaveChangesAsync();

        // Client is logged in as ADMIN
        var adminClient = _factory.CreateAuthenticatedClient(adminReg.Token);

        var payload = new
        {
            ClientScore = 100m,
            SectionScores = $"{{\"G1\":{{\"score\":10,\"maxScore\":10}}}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 10m, Value = "conform" }
            }
        };

        // Act
        var response = await adminClient.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
