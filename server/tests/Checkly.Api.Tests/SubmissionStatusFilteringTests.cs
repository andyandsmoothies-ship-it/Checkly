using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common;
using Checkly.Api.Features.Submissions;
using Checkly.Api.Features.Templates;

namespace Checkly.Api.Tests;

public class SubmissionStatusFilteringTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SubmissionStatusFilteringTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task ListSubmissions_WhenFilteredByStatus_ReturnsOnlyMatchingSubmissions()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        // 1. Create a Store
        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Test Store" });
        storeResponse.EnsureSuccessStatusCode();
        var storeJson = await storeResponse.Content.ReadFromJsonAsync<JsonElement>();
        var storeId = storeJson.GetProperty("id").GetGuid();

        // 2. Create a Template
        var templateResponse = await adminClient.PostAsJsonAsync("/api/templates", new { Title = "Test Template" });
        templateResponse.EnsureSuccessStatusCode();
        var templateJson = await templateResponse.Content.ReadFromJsonAsync<JsonElement>();
        var templateId = templateJson.GetProperty("id").GetGuid();

        // 3. Create an auditor
        var (auditorToken, auditorId) = await _factory.RegisterUserAsync(
            client, "status-tester@test.test", "Status123!@", "StatusTester", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // 4. Create a 'draft' submission
        var draftResponse = await auditorClient.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "draft"
        });
        draftResponse.EnsureSuccessStatusCode();

        // 5. Create a 'scheduled' submission
        var scheduledResponse = await auditorClient.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });
        scheduledResponse.EnsureSuccessStatusCode();

        // Act & Assert for 'draft'
        var draftFilterResponse = await auditorClient.GetAsync("/api/submissions?status=draft");
        draftFilterResponse.EnsureSuccessStatusCode();
        var draftResult = await draftFilterResponse.Content.ReadFromJsonAsync<PagedResult<SubmissionDto>>();
        Assert.Contains(draftResult!.Items, s => s.Status == "draft");
        Assert.DoesNotContain(draftResult!.Items, s => s.Status == "scheduled");

        // Act & Assert for 'scheduled'
        var scheduledFilterResponse = await auditorClient.GetAsync("/api/submissions?status=scheduled");
        scheduledFilterResponse.EnsureSuccessStatusCode();
        var scheduledResult = await scheduledFilterResponse.Content.ReadFromJsonAsync<PagedResult<SubmissionDto>>();
        Assert.Contains(scheduledResult!.Items, s => s.Status == "scheduled");
        Assert.DoesNotContain(scheduledResult!.Items, s => s.Status == "draft");
    }
}
