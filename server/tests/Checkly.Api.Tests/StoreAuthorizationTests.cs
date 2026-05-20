using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Store Authorization — Infra Security Slice 1.
/// Defines acceptance criteria for role-based access control on
/// GetStoreDashboard (IDOR Guard) and ListStores (role-scoped filtering).
///
/// Citation: implementation_plan_infra_slice_1.md.resolved
/// Citation: platform-rules.md §4 (Security — RBAC and IDOR)
/// Citation: audit_infra_report_20260324.md (Critical: Role-Based Data Leakage)
/// </summary>
public class StoreAuthorizationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    // runId ensures all test emails are unique across parallel runs
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public StoreAuthorizationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private static string UniqueEmail(string prefix) => $"{prefix}-{_runId}@store-auth.test";

    // ─── Setup Helpers ────────────────────────────────────────────────────────

    /// <summary>Creates a store and returns its Guid.</summary>
    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/stores", new
        {
            name
        });
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    /// <summary>
    /// Registers a user, assigns a store or area to their Profile via admin UPDATE,
    /// and returns their token and userId. This simulates the post-registration
    /// profile assignment that happens in production.
    /// </summary>
    private async Task<(string Token, Guid UserId)> CreateUserWithRoleAsync(
        HttpClient adminClient,
        string email,
        string role)
    {
        var clnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(clnt);
        return await _factory.RegisterUserAsync(clnt, email, "Auth123!@", $"Test {role}", role, adminToken: bootstrapToken);
    }

    // ─── GetStoreDashboard: Auditor Restriction ───────────────────────────────

    // Scenario: Auditor accesses any store dashboard
    // Given I am authenticated as an auditor
    // When I request GET /api/stores/{any_store_id}/dashboard
    // Then the system returns 403 Forbidden
    // Because: Auditors perform audits via the audit form, not the dashboard API.
    //          Citation: implementation_plan_infra_slice_1.md line 18

    [Fact]
    public async Task GetStoreDashboard_AsAuditor_ReturnsForbidden()
    {
        // Arrange — admin creates a store so we have a valid target ID
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeId = await CreateStoreAsync(adminClient, $"Dashboard Store {_runId}");

        // Arrange — auditor registers and gets their token
        var (auditorToken, _) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("auditor-dash"), "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditorClient.GetAsync($"/api/stores/{storeId}/dashboard");

        // Assert — business rule: auditors are forbidden from dashboards
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── GetStoreDashboard: Store Manager IDOR Guard ──────────────────────────

    // Scenario: Store Manager accesses a dashboard for a store they do NOT manage
    // Given I am authenticated as a store_manager assigned to Store A
    // When I request GET /api/stores/{store_b_id}/dashboard
    // Then the system returns 403 Forbidden
    // Because: IDOR prevention — store managers must only see their own store.
    //          Citation: implementation_plan_infra_slice_1.md line 20

    [Fact]
    public async Task GetStoreDashboard_AsStoreManager_OtherStore_ReturnsForbidden()
    {
        // Arrange — admin creates two separate stores
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeA = await CreateStoreAsync(adminClient, $"SM Store A {_runId}");
        var storeB = await CreateStoreAsync(adminClient, $"SM Store B {_runId}");

        // Arrange — register a store_manager linked to Store A
        var (smToken, smId) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("sm-idor"), "store_manager");

        // Simulate profile store assignment (admin updates user profile)
        await adminClient.PutAsJsonAsync($"/api/admin/users/{smId}", new
        {
            storeId = storeA
        });

        var smClient = _factory.CreateAuthenticatedClient(smToken);

        // Act — SM tries to access Store B's dashboard (which they don't own)
        var response = await smClient.GetAsync($"/api/stores/{storeB}/dashboard");

        // Assert — IDOR prevention must return Forbidden
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── GetStoreDashboard: Area Manager IDOR Guard ───────────────────────────

    // Scenario: Area Manager accesses a dashboard for a store in a DIFFERENT area
    // Given I am authenticated as an area_manager for Area A
    // When I request GET /api/stores/{store_in_area_b_id}/dashboard
    // Then the system returns 403 Forbidden
    // Because: Area managers must be scoped to their geographic area.
    //          Citation: implementation_plan_infra_slice_1.md line 21

    [Fact]
    public async Task GetStoreDashboard_AsAreaManager_NoJunction_ReturnsForbidden()
    {
        // Arrange — admin creates a store
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeAId = await CreateStoreAsync(adminClient, $"AM Store A {_runId}");

        // Arrange — register area_manager
        var (amToken, amId) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("am-idor"), "area_manager");

        var amClient = _factory.CreateAuthenticatedClient(amToken);

        // Act — AM tries to access a store, BUT has no junction row
        var response = await amClient.GetAsync($"/api/stores/{storeAId}/dashboard");

        // Assert — IDOR prevention must return Forbidden
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── ListStores: Store Manager Scope ─────────────────────────────────────

    // Scenario: Store Manager calls ListStores
    // Given I am a store_manager for Store A (and Store B exists)
    // When I call GET /api/stores
    // Then the response contains exactly Store A (not Store B)
    // Because: Store managers must only see their assigned store.
    //          Citation: implementation_plan_infra_slice_1.md line 29

    [Fact]
    public async Task ListStores_AsStoreManager_ReturnsOnlyOwnStore()
    {
        // Arrange — admin creates two stores
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeA = await CreateStoreAsync(adminClient, $"SM List StoreA {_runId}");
        /*var storeB =*/
        await CreateStoreAsync(adminClient, $"SM List StoreB {_runId}");

        // Arrange — register SM assigned to Store A
        var (smToken, smId) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("sm-list"), "store_manager");
        await adminClient.PutAsJsonAsync($"/api/admin/users/{smId}", new { storeId = storeA });

        var smClient = _factory.CreateAuthenticatedClient(smToken);

        // Act
        var response = await smClient.GetAsync("/api/stores");

        // Assert — SM sees only their single assigned store
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items");
        Assert.Equal(1, items.GetArrayLength());
        Assert.Equal(storeA.ToString(), items[0].GetProperty("id").GetString());
    }

    // ─── ListStores: Area Manager Scope ──────────────────────────────────────

    // Scenario: Area Manager calls ListStores
    // Given I am an area_manager for Area A (with 2 stores)
    // And Area B (with 1 store) also exists
    // When I call GET /api/stores
    // Then the response contains exactly the 2 stores in Area A
    // Because: Area managers must only see stores in their assigned area.
    //          Citation: implementation_plan_infra_slice_1.md line 30

    [Fact]
    public async Task ListStores_AsAreaManager_ReturnsOnlyJunctionStores()
    {
        // Arrange — create stores
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeA1 = await CreateStoreAsync(adminClient, $"AM North Store1 {_runId}");
        var storeA2 = await CreateStoreAsync(adminClient, $"AM North Store2 {_runId}");
        var storeB1 = await CreateStoreAsync(adminClient, $"AM South Store1 {_runId}");

        // Arrange — register AM
        var (amToken, amId) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("am-list"), "area_manager");

        // Insert junction rows for StoreA1 and StoreB1
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();
            db.ProfileStoreAssignments.Add(new Checkly.Api.Common.Persistence.Entities.ProfileStoreAssignment { ProfileId = amId, StoreId = storeA1 });
            db.ProfileStoreAssignments.Add(new Checkly.Api.Common.Persistence.Entities.ProfileStoreAssignment { ProfileId = amId, StoreId = storeB1 });
            await db.SaveChangesAsync();
        }

        var amClient = _factory.CreateAuthenticatedClient(amToken);

        // Act
        var response = await amClient.GetAsync("/api/stores");

        // Assert — AM sees exactly 2 stores (junction assigned only)
        // Currently fails because it returns all 2 stores in Area A, ignoring junction and Store B1.
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().Select(x => x.GetProperty("id").GetString()).ToList();

        Assert.Equal(2, items.Count);
        Assert.Contains(storeA1.ToString(), items);
        Assert.Contains(storeB1.ToString(), items);
    }

    // ─── ListStores: Auditor Sees All Active Stores ───────────────────────────

    // Scenario: Auditor calls ListStores
    // Given I am an auditor and multiple stores exist
    // When I call GET /api/stores
    // Then the response contains all active stores (no role-based scoping)
    // Because: Auditors need access to all stores to select a target for an audit.
    //          Citation: implementation_plan_infra_slice_1.md line 27

    [Fact]
    public async Task ListStores_AsAuditor_ReturnsAllActiveStores()
    {
        // Arrange — admin creates two stores
        var adminClnt = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(adminClnt);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        var storeX = await CreateStoreAsync(adminClient, $"Aud StoreX {_runId}");
        var storeY = await CreateStoreAsync(adminClient, $"Aud StoreY {_runId}");

        // Arrange — register auditor
        var (auditorToken, _) = await CreateUserWithRoleAsync(adminClient, UniqueEmail("auditor-list"), "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditorClient.GetAsync($"/api/stores?search={_runId}&pageSize=200");

        // Assert — auditor gets a result set that contains BOTH stores
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items");
        var returnedIds = items.EnumerateArray()
            .Select(x => x.GetProperty("id").GetString())
            .ToHashSet();

        Assert.Contains(storeX.ToString(), returnedIds);
        Assert.Contains(storeY.ToString(), returnedIds);
    }
}
