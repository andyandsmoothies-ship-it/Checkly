using System.Net;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Tests.Features.Users;

public class SearchUsers_Authorization_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SearchUsers_Authorization_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task SearchUsers_AsAdmin_ReturnsOk()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.GetAsync("/api/users");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SearchUsers_AsAreaManager_ReturnsOk()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var user = await _factory.RegisterUserAsync(client, $"am_{Guid.NewGuid()}@test.com", "Pass123!@", "AM User", "area_manager", adminToken);
        var authClient = _factory.CreateAuthenticatedClient(user.Token);

        // Act
        var response = await authClient.GetAsync("/api/users");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SearchUsers_AsStoreManager_ReturnsForbidden()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var user = await _factory.RegisterUserAsync(client, $"sm_{Guid.NewGuid()}@test.com", "Pass123!@", "SM User", "store_manager", adminToken);
        var authClient = _factory.CreateAuthenticatedClient(user.Token);

        // Act
        var response = await authClient.GetAsync("/api/users");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task SearchUsers_AsAuditor_ReturnsForbidden()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var user = await _factory.RegisterUserAsync(client, $"auditor_{Guid.NewGuid()}@test.com", "Pass123!@", "Auditor User", "auditor", adminToken);
        var authClient = _factory.CreateAuthenticatedClient(user.Token);

        // Act
        var response = await authClient.GetAsync("/api/users");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
