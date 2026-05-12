using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 2A: Programs Module - Backend Sync & Submit Endpoints
/// ATDD Acceptance Tests for SM Execution Workflow
/// </summary>
public class Program_Slice2A_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice2A_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ── Setup Helpers ────────────────────────────────────────────────────────

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

    private async Task<Guid> CreateTemplateAsync(HttpClient adminClient, string title)
    {
        var response = await adminClient.PostAsJsonAsync("/api/templates", new { title, type = "qc" });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    /// <summary>
    /// Creates a template with one active pass_fail criterion seeded directly in the DB.
    /// Returns (templateId, criterionId) for tests that need a valid answers payload.
    /// </summary>
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

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/stores", new { name });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
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

    // ── Tests ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task TC1_GetMyAssignments_AsStoreManager_ReturnsAssignments()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc1-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC1 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC1 Template");
        await AssignProgramAsync(adminClient, templateId, storeId, "TC1 Program");

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.Single(items);
        var item = items[0];
        Assert.Equal("TC1 Program", item.GetProperty("programTitle").GetString());
        Assert.Equal("pending", item.GetProperty("status").GetString());
        Assert.Equal(templateId.ToString(), item.GetProperty("templateId").GetString());
    }

    [Fact]
    public async Task TC2_GetMyAssignments_OnlyReturnsOwnStoreAssignments()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc2-sm-{Guid.NewGuid()}@test.test");

        var ownStoreId = await CreateStoreAsync(adminClient, "TC2 Own Store");
        var otherStoreId = await CreateStoreAsync(adminClient, "TC2 Other Store");
        await LinkStoreManagerToStoreAsync(smId, ownStoreId);

        var templateId = await CreateTemplateAsync(adminClient, "TC2 Template");

        // Assign to BOTH stores
        await AssignProgramAsync(adminClient, templateId, ownStoreId, "TC2 Own Program");
        await AssignProgramAsync(adminClient, templateId, otherStoreId, "TC2 Other Program");

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        // Should only see the 1 assignment for their own store, implicitly verifying store scoping (IDOR protection)
        Assert.Single(items);
        Assert.Equal("TC2 Own Program", items[0].GetProperty("programTitle").GetString());
    }

    private async Task<Guid> GetAssignmentIdForStoreAsync(Guid programId, Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FirstAsync(pa => pa.ProgramId == programId && pa.StoreId == storeId);
        return assignment.Id;
    }

    [Fact]
    public async Task TC_S2_01_SM_With_ProgramsExecute_Creates_Draft_For_Valid_Assignment()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc01-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC01 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC01 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC01 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-{assignmentId}"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Verify state change
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
        Assert.Equal("in_progress", assignment!.Status);
    }

    [Fact]
    public async Task TC_S2_02_SM_Creates_Draft_Submission_For_Assignment_Transitions_To_InProgress()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc02-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC02 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC02 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC02 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        // Use draft status — this test verifies the in_progress state machine transition.
        // Completed submissions require a full answers payload which would over-complicate this test.
        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-tc02-{assignmentId}"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Verify state change
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
        Assert.Equal("in_progress", assignment!.Status);
    }

    [Fact]
    public async Task TC_S2_03_Finalize_Transitions_Assignment_To_Submitted()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc03-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC03 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        // Use a template with a seeded criterion so the finalize payload can provide a valid answer.
        var (templateId, criterionId) = await CreateTemplateWithCriterionAsync(adminClient, "TC03 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC03 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-{assignmentId}"
        };

        var draftRes = await smClient.PostAsJsonAsync("/api/submissions", request);
        draftRes.EnsureSuccessStatusCode();
        var draftJson = await draftRes.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = draftJson.GetProperty("id").GetString();

        // Provide one valid answer so the finalize guard (Answers not empty) is satisfied.
        // clientScore must match server-computed score: 1 conform pass_fail criterion = 100%.
        var finalizeReq = new
        {
            clientScore = 100.0,
            sectionScores = "{}",
            answers = new[]
            {
                new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false }
            }
        };

        // Act
        var finalizeRes = await smClient.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", finalizeReq);

        // Assert
        if (!finalizeRes.IsSuccessStatusCode) Assert.Fail($"Status: {finalizeRes.StatusCode}. Body: {await finalizeRes.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.OK, finalizeRes.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
        Assert.Equal("submitted", assignment!.Status);

        var submission = await db.Set<Checkly.Api.Common.Persistence.Entities.Submission>().FindAsync(Guid.Parse(submissionId!));
        Assert.Equal("approved", submission!.ReviewStatus);
    }

    [Fact]
    public async Task TC_S2_04_IDOR_SM_From_StoreB_Cannot_Use_StoreA_Assignment()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClientB, smIdB) = await CreateStoreManagerAsync($"tc04-smB-{Guid.NewGuid()}@test.test");

        var storeA = await CreateStoreAsync(adminClient, "TC04 Store A");
        var storeB = await CreateStoreAsync(adminClient, "TC04 Store B");
        
        await LinkStoreManagerToStoreAsync(smIdB, storeB); // SM B linked to Store B

        var templateId = await CreateTemplateAsync(adminClient, "TC04 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeA, "TC04 Program for A"); // Assigned to Store A
        var assignmentIdA = await GetAssignmentIdForStoreAsync(programId, storeA);

        var request = new
        {
            templateId = templateId,
            storeId = storeB, // SM trying to create submission for their own store...
            programAssignmentId = assignmentIdA, // ...but hijacking Store A's assignment
            status = "draft",
            idempotencyKey = $"prog-draft-idor-{assignmentIdA}"
        };

        // Act
        var response = await smClientB.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC_S2_05_Template_Mismatch_Returns_400()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc05-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC05 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var template1 = await CreateTemplateAsync(adminClient, "TC05 Template 1");
        var template2 = await CreateTemplateAsync(adminClient, "TC05 Template 2");
        
        var programId = await AssignProgramAsync(adminClient, template1, storeId, "TC05 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        var request = new
        {
            templateId = template2, // Wrong template
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-{assignmentId}"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC_S2_06_NonExistent_AssignmentId_Returns_404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc06-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC06 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC06 Template");

        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = Guid.NewGuid(), // Fake ID
            status = "draft",
            idempotencyKey = $"prog-draft-fake"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC_S2_07_SM_Without_ProgramsExecute_Is_Rejected()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        
        // We need a user WITHOUT programs:execute. An auditor does not have it.
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, $"tc07-auditor-{Guid.NewGuid()}@test.test", "AudTest123!@", "Test Aud", "auditor", adminToken);
        var auditorClient = _factory.CreateAuthenticatedClient(token);

        var storeId = await CreateStoreAsync(adminClient, "TC07 Store");
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FirstAsync(p => p.Id == userId);
        profile.StoreId = storeId;
        await db.SaveChangesAsync();

        var templateId = await CreateTemplateAsync(adminClient, "TC07 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC07 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-{assignmentId}"
        };

        // Act
        var response = await auditorClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC_S2_08_Normal_Audit_Path_Unchanged()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, $"tc08-auditor-{Guid.NewGuid()}@test.test", "AudTest123!@", "Test Aud", "auditor", adminToken);
        var auditorClient = _factory.CreateAuthenticatedClient(token);

        var storeId = await CreateStoreAsync(adminClient, "TC08 Store");
        var templateId = await CreateTemplateAsync(adminClient, "TC08 Template");

        // Normal audit (NO programAssignmentId)
        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            status = "draft",
            idempotencyKey = $"normal-draft-{Guid.NewGuid()}"
        };

        // Act
        var response = await auditorClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task TC_S2_10_DoubleTap_Guard_Returns_Same_Submission()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc10-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC10 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC10 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC10 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        var idempotencyKey = $"prog-draft-{assignmentId}";
        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = idempotencyKey
        };

        // Act
        var res1 = await smClient.PostAsJsonAsync("/api/submissions", request);
        var res2 = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, res1.StatusCode); // First creates
        Assert.Equal(HttpStatusCode.OK, res2.StatusCode); // Second hits idempotency

        var json1 = await res1.Content.ReadFromJsonAsync<JsonElement>();
        var json2 = await res2.Content.ReadFromJsonAsync<JsonElement>();
        
        Assert.Equal(json1.GetProperty("id").GetString(), json2.GetProperty("id").GetString());
    }

    [Fact]
    public async Task TC_S2_11_Cannot_Draft_Submission_For_Already_Submitted_Assignment()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc11-sm-{Guid.NewGuid()}@test.test");

        var storeId = await CreateStoreAsync(adminClient, "TC11 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);

        var templateId = await CreateTemplateAsync(adminClient, "TC11 Template");
        var programId = await AssignProgramAsync(adminClient, templateId, storeId, "TC11 Program");
        var assignmentId = await GetAssignmentIdForStoreAsync(programId, storeId);

        // Set assignment to "submitted" manually
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignment = await db.Set<Checkly.Api.Common.Persistence.Entities.ProgramAssignment>().FindAsync(assignmentId);
            assignment!.Status = "submitted";
            await db.SaveChangesAsync();
        }

        var request = new
        {
            templateId = templateId,
            storeId = storeId,
            programAssignmentId = assignmentId,
            status = "draft",
            idempotencyKey = $"prog-draft-already-sub-{assignmentId}"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/submissions", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
