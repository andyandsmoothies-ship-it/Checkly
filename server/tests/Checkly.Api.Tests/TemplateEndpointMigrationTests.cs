using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Auth;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Checkly.Api.Tests;

public class TemplateEndpointMigrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public TemplateEndpointMigrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Auditor_Cannot_UpdateTemplate_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "upd-auditor@template.test", "Aud123!@", "Auditor No Update", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.PutAsJsonAsync($"/api/templates/{Guid.NewGuid()}",
            new { title = "Hacked" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_DeleteTemplate_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "del-auditor@template.test", "Aud123!@", "Auditor No Delete", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.DeleteAsync($"/api/templates/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_Call_UpdateTemplate_NeverForbidden()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var response = await adminClient.PutAsJsonAsync($"/api/templates/{Guid.NewGuid()}",
            new { title = "Admin Update Attempt" });

        // Auth passed (admin has templates:update). May be 404 (template not found) or 200.
        // Must NOT be 403 Forbidden.
        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_Cannot_CreateGroup_Returns403()
    {
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "grp-auditor@template.test", "Aud123!@", "Auditor No Group", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.PostAsJsonAsync(
            $"/api/templates/{Guid.NewGuid()}/groups",
            new { title = "Hacked Group" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
