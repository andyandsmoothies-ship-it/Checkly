using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 6: Programs Module - CRUD Parity (Update & Archive)
/// ATDD Acceptance Tests
/// </summary>
public class Program_Slice6_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice6_Tests(TestWebApplicationFactory factory)
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

    private async Task<Guid> CreateProgramAsync(HttpClient adminClient, string title)
    {
        var templateId = await CreateTemplateAsync(adminClient, $"{title} Template");
        var storeId = await CreateStoreAsync(adminClient, $"{title} Store");

        var request = new
        {
            templateId = templateId,
            storeIds = new[] { storeId },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Testing",
            title = title
        };

        var response = await adminClient.PostAsJsonAsync("/api/programs", request);
        Assert.True(response.IsSuccessStatusCode, "Setup: Could not create program");
        
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(body.GetProperty("programId").GetString()!);
    }

    [Fact]
    public async Task TC_U1_Admin_Updates_Active_Program_ReturnsOk()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC U1 Program");

        var request = new
        {
            title = "Updated TC U1 Title",
            deadline = DateTimeOffset.UtcNow.AddDays(14),
            category = "Compliance v2"
        };

        var response = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", request);
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Updated TC U1 Title", body.GetProperty("title").GetString());
        Assert.Equal("Compliance v2", body.GetProperty("category").GetString());
    }

    [Fact]
    public async Task TC_U2_StoreManager_Updates_Program_ReturnsForbidden()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC U2 Program");
        
        var smClient = await CreateRoleClientAsync("tc_u2@test.test", "store_manager");

        var request = new { title = "Hacked Title", deadline = DateTimeOffset.UtcNow.AddDays(14), category = "Hacked" };
        var response = await smClient.PutAsJsonAsync($"/api/programs/{programId}", request);
        
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC_U3_Admin_Updates_NonExistent_Program_ReturnsNotFound()
    {
        var adminClient = await CreateAdminClientAsync();
        
        var request = new { title = "New Title", deadline = DateTimeOffset.UtcNow.AddDays(14), category = "Test" };
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{Guid.NewGuid()}", request);
        
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC_U4_Admin_Updates_With_Past_Deadline_ReturnsBadRequest()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC U4 Program");
        
        var request = new { title = "New Title", deadline = DateTimeOffset.UtcNow.AddDays(-1), category = "Test" };
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", request);
        
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC_U5_Gap_Admin_Updates_Cancelled_Program_ReturnsBadRequest()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC U5 Program");
        
        // Archive it first
        var archiveResponse = await adminClient.DeleteAsync($"/api/programs/{programId}");
        if (!archiveResponse.IsSuccessStatusCode) Assert.Fail($"Status: {archiveResponse.StatusCode}. Body: {await archiveResponse.Content.ReadAsStringAsync()}");

        // Try to update
        var request = new { title = "New Title", deadline = DateTimeOffset.UtcNow.AddDays(14), category = "Test" };
        var updateResponse = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", request);
        
        Assert.Equal(HttpStatusCode.BadRequest, updateResponse.StatusCode);
    }

    [Fact]
    public async Task TC_U6_Gap_Admin_Updates_With_Empty_Title_ReturnsBadRequest()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC U6 Program");
        
        var request = new { title = "", deadline = DateTimeOffset.UtcNow.AddDays(14), category = "Test" };
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", request);
        
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task TC_A1_Admin_Archives_Active_Program_ReturnsNoContent()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC A1 Program");
        
        var response = await adminClient.DeleteAsync($"/api/programs/{programId}");
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify status changed to cancelled via GET
        var getResponse = await adminClient.GetAsync($"/api/programs/{programId}");
        if (!getResponse.IsSuccessStatusCode) Assert.Fail($"Status: {getResponse.StatusCode}. Body: {await getResponse.Content.ReadAsStringAsync()}");
        var body = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("cancelled", body.GetProperty("status").GetString());
    }

    [Fact]
    public async Task TC_A2_StoreManager_Archives_Program_ReturnsForbidden()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC A2 Program");
        
        var smClient = await CreateRoleClientAsync("tc_a2@test.test", "store_manager");

        var response = await smClient.DeleteAsync($"/api/programs/{programId}");
        
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC_A3_Admin_Archives_NonExistent_Program_ReturnsNotFound()
    {
        var adminClient = await CreateAdminClientAsync();
        var response = await adminClient.DeleteAsync($"/api/programs/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC_A4_Admin_Archives_Already_Cancelled_Program_ReturnsBadRequest()
    {
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient, "TC A4 Program");
        
        // Archive it first
        var archive1 = await adminClient.DeleteAsync($"/api/programs/{programId}");
        if (!archive1.IsSuccessStatusCode) Assert.Fail($"Status: {archive1.StatusCode}. Body: {await archive1.Content.ReadAsStringAsync()}");

        // Archive again
        var archive2 = await adminClient.DeleteAsync($"/api/programs/{programId}");
        Assert.Equal(HttpStatusCode.BadRequest, archive2.StatusCode);
    }
}
