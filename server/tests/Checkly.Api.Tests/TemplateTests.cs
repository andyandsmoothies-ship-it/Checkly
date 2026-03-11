using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Tests for template endpoints: CRUD, auth guards, tree structure.
/// </summary>
public class TemplateTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public TemplateTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Auditor_Cannot_Create_Template()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "auditor@template.test", "Aud123!@", "Auditor", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.PostAsJsonAsync("/api/templates", new
        {
            title = "Should fail",
            type = "checklist"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Authenticated_User_Can_List_Templates()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "reader@template.test", "Read123!@", "Reader", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/templates");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task List_Stores_Returns_Ok()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "store-lister@test.test", "Store123!@", "Lister", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/stores");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
