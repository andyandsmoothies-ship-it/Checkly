using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Stores;

public class StoreStructuredAddress_ATDD_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public StoreStructuredAddress_ATDD_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task TC_SL1_01_DbSchema_HasAddressColumns()
    {
        // 1. Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 2. Act
        using var connection = db.Database.GetDbConnection();
        await connection.OpenAsync();
        using var command = connection.CreateCommand();
        command.CommandText = "SELECT column_name FROM information_schema.columns WHERE table_name = 'stores';";
        using var reader = await command.ExecuteReaderAsync();
        
        var columns = new List<string>();
        while (await reader.ReadAsync())
        {
            columns.Add(reader.GetString(0));
        }

        // 3. Assert
        Assert.Contains("address_province", columns);
        Assert.Contains("address_district", columns);
        Assert.Contains("address_ward", columns);
        Assert.Contains("address_street", columns);
    }

    [Fact]
    public async Task TC_SL1_02_CreateStore_WithInvalidProvince_ReturnsBadRequest()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var payload = new
        {
            name = "Test Store Invalid",
            province = "NotARealPlace"
        };
        var response = await authClient.PostAsJsonAsync("/api/stores", payload);

        // 3. Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            Assert.Fail($"Status: {response.StatusCode}. Route /api/stores not found or missing capability. Body: {body}");
        }
        
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("province", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task TC_SL1_05_GetLocations_ReturnsProvinceArray()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(client, "test_loc@checkly.test", "Aa1234567@", "Location Tester", "store_manager");
        var authClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var response = await authClient.GetAsync("/api/reference/locations");

        // 3. Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            Assert.Fail($"Status: {response.StatusCode}. Route /api/reference/locations not found. Body: {body}");
        }

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = JsonDocument.Parse(body);
        Assert.Equal(JsonValueKind.Array, json.RootElement.ValueKind);
        Assert.True(json.RootElement.GetArrayLength() > 0, "Expected non-empty array of provinces.");
        
        var first = json.RootElement[0].GetString();
        Assert.NotNull(first);
    }

    [Fact]
    public async Task TC_SL1_08_CreateStore_ReturnsAddressFields()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // 2. Act
        var payload = new
        {
            name = "Cửa hàng HCM",
            province = "Hồ Chí Minh",
            district = "Quận 1",
            ward = "Phường Bến Nghé",
            street = "123 Nguyễn Huệ"
        };
        var response = await authClient.PostAsJsonAsync("/api/stores", payload);

        // 3. Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            Assert.Fail($"Status: {response.StatusCode}. Route /api/stores might not be registered. Body: {body}");
        }
        
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        
        var json = JsonDocument.Parse(body);
        Assert.True(json.RootElement.TryGetProperty("addressProvince", out var p), "Missing addressProvince in response");
        Assert.Equal("Hồ Chí Minh", p.GetString());
        
        Assert.True(json.RootElement.TryGetProperty("addressDistrict", out var d), "Missing addressDistrict in response");
        Assert.Equal("Quận 1", d.GetString());
    }

    [Fact]
    public async Task Gap1_CreateStore_WithTooLongStreet_ReturnsBadRequest()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // 2. Act
        var payload = new
        {
            name = "Test Long Street",
            province = "Hồ Chí Minh",
            street = new string('A', 300) // Expect max 200/255
        };
        var response = await authClient.PostAsJsonAsync("/api/stores", payload);

        // 3. Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            Assert.Fail($"Status: {response.StatusCode}. Route /api/stores not found. Body: {body}");
        }

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("street", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Gap2_Hostile_AuditorCannotUpdateStoreAddress()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(client, "auditor_hostile@checkly.test", "Aa1234567@", "Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // We assume store ID exists or we just try to update a fake ID. The Auth check happens before DB lookup in Minimal APIs if configured right.
        // Or we use CreateStore.
        
        // 2. Act - Try to Create Store
        var payload = new
        {
            name = "Auditor Sneak Store",
            province = "Hồ Chí Minh"
        };
        var response = await auditorClient.PostAsJsonAsync("/api/stores", payload);

        // 3. Assert
        var body = await response.Content.ReadAsStringAsync();
        
        if (response.StatusCode == HttpStatusCode.NotFound)
        {
            Assert.Fail($"Status: {response.StatusCode}. Route /api/stores not found. Body: {body}");
        }

        // Must be forbidden due to lacking 'stores:write' capability
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
