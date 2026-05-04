using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Features.Programs;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 4: Programs Module - Verification and Rejection Engine
/// ATDD Acceptance Tests for POST /reject and POST /verify endpoints.
/// </summary>
public class Program_Slice4_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice4_Tests(TestWebApplicationFactory factory)
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

    private async Task<(HttpClient token, Guid userId)> CreateRoleClientAsync(string email, string role)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, $"Test123!@#{role}", $"Test {role}", role, adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<(HttpClient adminClient, HttpClient smClient, Guid assignmentId, Guid programId)> SetupSubmittedAssignmentAsync()
    {
        var adminClient = await CreateAdminClientAsync();

        // 1. Create a Store
        var storeResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = $"Slice4-Store-{Guid.NewGuid()}" });
        storeResp.EnsureSuccessStatusCode();
        var storeId = (await storeResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // 2. Create an SM and assign to Store
        var smEmail = $"sm-{Guid.NewGuid()}@test.test";
        var (smClient, smId) = await CreateRoleClientAsync(smEmail, "store_manager");

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(smId);
            if (profile != null)
            {
                profile.StoreId = storeId;
                await db.SaveChangesAsync();
            }
        }

        // 3. Create a Template
        var tplResp = await adminClient.PostAsJsonAsync("/api/templates", new { title = "Slice4-Template", type = "checklist" });
        tplResp.EnsureSuccessStatusCode();
        var templateId = (await tplResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // 4. Create the Program (Assigns to Store)
        var createResp = await adminClient.PostAsJsonAsync("/api/programs", new
        {
            templateId,
            storeIds = new[] { storeId },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Slice4",
            title = "Slice4 Program"
        });
        createResp.EnsureSuccessStatusCode();
        var createJson = await createResp.Content.ReadFromJsonAsync<JsonElement>();
        var programId = createJson.GetProperty("programId").GetGuid();

        // 5. Get Assignment ID
        var assignResp = await adminClient.GetAsync($"/api/programs/{programId}/assignments");
        assignResp.EnsureSuccessStatusCode();
        var assignJson = await assignResp.Content.ReadFromJsonAsync<JsonElement>();
        var assignmentId = assignJson.GetProperty("items")[0].GetProperty("id").GetGuid();

        // 6. SM Submits Assignment
        var submitResp = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", new SubmitEvidenceRequest(
            new[]
            {
                new EvidenceItemRequest(Guid.NewGuid(), "Done", null)
            }
        ));
        submitResp.EnsureSuccessStatusCode();

        return (adminClient, smClient, assignmentId, programId);
    }

    [Fact]
    public async Task TC1_Reject_Submitted_Assignment_Returns_200()
    {
        // Arrange
        var (adminClient, _, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Act
        var response = await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "Incomplete photos" });

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected 200, got {response.StatusCode}. Body: {body}");
        }

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task TC2_Reject_NeedsRevision_Assignment_Returns_400()
    {
        // Arrange
        var (adminClient, _, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Reject once
        await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "First reject" });

        // Act - Reject again
        var response = await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "Second reject" });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC3_Reject_Pending_Assignment_Returns_400()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var storeResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = "Pending-Store" });
        var storeId = (await storeResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var tplResp = await adminClient.PostAsJsonAsync("/api/templates", new { title = "Pending-Tpl", type = "checklist" });
        var templateId = (await tplResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var createResp = await adminClient.PostAsJsonAsync("/api/programs", new
        {
            templateId,
            storeIds = new[] { storeId },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Slice4",
            title = "Pending Program"
        });
        var programId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("programId").GetGuid();

        var assignResp = await adminClient.GetAsync($"/api/programs/{programId}/assignments");
        var assignmentId = (await assignResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("items")[0].GetProperty("id").GetGuid();

        // Act - Assignment is still 'pending'
        var response = await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "Should fail" });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC4_StoreManager_Cannot_Reject()
    {
        // Arrange
        var (_, smClient, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Act
        var response = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "SM reject" });

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC5_Verify_Submitted_Assignment_Returns_200()
    {
        // Arrange
        var (adminClient, _, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Act
        var response = await adminClient.PostAsync($"/api/programs/assignments/{assignmentId}/verify", null);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected 200, got {response.StatusCode}. Body: {body}");
        }

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task TC6_Verify_Already_Verified_Assignment_Returns_400()
    {
        // Arrange
        var (adminClient, _, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Verify once
        await adminClient.PostAsync($"/api/programs/assignments/{assignmentId}/verify", null);

        // Act - Verify again
        var response = await adminClient.PostAsync($"/api/programs/assignments/{assignmentId}/verify", null);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC7_Reject_Empty_Reason_Returns_400()
    {
        // Arrange
        var (adminClient, _, assignmentId, _) = await SetupSubmittedAssignmentAsync();

        // Act
        var response = await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "   " });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GapAC1_Resubmit_NeedsRevision_Clears_RejectionComment()
    {
        // Arrange
        var (adminClient, smClient, assignmentId, programId) = await SetupSubmittedAssignmentAsync();

        // Admin rejects
        await adminClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/reject", new { reason = "Needs fixing" });

        // Act - SM resubmits
        var submitResp = await smClient.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", new SubmitEvidenceRequest(
            new[]
            {
                new EvidenceItemRequest(Guid.NewGuid(), "Fixed", null)
            }
        ));

        if (!submitResp.IsSuccessStatusCode)
        {
            var err = await submitResp.Content.ReadAsStringAsync();
            Assert.Fail($"Resubmit failed: {err}");
        }

        // Assert - Fetch assignment to check status and comment
        var assignResp = await adminClient.GetAsync($"/api/programs/{programId}/assignments");
        var assignJson = await assignResp.Content.ReadFromJsonAsync<JsonElement>();
        var item = assignJson.GetProperty("items")[0];

        Assert.Equal("submitted", item.GetProperty("status").GetString());

        // Rejection comment should be null
        Assert.Equal(JsonValueKind.Null, item.GetProperty("rejectionComment").ValueKind);
    }

    [Fact]
    public async Task GapAC2_Verify_Sets_VerifiedAt()
    {
        // Arrange
        var (adminClient, _, assignmentId, programId) = await SetupSubmittedAssignmentAsync();

        // Act
        await adminClient.PostAsync($"/api/programs/assignments/{assignmentId}/verify", null);

        // Assert
        var assignResp = await adminClient.GetAsync($"/api/programs/{programId}/assignments");
        var assignJson = await assignResp.Content.ReadFromJsonAsync<JsonElement>();
        var item = assignJson.GetProperty("items")[0];

        Assert.Equal("verified", item.GetProperty("status").GetString());
        Assert.True(item.TryGetProperty("verifiedAt", out var verifiedAtProp));
        Assert.NotEqual(JsonValueKind.Null, verifiedAtProp.ValueKind);
    }
}
