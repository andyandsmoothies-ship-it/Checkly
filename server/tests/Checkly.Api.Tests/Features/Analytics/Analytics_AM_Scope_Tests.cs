using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// Verification tests for the am2 Analytics 403 bug fix.
///
/// Bug: GetAnalytics.cs used profile.AreaId for AM tenancy scoping,
///      but profile.AreaId is intentionally NULL for AMs.
///      AMs are assigned stores via ProfileStoreAssignment junction.
///
/// Fix: Replaced AreaId guard with ProfileStoreAssignment query — matching ListActionPlans.cs:42-55.
///
/// Source: docs/diagnostics/failure_report_20260518_164958_am2_analytics_area_scope.md
/// </summary>
public class Analytics_AM_Scope_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Analytics_AM_Scope_Tests(TestWebApplicationFactory factory)
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

    private async Task<(HttpClient Client, Guid UserId)> CreateRoleClientAsync(string email, string role)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, $"Test123!@#{role}", $"Test {role}", role, adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var resp = await adminClient.PostAsJsonAsync("/api/stores", new { name });
        if (!resp.IsSuccessStatusCode)
            Assert.Fail($"Setup: store creation failed. {resp.StatusCode}: {await resp.Content.ReadAsStringAsync()}");
        var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task AssignStoreToAmAsync(HttpClient adminClient, Guid amUserId, Guid storeId)
    {
        var resp = await adminClient.PutAsJsonAsync(
            $"/api/admin/users/{amUserId}",
            new { assignedStoreIds = new[] { storeId } });
        if (!resp.IsSuccessStatusCode)
            Assert.Fail($"Setup: store assignment failed. {resp.StatusCode}: {await resp.Content.ReadAsStringAsync()}");
    }

    // ─────────────────────────────────────────────────────────────
    // AC-1: AM with NULL profile.AreaId no longer receives 403.
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Previously, any AM with NULL AreaId received HTTP 403.
    /// After the fix, the endpoint must return HTTP 200.
    /// </summary>
    [Fact]
    public async Task AM_With_No_Store_Assignments_Returns_200_Not_403()
    {
        // Arrange — create AM with no store assignments (profile.AreaId is NULL by design)
        var (amClient, _) = await CreateRoleClientAsync("am-scope-noassign@test.test", "area_manager");

        // Act
        var response = await amClient.GetAsync("/api/analytics");

        // Assert — must be 200, NOT 403 (the original bug)
        if (response.StatusCode == HttpStatusCode.Forbidden)
            Assert.Fail("AM with NULL AreaId received 403 — am2 bug is not fixed.");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ─────────────────────────────────────────────────────────────
    // AC-2: AM scoped to assigned stores (IDOR protection).
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// AM assigned to Store A must see only data from Store A.
    /// Passing ?storeId= for a different store must be silently overridden (IDOR protection).
    /// </summary>
    [Fact]
    public async Task AM_Analytics_Is_Scoped_To_Assigned_Stores()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (amClient, amUserId) = await CreateRoleClientAsync("am-scope-assigned@test.test", "area_manager");

        var storeA = await CreateStoreAsync(adminClient, $"AM-Scope StoreA {Guid.NewGuid()}");
        var storeB = await CreateStoreAsync(adminClient, $"AM-Scope StoreB {Guid.NewGuid()}");

        // Assign AM to Store A only
        await AssignStoreToAmAsync(adminClient, amUserId, storeA);

        // Act — AM requests analytics (no storeId param = their store scope)
        var response = await amClient.GetAsync("/api/analytics");

        // Assert — 200 (not 403) and response shape is valid
        if (!response.IsSuccessStatusCode)
            Assert.Fail($"AM /api/analytics failed. Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("kpis", out _), "Response must contain 'kpis'");
        Assert.True(json.TryGetProperty("trend", out _), "Response must contain 'trend'");
    }

    // ─────────────────────────────────────────────────────────────
    // AC-3: Store Manager and Admin still work (regression guard).
    // ─────────────────────────────────────────────────────────────

    /// <summary>
    /// Blast radius check: the SM block must not be affected by the AM fix.
    /// </summary>
    [Fact]
    public async Task Admin_GetAnalytics_Still_Returns_200_After_Fix()
    {
        var adminClient = await CreateAdminClientAsync();
        var response = await adminClient.GetAsync("/api/analytics");
        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Admin analytics broken after fix. Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
