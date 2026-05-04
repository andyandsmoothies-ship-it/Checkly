using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
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

    [Fact]
    public async Task TC3_SubmitEvidence_AsStoreManager_ReturnsSuccess()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"tc3-sm-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "TC3 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "TC3 Template");
        await AssignProgramAsync(adminClient, templateId, storeId, "TC3 Program");

        // Fetch the assignment ID via GET /my
        var getResponse = await smClient.GetAsync("/api/programs/assignments/my");
        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        var assignmentId = getBody.GetProperty("items")[0].GetProperty("id").GetString();

        var submitRequest = new
        {
            evidenceItems = new[]
            {
                new { criteriaId = Guid.NewGuid().ToString(), value = "Done", photoLocalKey = "photo1.jpg" }
            }
        };

        // Act
        var response = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", submitRequest);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task TC4_SubmitEvidence_AsAdmin_ReturnsForbidden()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "TC4 Template");
        var storeId = await CreateStoreAsync(adminClient, "TC4 Store");
        await AssignProgramAsync(adminClient, templateId, storeId, "TC4 Program");

        var assignmentId = Guid.NewGuid(); // Since Admin can't call /my and we just need a failure, we can mock or query DB
        // Fetch assignment ID directly via EF Core to be accurate
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            assignmentId = await db.ProgramAssignments.Select(x => x.Id).FirstOrDefaultAsync();
        }

        var submitRequest = new
        {
            evidenceItems = new[]
            {
                new { criteriaId = Guid.NewGuid().ToString(), value = "Done" }
            }
        };

        // Act
        var response = await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", submitRequest);

        // Assert (Admin lacks store manager specific scope/role for execution)
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task GapAC1_SubmitEvidence_AlreadyCompleted_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"gap1-sm-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Gap1 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Gap1 Template");
        await AssignProgramAsync(adminClient, templateId, storeId, "Gap1 Program");

        var getResponse = await smClient.GetAsync("/api/programs/assignments/my");
        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        var assignmentId = getBody.GetProperty("items")[0].GetProperty("id").GetString();

        var submitRequest = new
        {
            evidenceItems = new[] { new { criteriaId = Guid.NewGuid().ToString(), value = "Done" } }
        };

        // Act 1: Submit first time (Should Succeed)
        await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", submitRequest);

        // Act 2: Submit second time (Should Fail)
        var response = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", submitRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GapAC2_SubmitEvidence_WithEmptyItems_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"gap2-sm-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Gap2 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Gap2 Template");
        await AssignProgramAsync(adminClient, templateId, storeId, "Gap2 Program");

        var getResponse = await smClient.GetAsync("/api/programs/assignments/my");
        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        var assignmentId = getBody.GetProperty("items")[0].GetProperty("id").GetString();

        var submitRequest = new
        {
            evidenceItems = Array.Empty<object>() // Empty!
        };

        // Act
        var response = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", submitRequest);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GapAC3_SubmitEvidence_ForOtherStore_ReturnsNotFound()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClientA, smIdA) = await CreateStoreManagerAsync($"gap3-sma-{Guid.NewGuid()}@test.test");
        var (smClientB, smIdB) = await CreateStoreManagerAsync($"gap3-smb-{Guid.NewGuid()}@test.test");

        var storeIdA = await CreateStoreAsync(adminClient, "Gap3 Store A");
        var storeIdB = await CreateStoreAsync(adminClient, "Gap3 Store B");

        await LinkStoreManagerToStoreAsync(smIdA, storeIdA);
        await LinkStoreManagerToStoreAsync(smIdB, storeIdB);

        var templateId = await CreateTemplateAsync(adminClient, "Gap3 Template");
        await AssignProgramAsync(adminClient, templateId, storeIdB, "Gap3 Program B");

        // Fetch B's assignment ID
        var getResponseB = await smClientB.GetAsync("/api/programs/assignments/my");
        var getBodyB = await getResponseB.Content.ReadFromJsonAsync<JsonElement>();
        var assignmentIdB = getBodyB.GetProperty("items")[0].GetProperty("id").GetString();

        var submitRequest = new
        {
            evidenceItems = new[] { new { criteriaId = Guid.NewGuid().ToString(), value = "Done" } }
        };

        // Act: SM A tries to submit evidence for SM B's assignment
        var response = await smClientA.PostAsJsonAsync($"/api/programs/assignments/{assignmentIdB}/submit", submitRequest);

        // Assert (Must be NotFound to prevent data leakage of existence, or Forbidden)
        Assert.True(response.StatusCode == HttpStatusCode.NotFound || response.StatusCode == HttpStatusCode.Forbidden);
    }
}
