using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Areas Entity — Slice 1 (CRUD API).
/// These tests define the acceptance criteria for the Area entity.
/// They will FAIL (RED) until the production code is implemented.
/// </summary>
public class AreaTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public AreaTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private static string UniqueEmail(string prefix) => $"{prefix}-{_runId}@area.test";

    // ─── AC1: GET /api/areas returns 200 OK ───
    // Citation: analysis_areas_entity.md:185

    [Fact]
    public async Task List_Areas_Returns_Ok()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("lister"), "Area123!@", "Area Lister", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/areas");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ─── AC2: POST /api/areas creates area, returns 201 ───
    // Citation: analysis_areas_entity.md:186

    [Fact]
    public async Task Admin_Can_Create_Area()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var (adminToken, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("create-admin"), "Admin123!@", "Area Admin", "admin",
            adminToken: bootstrapToken);

        var authClient = _factory.CreateAuthenticatedClient(adminToken);
        var response = await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = "Miền Bắc",
            code = $"north-{_runId}"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("id", out _));
        Assert.Equal("Miền Bắc", json.GetProperty("name").GetString());
        Assert.Equal($"north-{_runId}", json.GetProperty("code").GetString());
        Assert.True(json.GetProperty("isActive").GetBoolean());
    }

    // ─── AC3: Duplicate code returns 409 Conflict ───
    // Citation: analysis_areas_entity.md:187

    [Fact]
    public async Task Create_Area_With_Duplicate_Code_Returns_Conflict()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var (adminToken, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("dup-admin"), "Admin123!@", "Dup Admin", "admin",
            adminToken: bootstrapToken);

        var authClient = _factory.CreateAuthenticatedClient(adminToken);
        var dupCode = $"south-{_runId}";

        // Create first area
        await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = "Miền Nam",
            code = dupCode
        });

        // Attempt duplicate
        var response = await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = "Nam Bộ",
            code = dupCode
        });

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    // ─── AC4: PUT /api/areas/{id} can rename and deactivate ───
    // Citation: analysis_areas_entity.md:188

    [Fact]
    public async Task Admin_Can_Update_Area()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var (adminToken, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("update-admin"), "Admin123!@", "Update Admin", "admin",
            adminToken: bootstrapToken);

        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Create area first
        var createResponse = await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = "Miền Trung",
            code = $"central-{_runId}"
        });
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var areaId = created.GetProperty("id").GetString();

        // Update it
        var updateResponse = await authClient.PutAsJsonAsync($"/api/areas/{areaId}", new
        {
            name = "Miền Trung (cũ)",
            isActive = false
        });

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        var updated = await updateResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Miền Trung (cũ)", updated.GetProperty("name").GetString());
        Assert.False(updated.GetProperty("isActive").GetBoolean());
    }

    // ─── AC5: Non-admin cannot create area ───
    // Citation: platform-rules.md §4, analysis_areas_entity.md:182

    [Fact]
    public async Task Auditor_Cannot_Create_Area()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("auditor"), "Aud123!@", "Area Auditor", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = "Should Fail",
            code = $"fail-{_runId}"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
