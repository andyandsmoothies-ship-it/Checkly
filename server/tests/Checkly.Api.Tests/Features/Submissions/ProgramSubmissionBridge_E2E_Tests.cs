using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class ProgramSubmissionBridge_E2E_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public ProgramSubmissionBridge_E2E_Tests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateAndFinalize_ProgramSubmission_TransitionsAssignmentStatusAndLinksCorrectly()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        // Register a store manager user to act as the assignee
        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "assignee1@test.com", "Aa1234567@", "Assignee 1", "store_manager");

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store { Id = storeId, Name = "Bridge Test Store", IsActive = true });

        // Link profile to store
        var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == userId);
        profile!.StoreId = storeId;

        var templateId = Guid.NewGuid();
        db.Templates.Add(new Template { Id = templateId, Title = "Bridge Template", Version = 1, IsActive = true, ScoringLogicConfig = "{\"mode\":\"penalty\",\"maxPoints\":100}" });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        var programId = Guid.NewGuid();
        db.Programs.Add(new ChecklyProgram { Id = programId, Title = "Bridge Program", Status = "active", TemplateId = templateId, Deadline = DateTimeOffset.UtcNow.AddDays(7) });

        var assignmentId = Guid.NewGuid();
        db.ProgramAssignments.Add(new ProgramAssignment
        {
            Id = assignmentId,
            ProgramId = programId,
            StoreId = storeId,
            AssigneeId = profile.Id,
            Status = "pending",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // Act 1: Create a Draft Submission linked to the Program Assignment
        var createPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "draft",
            ProgramAssignmentId = assignmentId
        };

        var createResponse = await client.PostAsJsonAsync("/api/submissions", createPayload);
        
        // Assert 1: Creation success and initial linkage
        if (!createResponse.IsSuccessStatusCode)
        {
            var contentString = await createResponse.Content.ReadAsStringAsync();
            Assert.Fail($"Request failed with {createResponse.StatusCode} and body: {contentString}");
        }

        var createJson = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(createJson.GetProperty("id").GetString()!);

        // Verify DB State after Create
        var dbSubmissionDraft = await db.Submissions.AsNoTracking().FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(dbSubmissionDraft);
        Assert.Equal(assignmentId, dbSubmissionDraft.ProgramAssignmentId);
        
        var dbAssignmentDraft = await db.ProgramAssignments.AsNoTracking().FirstOrDefaultAsync(pa => pa.Id == assignmentId);
        Assert.NotNull(dbAssignmentDraft);
        Assert.Equal("in_progress", dbAssignmentDraft.Status);

        // Act 2: Finalize the Submission
        var finalizePayload = new
        {
            ClientScore = 100m,
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        var finalizeResponse = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", finalizePayload);

        // Assert 2: Finalize success and final status transitions
        if (!finalizeResponse.IsSuccessStatusCode)
        {
            var contentString = await finalizeResponse.Content.ReadAsStringAsync();
            Assert.Fail($"Finalize request failed with {finalizeResponse.StatusCode} and body: {contentString}");
        }

        // Verify DB State after Finalize
        var dbSubmissionFinal = await db.Submissions.AsNoTracking().FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(dbSubmissionFinal);
        Assert.Equal("completed", dbSubmissionFinal.Status);
        Assert.Equal("approved", dbSubmissionFinal.ReviewStatus);

        var dbAssignmentFinal = await db.ProgramAssignments.AsNoTracking().FirstOrDefaultAsync(pa => pa.Id == assignmentId);
        Assert.NotNull(dbAssignmentFinal);
        Assert.Equal("submitted", dbAssignmentFinal.Status);
    }
}
