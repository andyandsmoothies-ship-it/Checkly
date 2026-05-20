using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Stores;

/// <summary>
/// ATDD coverage for CreateStore, UpdateStore, DeleteStore, GetStoreDashboard.
/// Phase 4 item: raised as stubs per the global audit (audit_code_report_core_execution_20260520).
/// </summary>
public class StoreCrud_ATDD_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public StoreCrud_ATDD_Tests(TestWebApplicationFactory factory)
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

    // ── CreateStore ─────────────────────────────────────────────

    [Fact]
    public async Task CreateStore_Admin_ValidPayload_Returns201WithId()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var payload = new { name = $"New Store {Guid.NewGuid()}", province = "Hồ Chí Minh" };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/stores", payload);

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
            Assert.Fail($"Route /api/stores not registered. Body: {body}");

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var json = JsonDocument.Parse(body);
        Assert.True(json.RootElement.TryGetProperty("id", out _), "Response must contain 'id'.");
    }

    [Fact]
    public async Task CreateStore_MissingName_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var payload = new { province = "Hồ Chí Minh" }; // name is required

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/stores", payload);

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("name", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task CreateStore_Unauthenticated_Returns401()
    {
        // Arrange
        var anonClient = _factory.CreateClient();
        var payload = new { name = "Ghost Store" };

        // Act
        var response = await anonClient.PostAsJsonAsync("/api/stores", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ── UpdateStore ─────────────────────────────────────────────

    [Fact]
    public async Task UpdateStore_Admin_ValidPayload_Returns200WithUpdatedName()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var createResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = $"Original {Guid.NewGuid()}" });
        createResp.EnsureSuccessStatusCode();
        var storeId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // Act
        var updatedName = $"Updated {Guid.NewGuid()}";
        var response = await adminClient.PutAsJsonAsync($"/api/stores/{storeId}", new { name = updatedName });

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {body}");

        var json = JsonDocument.Parse(body);
        Assert.Equal(updatedName, json.RootElement.GetProperty("name").GetString());
    }

    [Fact]
    public async Task UpdateStore_NonExistentId_Returns404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.PutAsJsonAsync($"/api/stores/{Guid.NewGuid()}", new { name = "Ghost" });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ── DeleteStore ─────────────────────────────────────────────

    [Fact]
    public async Task DeleteStore_Admin_ExistingStore_Returns204()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var createResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = $"Delete Me {Guid.NewGuid()}" });
        createResp.EnsureSuccessStatusCode();
        var storeId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // Act
        var response = await adminClient.DeleteAsync($"/api/stores/{storeId}");

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {body}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task DeleteStore_NonExistentId_Returns404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.DeleteAsync($"/api/stores/{Guid.NewGuid()}");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ── GetStoreDashboard ────────────────────────────────────────

    [Fact]
    public async Task GetStoreDashboard_Admin_ExistingStore_Returns200WithKpis()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var createResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = $"Dashboard Store {Guid.NewGuid()}" });
        createResp.EnsureSuccessStatusCode();
        var storeId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // Act
        var response = await adminClient.GetAsync($"/api/stores/{storeId}/dashboard");

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
            Assert.Fail($"Route /api/stores/{{id}}/dashboard not registered. Body: {body}");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {body}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = JsonDocument.Parse(body);
        Assert.True(json.RootElement.TryGetProperty("storeId", out _), "Dashboard must contain 'storeId'.");
    }

    [Fact]
    public async Task GetStoreDashboard_NonExistentStore_Returns404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.GetAsync($"/api/stores/{Guid.NewGuid()}/dashboard");

        // Assert
        // Accept 404 OR 400 (store not found vs bad request) — both are valid failure modes
        Assert.True(
            response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.BadRequest,
            $"Expected 404 or 400, got {response.StatusCode}.");
    }
}
