using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Auth;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Checkly.Api.Tests;

public class Slice3EndpointMigrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Slice3EndpointMigrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Auditor_Cannot_CreateStore_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl3-store-auditor@test.test", "Aud123!@", "Store Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.PostAsJsonAsync("/api/stores",
            new { name = "Hacked Store", province = "Hà Nội" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_CreateStore_NeverForbidden()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var response = await adminClient.PostAsJsonAsync("/api/stores",
            new { name = $"Slice3 Store {Guid.NewGuid():N}", province = "Hà Nội" });

        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_ListUserGroups_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl3-ug-auditor@test.test", "Aud123!@", "UG Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.GetAsync("/api/user-groups");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_GetTopFailures_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl3-analytics-auditor@test.test", "Aud123!@", "Analytics Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.GetAsync("/api/analytics/top-failures");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_GetTopFailures_NeverForbidden()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var response = await adminClient.GetAsync("/api/analytics/top-failures");

        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
