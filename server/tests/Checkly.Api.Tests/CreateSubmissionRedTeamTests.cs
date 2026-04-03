using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")]
public class CreateSubmissionRedTeamTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public CreateSubmissionRedTeamTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateSubmission_WithHostileDtoMassAssignment_IgnoresAdministrativeFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "redteam@test.com", "Aa1234567@", "Red Team Attacker", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "P0.4 Target", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "P0.4 Store", IsActive = true });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);
        
        // This dictionary bypasses the CreateSubmissionRequest restrictions when serialized as JSON,
        // allowing us to inject arbitrary strings at the root mapping level.
        var hostilePayload = new Dictionary<string, object>
        {
            { "templateId", templateId },
            { "storeId", storeId },
            { "status", "completed" },
            { "clientScore", 100m },
            { "sectionScores", $"{{\"Section 1\":{{\"score\":10,\"maxScore\":10}}}}" },
            { "answers", new[]
                {
                    new { criteriaId = criteria.Id, numericValue = 0m, value = "conform" }
                }
            },
            
            // --- HOSTILE MASS ASSIGNMENT INJECTIONS ---
            { "isVerified", true },                   // P0.4 Attack
            { "reviewStatus", "approved" },           // Bypass manual approval checks
            { "totalScore", 9999m },                  // Override server-side business logic
            { "approvedBy", Guid.NewGuid() },         // Fake an admin
            { "voidReason", "Attacker voided this" }, // Write to read-only audit fields
            { "auditorName", "God Mode Admin" }       // Overwrite user extraction
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", hostilePayload);
        
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            throw new Exception($"Request failed with {response.StatusCode} and body: {contentString}");
        }
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        // Reload the true entity from the database to ensure the DTO dropped the hostile payload
        // and safely mapped ONLY the authorized CreateSubmissionRequest fields.
        var dbSubmission = await db.Submissions.AsNoTracking().FirstOrDefaultAsync(s => s.Id == submissionId);
        
        Assert.NotNull(dbSubmission);

        // Prove ReviewStatus was NOT mass-assigned
        Assert.Null(dbSubmission.ReviewStatus);
        
        // Prove ApprovedBy was NOT mass-assigned
        Assert.Null(dbSubmission.ApprovedBy);
        
        // Prove VoidReason was NOT mass-assigned
        Assert.Null(dbSubmission.VoidReason);
        
        // Prove TotalScore was calculated by the backend (100 in this case), not driven by the hostile "9999m"
        Assert.Equal(100m, dbSubmission.TotalScore);
        
        // Prove AuditorName was extracted from the true JWT Profile context ("Red Team Attacker"), 
        // completely ignoring the frontend's injected "God Mode Admin"
        Assert.Equal("Red Team Attacker", dbSubmission.AuditorName);
    }
}
