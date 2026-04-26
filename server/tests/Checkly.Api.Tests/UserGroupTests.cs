using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 1: UserGroup CRUD
/// Source: analysis_roles_permissions.md §4, §7
/// 
/// These tests define the acceptance criteria for the UserGroup management feature.
/// They should fail RED because the endpoints do not exist yet.
/// </summary>
public class UserGroupTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public UserGroupTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
        _client = factory.CreateClient();
    }

    // ── Helpers ─────────────────────────────────────────────

    private async Task<HttpClient> GetAdminClientAsync()
    {
        var token = await _factory.LoginBootstrapAdminAsync(_client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<HttpClient> GetAuditorClientAsync()
    {
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            _client,
            $"auditor-{Guid.NewGuid():N}@test.com",
            "Auditor123!@",
            "Test Auditor",
            "auditor",
            adminToken);
        return _factory.CreateAuthenticatedClient(auditorToken);
    }

    // ── AC1: Admin can create a UserGroup ───────────────────
    // Source: analysis §4 — POST /api/user-groups (admin only)

    [Fact]
    public async Task CreateUserGroup_AsAdmin_ReturnsCreated()
    {
        // Arrange
        var admin = await GetAdminClientAsync();

        // Act
        var response = await admin.PostAsJsonAsync("/api/user-groups", new
        {
            name = "QC Auditors",
            description = "Quality control team"
        });

        // Assert — endpoint should return 201 with the created group
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("id", out _), "Response must include 'id'");
        Assert.Equal("QC Auditors", body.GetProperty("name").GetString());
    }

    // ── AC2: Auditor cannot create a UserGroup ──────────────
    // Source: analysis §7 — UserGroup CRUD is Admin-only

    [Fact]
    public async Task CreateUserGroup_AsAuditor_ReturnsForbidden()
    {
        // Arrange
        var auditor = await GetAuditorClientAsync();

        // Act
        var response = await auditor.PostAsJsonAsync("/api/user-groups", new
        {
            name = "Rogue Group"
        });

        // Assert — non-admin should get 403
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ── AC3: Admin can list all UserGroups ───────────────────
    // Source: analysis §4 — GET /api/user-groups (admin only)

    [Fact]
    public async Task ListUserGroups_AsAdmin_ReturnsOk()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        // Create a group first
        await admin.PostAsJsonAsync("/api/user-groups", new { name = "List Test Group" });

        // Act
        var response = await admin.GetAsync("/api/user-groups");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Object, body.ValueKind);
        Assert.True(body.TryGetProperty("items", out var items), "Response must include 'items' array");
        Assert.Equal(JsonValueKind.Array, items.ValueKind);
    }

    // ── AC4: Admin can add members to a UserGroup ───────────
    // Source: analysis §4 — PUT /api/user-groups/{id}/members

    [Fact]
    public async Task AddMembersToGroup_AsAdmin_ReturnsOk()
    {
        // Arrange
        var admin = await GetAdminClientAsync();

        // Create a group
        var createResponse = await admin.PostAsJsonAsync("/api/user-groups", new
        {
            name = "Members Test Group"
        });
        var group = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var groupId = group.GetProperty("id").GetString();
        Assert.NotNull(groupId); // Setup: group must be created

        // Create an auditor to add as member
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);
        var (_, auditorId) = await _factory.RegisterUserAsync(
            _client,
            $"member-{Guid.NewGuid():N}@test.com",
            "Member123!@",
            "Member User",
            "auditor",
            adminToken);

        // Act
        var response = await admin.PutAsJsonAsync(
            $"/api/user-groups/{groupId}/members",
            new { profileIds = new[] { auditorId } });

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ── AC5: Unauthenticated request returns 401 ────────────
    // Source: analysis §7 — all endpoints require auth

    [Fact]
    public async Task ListUserGroups_Unauthenticated_ReturnsUnauthorized()
    {
        // Act — no auth header
        var response = await _client.GetAsync("/api/user-groups");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
