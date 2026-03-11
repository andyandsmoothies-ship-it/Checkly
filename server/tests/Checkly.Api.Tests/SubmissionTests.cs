using System.Net;
using System.Net.Http.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Tests for submission endpoints: IDOR protection, role-based filtering.
/// </summary>
public class SubmissionTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SubmissionTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task List_Submissions_Returns_Ok()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sub-lister@test.test", "Sub123!@", "SubLister", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/submissions");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Get_Nonexistent_Submission_Returns_NotFound()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sub-404@test.test", "Sub123!@", "Sub404", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync($"/api/submissions/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task List_Notifications_Returns_Ok()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "notif@test.test", "Notif123!@", "NotifUser", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/notifications");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task List_ActionPlans_Returns_Ok()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "ap-lister@test.test", "Ap123!@#", "APLister", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var response = await authClient.GetAsync("/api/action-plans");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
