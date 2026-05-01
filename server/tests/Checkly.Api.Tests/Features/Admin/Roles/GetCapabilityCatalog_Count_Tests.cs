using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Features.Admin.Roles;

namespace Checkly.Api.Tests.Features.Admin.Roles;

public class GetCapabilityCatalog_Count_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GetCapabilityCatalog_Count_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetCapabilityCatalog_Returns17Capabilities_IncludingProgramExecution()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act
        var response = await client.GetAsync("/api/admin/capabilities/catalog");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var catalog = await response.Content.ReadFromJsonAsync<CatalogResponse>();
        
        Assert.NotNull(catalog);
        Assert.Contains("admin:access", catalog.Capabilities);
        Assert.Contains("analytics:area", catalog.Capabilities);
        Assert.Contains("analytics:view", catalog.Capabilities);
        Assert.Contains("programs:execute", catalog.Capabilities);
        Assert.Equal(17, catalog.Capabilities.Length);
    }
}
