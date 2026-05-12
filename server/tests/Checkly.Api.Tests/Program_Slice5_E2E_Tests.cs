using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 5: Program Submission Bridge - E2E Integration Test
/// Full E2E proof of the bridge lifecycle.
/// </summary>
public class Program_Slice5_E2E_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice5_E2E_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<(HttpClient Client, Guid UserId)> CreateStoreManagerAsync(string email)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, "SmTest123!@", "Test SM", "store_manager", adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task LinkStoreManagerToStoreAsync(Guid userId, Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FirstAsync(p => p.Id == userId);
        profile.StoreId = storeId;
        await db.SaveChangesAsync();
    }

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/stores", new { name });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> CreateTemplateAsync(HttpClient adminClient, string title)
    {
        var response = await adminClient.PostAsJsonAsync("/api/templates", new { title, type = "qc" });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<(Guid TemplateId, Guid CriterionId)> CreateTemplateWithCriterionAsync(HttpClient adminClient, string title)
    {
        var templateId = await CreateTemplateAsync(adminClient, title);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var group = new Group
        {
            Id = Guid.NewGuid(),
            TemplateId = templateId,
            Title = "Section A",
            IsActive = true
        };
        db.Groups.Add(group);

        var criterion = new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = group.Id,
            Label = "Pass/Fail Item",
            InputType = "pass_fail",
            PointsWeight = 10,
            IsActive = true
        };
        db.Criteria.Add(criterion);
        await db.SaveChangesAsync();

        return (templateId, criterion.Id);
    }

    private async Task<Guid> AssignProgramAsync(HttpClient adminClient, Guid templateId, Guid storeId, string title)
    {
        var request = new
        {
            templateId = templateId,
            storeIds = new[] { storeId },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = title
        };
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);
        Assert.True(response.IsSuccessStatusCode, "Failed to assign program.");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("programId").GetString()!);
    }

    private async Task<Guid> GetAssignmentIdForStoreAsync(Guid programId, Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FirstAsync(pa => pa.ProgramId == programId && pa.StoreId == storeId);
        return assignment.Id;
    }

    [Fact]
    public async Task Slice5_E2E_SM_Taps_Submission_Created_Submitted_Approved()
    {
        // ====================================================================
        // ARRANGE: Setup the Program Assignment (HQ Journey)
        // ====================================================================
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"slice5-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "Slice 5 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var (templateId, criterionId) = await CreateTemplateWithCriterionAsync(adminClient, "Slice 5 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "Slice 5 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        // Verify initial state
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
            Assert.Equal("pending", assignment!.Status);
        }

        // ====================================================================
        // ACT 1: SM Taps "Start Audit" -> Creates Submission with ProgramAssignmentId
        // ====================================================================
        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"slice5-draft-{assignmentId}"
        };

        var draftRes = await smClient.PostAsJsonAsync("/api/submissions", request);

        // ====================================================================
        // ASSERT 1: Validate Submission Created & Status in_progress
        // ====================================================================
        Assert.Equal(HttpStatusCode.Created, draftRes.StatusCode);
        var draftJson = await draftRes.Content.ReadFromJsonAsync<JsonElement>();
        var submissionIdStr = draftJson.GetProperty("id").GetString();
        Assert.NotNull(submissionIdStr);
        var submissionId = Guid.Parse(submissionIdStr!);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var submission = await db.Set<Checkly.Api.Common.Persistence.Entities.Submission>().FindAsync(submissionId);
            
            Assert.NotNull(submission);
            Assert.Equal(assignmentId, submission!.ProgramAssignmentId);

            var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
            Assert.Equal("in_progress", assignment!.Status);
        }

        // ====================================================================
        // ACT 2: SM Completes Audit -> Finalize Submission
        // ====================================================================
        var finalizeReq = new
        {
            clientScore = 100.0,
            sectionScores = "{}",
            answers = new[]
            {
                new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false }
            }
        };

        var finalizeRes = await smClient.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", finalizeReq);

        // ====================================================================
        // ASSERT 2: Validate ProgramAssignment submitted & Submission approved
        // ====================================================================
        Assert.Equal(HttpStatusCode.OK, finalizeRes.StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
            Assert.Equal("submitted", assignment!.Status);

            var submission = await db.Set<Checkly.Api.Common.Persistence.Entities.Submission>().FindAsync(submissionId);
            Assert.Equal("approved", submission!.ReviewStatus);
            Assert.Equal("completed", submission!.Status);
        }
    }
}
