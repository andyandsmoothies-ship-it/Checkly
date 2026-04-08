using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common;
using Checkly.Api.Features.Submissions;
using Xunit;

namespace Checkly.Api.Tests;

public class OwnershipScopeFilterTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public OwnershipScopeFilterTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task ListSubmissions_WithAuditorJwt_ReturnsOnlyOwnSubmissions()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        // 1. Create a Store
        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Owner Test Store" });
        storeResponse.EnsureSuccessStatusCode();
        var storeId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // 2. Create a Template
        var templateResponse = await adminClient.PostAsJsonAsync("/api/templates", new { Title = "Owner Test Template", Type = "audit" });
        templateResponse.EnsureSuccessStatusCode();
        var templateId = (await templateResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // 3. Create Auditor 1
        var (auditor1Token, auditor1Id) = await _factory.RegisterUserAsync(client, "auditor1@test.test", "Pass123!@", "Auditor One", "auditor");
        var auditor1Client = _factory.CreateAuthenticatedClient(auditor1Token);

        // 4. Create Auditor 2
        var (auditor2Token, auditor2Id) = await _factory.RegisterUserAsync(client, "auditor2@test.test", "Pass123!@", "Auditor Two", "auditor");
        var auditor2Client = _factory.CreateAuthenticatedClient(auditor2Token);

        // 5. Auditor 1 creates a submission
        var sub1Response = await auditor1Client.PostAsJsonAsync("/api/submissions", new { TemplateId = templateId, StoreId = storeId, Status = "draft" });
        sub1Response.EnsureSuccessStatusCode();
        var sub1Id = (await sub1Response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // 6. Auditor 2 creates a submission
        var sub2Response = await auditor2Client.PostAsJsonAsync("/api/submissions", new { TemplateId = templateId, StoreId = storeId, Status = "draft" });
        sub2Response.EnsureSuccessStatusCode();
        var sub2Id = (await sub2Response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // ACT
        // Auditor 1 fetches list
        var fetchResponse = await auditor1Client.GetAsync("/api/submissions");
        fetchResponse.EnsureSuccessStatusCode();
        var result = await fetchResponse.Content.ReadFromJsonAsync<PagedResult<SubmissionDto>>();

        // ASSERT
        // Should only see their own submission
        Assert.NotNull(result);
        Assert.Contains(result.Items, s => s.Id == sub1Id);
        Assert.DoesNotContain(result.Items, s => s.Id == sub2Id);

        // EXTRA DEFENSIVE: Asserts the exact count logic to prevent pagination leakage
        Assert.Equal(1, result.Items.Count(s => s.Id == sub1Id || s.Id == sub2Id)); 
    }

    [Fact]
    public async Task ListSubmissions_WithoutSubmissionsListCapability_Returns403()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        
        // Register an auditor. In Slice 2, this endpoint requires "submissions:list".
        // Until that capability is seeded and the endpoint is protected, this returns 200.
        // Once protected, and if the DB seed hasn't run or is missing for this role, it should return 403.
        var (token, _) = await _factory.RegisterUserAsync(client, "noperms@test.test", "Pass123!@", "No Perms", "auditor");
        var badClient = _factory.CreateAuthenticatedClient(token);

        // ACT
        var response = await badClient.GetAsync("/api/submissions");

        // ASSERT
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task ListSubmissions_WithAdminJwt_ReturnsAllSubmissions()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        // Create a Store and Template for the test
        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Admin Test Store" });
        storeResponse.EnsureSuccessStatusCode();
        var storeId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var templateResponse = await adminClient.PostAsJsonAsync("/api/templates", new { Title = "Admin Test Template", Type = "audit" });
        templateResponse.EnsureSuccessStatusCode();
        var templateId = (await templateResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // Create an auditor and a submission
        var (auditorToken, auditorId) = await _factory.RegisterUserAsync(client, "adminauditor@test.test", "Pass123!@", "Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);
        var subResponse = await auditorClient.PostAsJsonAsync("/api/submissions", new { TemplateId = templateId, StoreId = storeId, Status = "draft" });
        subResponse.EnsureSuccessStatusCode();
        var subId = (await subResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        // ACT
        var fetchResponse = await adminClient.GetAsync("/api/submissions");
        fetchResponse.EnsureSuccessStatusCode();
        var result = await fetchResponse.Content.ReadFromJsonAsync<PagedResult<SubmissionDto>>();

        // ASSERT
        // Admin should see submissions belonging to OTHERS
        Assert.NotNull(result);
        Assert.Contains(result.Items, s => s.Id == subId);
    }

    [Fact]
    public async Task ListSubmissions_WithStoreManagerMissingStoreId_ReturnsEmptyList()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        
        // Register a store_manager but DO NOT assign them to a store via UserGroup/Profile mapping.
        var (smToken, smId) = await _factory.RegisterUserAsync(client, "sm_nostore@test.test", "Pass123!@", "Orphan SM", "store_manager");
        var smClient = _factory.CreateAuthenticatedClient(smToken);

        // Create some data in the system as admin
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);
        
        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Unrelated Store" });
        storeResponse.EnsureSuccessStatusCode();
        var storeId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var templateResponse = await adminClient.PostAsJsonAsync("/api/templates", new { Title = "Unrelated Template", Type = "audit" });
        templateResponse.EnsureSuccessStatusCode();
        var templateId = (await templateResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var (auditorToken, auditorId) = await _factory.RegisterUserAsync(client, "unrelated@test.test", "Pass123!@", "Auditor", "auditor");
        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);
        var subResponse = await auditorClient.PostAsJsonAsync("/api/submissions", new { TemplateId = templateId, StoreId = storeId, Status = "draft" });
        subResponse.EnsureSuccessStatusCode();

        // ACT
        var fetchResponse = await smClient.GetAsync("/api/submissions");
        fetchResponse.EnsureSuccessStatusCode();
        var result = await fetchResponse.Content.ReadFromJsonAsync<PagedResult<SubmissionDto>>();

        // ASSERT
        // Since the SM has no StoreId, they should get 0 results defensively, not all results.
        Assert.NotNull(result);
        Assert.Empty(result.Items);
    }
}
