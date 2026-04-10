using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Auth;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Checkly.Api.Tests;

public class Slice4EndpointMigrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Slice4EndpointMigrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Auditor_Cannot_ListUsers_Returns403()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl4-listusers-auditor@test.test", "Aud123!@", "List Users Auditor", "auditor", adminToken);
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.GetAsync("/api/admin/users");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_ListUsers_NeverForbidden()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var response = await adminClient.GetAsync("/api/admin/users");

        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_GetLogs_Returns403()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl4-logs-auditor@test.test", "Aud123!@", "Logs Auditor", "auditor", adminToken);
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.GetAsync("/api/admin/logs");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_TransferStore_Returns403()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "sl4-transfer-auditor@test.test", "Aud123!@", "Transfer Auditor", "auditor", adminToken);
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.PostAsJsonAsync(
            $"/api/admin/stores/{Guid.NewGuid()}/transfer",
            new { newManagerId = Guid.NewGuid() });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Unauthenticated_Cannot_ListUsers_Returns401()
    {
        var client = _factory.CreateClient(); // No auth header

        var response = await client.GetAsync("/api/admin/users");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
