using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 2: Template Assignments
/// Source: analysis_roles_permissions.md §4, §7
/// 
/// These tests define the acceptance criteria for assigning templates to UserGroups.
/// They should fail RED because the endpoints do not exist yet.
/// </summary>
public class TemplateAssignmentTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public TemplateAssignmentTests(TestWebApplicationFactory factory)
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

    private async Task<string> CreateTemplateAsync(HttpClient admin)
    {
        var response = await admin.PostAsJsonAsync("/api/templates", new
        {
            title = $"Test Template {Guid.NewGuid():N}",
            type = "qc",
            description = "For assignment testing"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    private async Task<string> CreateUserGroupAsync(HttpClient admin, string name)
    {
        var response = await admin.PostAsJsonAsync("/api/user-groups", new
        {
            name,
            description = "Test group"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    // ── AC1: Admin can assign a template to a group ─────────
    // Source: analysis §4 — PUT /api/templates/{id}/assignments

    [Fact]
    public async Task AssignTemplateToGroup_AsAdmin_ReturnsOk()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin);
        var groupId = await CreateUserGroupAsync(admin, "Assignment Test Group");

        // Act
        var response = await admin.PutAsJsonAsync(
            $"/api/templates/{templateId}/assignments",
            new { userGroupIds = new[] { groupId } });

        // Assert — 200 OK confirms assignment was created
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ── AC2: Auditor cannot assign templates ────────────────
    // Source: analysis §7 — Template assignment is Admin-only

    [Fact]
    public async Task AssignTemplateToGroup_AsAuditor_ReturnsForbidden()
    {
        // Arrange
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);
        var admin = _factory.CreateAuthenticatedClient(adminToken);
        var templateId = await CreateTemplateAsync(admin);

        var (auditorToken, _) = await _factory.RegisterUserAsync(
            _client,
            $"auditor-assign-{Guid.NewGuid():N}@test.com",
            "Auditor123!@",
            "Test Auditor",
            "auditor",
            adminToken);
        var auditor = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditor.PutAsJsonAsync(
            $"/api/templates/{templateId}/assignments",
            new { userGroupIds = new[] { Guid.NewGuid() } });

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ── AC3: Assigning to empty group list clears assignments ─
    // Source: analysis §6 Failure 1 — CASCADE removes assignments, template reverts to global

    [Fact]
    public async Task AssignTemplateToEmptyGroupList_ClearsAssignments()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin);
        var groupId = await CreateUserGroupAsync(admin, "Clear Test Group");

        // First assign to a group
        await admin.PutAsJsonAsync(
            $"/api/templates/{templateId}/assignments",
            new { userGroupIds = new[] { groupId } });

        // Act — assign to empty list
        var response = await admin.PutAsJsonAsync(
            $"/api/templates/{templateId}/assignments",
            new { userGroupIds = Array.Empty<string>() });

        // Assert — clears assignments, template becomes global again
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
