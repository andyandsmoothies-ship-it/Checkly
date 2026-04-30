using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 1: Programs Module - HQ Assignment Engine
/// ATDD Acceptance Tests for Program Assignment
/// </summary>
public class Program_Slice1_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice1_Tests(TestWebApplicationFactory factory)
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

    private async Task<HttpClient> CreateRoleClientAsync(string email, string role)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, _) = await _factory.RegisterUserAsync(
            client, email, $"Test123!@#{role}", $"Test {role}", role, adminToken);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<Guid> CreateTemplateAsync(HttpClient adminClient, string title)
    {
        var response = await adminClient.PostAsJsonAsync("/api/templates", new
        {
            title = title,
            type = "qc"
        });
        Assert.True(response.IsSuccessStatusCode, "Setup: Could not create template");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/stores", new { name });
        Assert.True(response.IsSuccessStatusCode, "Setup: Could not create store");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    [Fact]
    public async Task TC1_CreateProgram_WithValidData_ReturnsCreated()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "TC1 Template");
        var store1 = await CreateStoreAsync(adminClient, "TC1 Store A");
        var store2 = await CreateStoreAsync(adminClient, "TC1 Store B");
        var store3 = await CreateStoreAsync(adminClient, "TC1 Store C");

        var request = new
        {
            templateId = templateId,
            storeIds = new[] { store1, store2, store3 },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = "TC1 Program"
        };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("programId", out _));
        Assert.Equal(3, body.GetProperty("assignmentCount").GetInt32());
    }

    [Fact]
    public async Task TC2_CreateProgram_AsStoreManager_ReturnsForbidden()
    {
        // Arrange
        var smClient = await CreateRoleClientAsync("tc2-sm@test.test", "store_manager");

        var request = new
        {
            templateId = Guid.NewGuid(),
            storeIds = new[] { Guid.NewGuid() },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = "TC2 Program"
        };

        // Act
        var response = await smClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        // Expected RED: Capability programs:create not seeded/implemented yet.
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC3_CreateProgram_WithEmptyStoreIds_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "TC3 Template");

        var request = new
        {
            templateId = templateId,
            storeIds = Array.Empty<Guid>(), // Empty!
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = "TC3 Program"
        };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC4_CreateProgram_WithNonExistentTemplateId_ReturnsNotFound()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var store1 = await CreateStoreAsync(adminClient, "TC4 Store");

        var request = new
        {
            templateId = Guid.NewGuid(), // Doesn't exist!
            storeIds = new[] { store1 },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = "TC4 Program"
        };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC5_ListPrograms_ReturnsPaginatedResult()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        
        // Act
        var response = await adminClient.GetAsync("/api/programs");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("items", out _));
        Assert.True(body.TryGetProperty("totalCount", out _));
    }

    [Fact]
    public async Task TC6_ListPrograms_WhenEmpty_ReturnsEmptyItems()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        // Add a random page that definitely has nothing
        var response = await adminClient.GetAsync("/api/programs?page=999");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Empty(items);
    }

    [Fact]
    public async Task GapAC1_CreateProgram_WithInvalidStoreId_ReturnsBadRequestOrServerError()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "GapAC1 Template");

        var request = new
        {
            templateId = templateId,
            storeIds = new[] { Guid.NewGuid() }, // Store doesn't exist
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = "GapAC1 Program"
        };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        Assert.False(response.IsSuccessStatusCode, "Creating a program with a non-existent storeId should fail");
    }

    [Fact]
    public async Task GapAC2_CreateProgram_WithPastDeadline_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "GapAC2 Template");
        var store1 = await CreateStoreAsync(adminClient, "GapAC2 Store");

        var request = new
        {
            templateId = templateId,
            storeIds = new[] { store1 },
            deadline = DateTimeOffset.UtcNow.AddDays(-1), // Past!
            category = "Testing",
            title = "GapAC2 Program"
        };

        // Act
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
