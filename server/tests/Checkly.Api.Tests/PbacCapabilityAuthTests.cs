using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// PBAC Slice 1 integration tests.
/// Tests verify that CapabilityAuthorizationHandler correctly grants/denies
/// access and that GET /api/system/capabilities returns role-scoped capabilities.
/// </summary>
[Trait("Category", "Pbac")]
public class PbacCapabilityAuthTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public PbacCapabilityAuthTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    [Trait("Category", "Pbac")]
    public async Task CreateTemplate_WithAdminJwt_RequireCapability_Returns201()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync("/api/templates", new
        {
            title = "PBAC Capability Test Template",
            type = "checklist"
        });

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Pbac")]
    public async Task CreateTemplate_WithAuditorJwt_RequireCapability_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "pbac-auditor@test.test", "Aud123!@#", "PBAC Auditor", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await authClient.PostAsJsonAsync("/api/templates", new
        {
            title = "Should be forbidden",
            type = "checklist"
        });

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Pbac")]
    public async Task GetCapabilities_WithAdminJwt_ReturnsAdminCapabilities()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.GetAsync("/api/system/capabilities");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("admin", json.GetProperty("role").GetString());

        var capabilities = json.GetProperty("capabilities");
        Assert.True(
            capabilities.EnumerateArray().Any(c => c.GetString() == "templates:create"),
            "Admin must have 'templates:create' capability in PBAC cache.");
    }

    [Fact]
    [Trait("Category", "Pbac")]
    public async Task GetCapabilities_Unauthenticated_Returns401()
    {
        // Arrange
        var client = _factory.CreateClient(); // No auth header

        // Act
        var response = await client.GetAsync("/api/system/capabilities");

        // Assert
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
