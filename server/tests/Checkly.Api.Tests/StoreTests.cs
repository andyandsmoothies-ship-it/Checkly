using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Store Entity — GET /api/stores/{id} and related guards.
/// Authored to satisfy EDD proof requirement from Sentinel failure report.
/// Citation: implementation_plan_infra_slice_3.md.resolved (Verification Plan)
/// </summary>
public class StoreTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public StoreTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> AdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    // ─── AC1: GET /api/stores/{id} returns 200 for an active store ────────────

    [Fact]
    public async Task GetStore_ActiveStore_ReturnsOk()
    {
        var admin = await AdminClientAsync();
        var createResp = await admin.PostAsJsonAsync("/api/stores", new { name = $"Get Active {_runId}", province = "Hà Nội" });
        createResp.EnsureSuccessStatusCode();
        var storeId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString();

        var response = await admin.GetAsync($"/api/stores/{storeId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(storeId, body.GetProperty("id").GetString());
        Assert.Equal($"Get Active {_runId}", body.GetProperty("name").GetString());
    }

    // ─── AC2: GET /api/stores/{id} returns 404 for a deactivated store ────────
    // This is the core Slice 2 bypass guard for GetStore.

    [Fact]
    public async Task GetStore_DeactivatedStore_ReturnsNotFound()
    {
        var admin = await AdminClientAsync();

        // Create store then deactivate it via UpdateStore
        var createResp = await admin.PostAsJsonAsync("/api/stores", new { name = $"Get Inactive {_runId}", province = "Hà Nội" });
        createResp.EnsureSuccessStatusCode();
        var stored = await createResp.Content.ReadFromJsonAsync<JsonElement>();
        var storeId = stored.GetProperty("id").GetString();

        // Deactivate via PUT
        await admin.PutAsJsonAsync($"/api/stores/{storeId}", new
        {
            name = $"Get Inactive {_runId}",
            isActive = false,
            province = "Hà Nội"
        });

        // Act — try to GET the deactivated store
        var response = await admin.GetAsync($"/api/stores/{storeId}");

        // Assert — must return 404, not 200
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ─── AC3: GET /api/stores/{id} returns 404 for unknown GUID ──────────────

    [Fact]
    public async Task GetStore_UnknownId_ReturnsNotFound()
    {
        var admin = await AdminClientAsync();
        var response = await admin.GetAsync($"/api/stores/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ─── AC4: Name too long returns 400 ───────────────────────────────────────

    [Fact]
    public async Task CreateStore_NameTooLong_ReturnsBadRequest()
    {
        var admin = await AdminClientAsync();
        var tooLong = new string('A', 201);
        var response = await admin.PostAsJsonAsync("/api/stores", new { name = tooLong });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
