using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 3: Filtered Template Sync
/// Source: analysis_roles_permissions.md §4, §5, §6
/// 
/// These tests verify that template visibility is filtered by UserGroup membership.
/// They should fail RED because the filtering logic does not exist yet.
/// </summary>
public class FilteredTemplateSyncTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public FilteredTemplateSyncTests(TestWebApplicationFactory factory)
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

    private async Task<(HttpClient Client, Guid UserId)> CreateAuditorAsync(string suffix)
    {
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);
        var (token, userId) = await _factory.RegisterUserAsync(
            _client,
            $"auditor-sync-{suffix}-{Guid.NewGuid():N}@test.com",
            "Auditor123!@",
            $"Auditor {suffix}",
            "auditor",
            adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<string> CreateTemplateAsync(HttpClient admin, string title)
    {
        var response = await admin.PostAsJsonAsync("/api/templates", new
        {
            title,
            type = "qc",
            description = "Sync test template"
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    private async Task<string> CreateGroupAsync(HttpClient admin, string name)
    {
        var response = await admin.PostAsJsonAsync("/api/user-groups", new { name });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    private async Task AddMemberAsync(HttpClient admin, string groupId, Guid profileId)
    {
        var response = await admin.PutAsJsonAsync(
            $"/api/user-groups/{groupId}/members",
            new { profileIds = new[] { profileId } });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    private async Task AssignTemplateAsync(HttpClient admin, string templateId, string groupId)
    {
        var response = await admin.PutAsJsonAsync(
            $"/api/templates/{templateId}/assignments",
            new { userGroupIds = new[] { groupId } });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ── AC1: Unassigned template visible to all auditors ────
    // Source: analysis §2 — "Unassigned = Visible to All"

    [Fact(Skip = "To be implemented in Slice 3")]
    public async Task SyncTemplates_UnassignedTemplate_VisibleToAllAuditors()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Global Template");
        // Do NOT assign to any group

        var (auditor, _) = await CreateAuditorAsync("global");

        // Act — auditor syncs templates
        var response = await auditor.GetAsync("/api/sync/templates?since=2020-01-01T00:00:00Z");

        // Assert — unassigned template should be visible
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains(templateId, body);
    }

    // ── AC2: Assigned template visible only to members ──────
    // Source: analysis §2 — "B → UserGroup: QC Auditors"

    [Fact(Skip = "To be implemented in Slice 3")]
    public async Task SyncTemplates_AssignedTemplate_VisibleOnlyToGroupMembers()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Restricted Template");
        var groupId = await CreateGroupAsync(admin, "Restricted Group");

        // Create 2 auditors — one IN the group, one NOT
        var (memberClient, memberId) = await CreateAuditorAsync("member");
        var (nonMemberClient, _) = await CreateAuditorAsync("nonmember");

        // Add member to group and assign template
        await AddMemberAsync(admin, groupId, memberId);
        await AssignTemplateAsync(admin, templateId, groupId);

        // Act — both auditors sync templates
        var memberResponse = await memberClient.GetAsync("/api/sync/templates?since=2020-01-01T00:00:00Z");
        var nonMemberResponse = await nonMemberClient.GetAsync("/api/sync/templates?since=2020-01-01T00:00:00Z");

        // Assert
        var memberBody = await memberResponse.Content.ReadAsStringAsync();
        var nonMemberBody = await nonMemberResponse.Content.ReadAsStringAsync();

        Assert.Contains(templateId, memberBody); // Member sees it
        Assert.DoesNotContain(templateId, nonMemberBody); // Non-member doesn't
    }

    // ── AC3: Admin sees all templates regardless ────────────
    // Source: analysis §4 diff — "if (role != 'admin')"

    [Fact(Skip = "To be implemented in Slice 3")]
    public async Task SyncTemplates_Admin_SeesAllTemplatesRegardless()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Admin Visibility Test");
        var groupId = await CreateGroupAsync(admin, "Admin Test Group");
        await AssignTemplateAsync(admin, templateId, groupId);
        // Admin is NOT a member of this group

        // Act — admin syncs
        var response = await admin.GetAsync("/api/sync/templates?since=2020-01-01T00:00:00Z");

        // Assert — admin sees everything
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains(templateId, body);
    }
}
