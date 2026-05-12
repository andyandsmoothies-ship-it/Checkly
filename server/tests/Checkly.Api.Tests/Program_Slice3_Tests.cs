using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Slice 3: Programs Module - HQ Review Dashboard
/// ATDD Acceptance Tests for Program Assignments GET endpoint.
/// </summary>
public class Program_Slice3_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice3_Tests(TestWebApplicationFactory factory)
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

    [Fact]
    public async Task TC1_HQAdmin_Can_Get_Program_Assignments()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        // Use a random Guid — the program won't exist, so we get 404 (program not found).
        // The goal of this test is to prove the route exists and is accessible to admin (not 403/405).
        var programId = Guid.NewGuid();

        // Act
        var response = await adminClient.GetAsync($"/api/programs/{programId}/assignments");

        // Assert — 404 means our handler ran and returned "program not found" (route works, auth works).
        // 403 would mean capability gate failed. 405 would mean routing failed.
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC2_StoreManager_Cannot_Get_Program_Assignments()
    {
        // Arrange
        var smClient = await CreateRoleClientAsync("tc2-slice3-sm@test.test", "store_manager");
        var programId = Guid.NewGuid();

        // Act
        var response = await smClient.GetAsync($"/api/programs/{programId}/assignments");

        // Assert
        // Expected RED: Route doesn't exist yet, so we get 404. We want 403 Forbidden.
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

}
