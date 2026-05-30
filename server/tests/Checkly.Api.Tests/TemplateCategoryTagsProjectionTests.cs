using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 2: Audit Template CategoryTags Projection & Sync
/// Source: implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md
/// 
/// These tests verify that category tags are correctly projected via the GET /api/templates/{id} 
/// and offline sync GET /api/sync/templates endpoints, ensuring backward compatibility.
/// </summary>
public class TemplateCategoryTagsProjectionTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public TemplateCategoryTagsProjectionTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
        _client = _factory.CreateClient();
    }

    private async Task<HttpClient> GetAdminClientAsync()
    {
        var token = await _factory.LoginBootstrapAdminAsync(_client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<string> CreateTemplateAsync(HttpClient admin, string title)
    {
        var response = await admin.PostAsJsonAsync("/api/templates", new
        {
            title,
            type = "qc",
            description = "Sync CategoryTags projection test template"
        });
        
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Setup failed: Could not create template. Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    // ── TC-CAT-03: Sync Endpoint Includes CategoryTags ──
    [Fact]
    public async Task Admin_Can_Sync_Category_Tags()
    {
        // Arrange
        var adminClient = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "Sync Template Tags");

        var treePayload = new
        {
            Title = "Sync Template Tags",
            Type = "qc",
            Description = "Sync CategoryTags projection test template",
            ScoringLogicConfig = (string?)null,
            DisplayNoun = (string?)null,
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Sync FOH Area",
                    Description = "FOH hygiene",
                    Weight = (decimal?)10.0m,
                    MaxDeductionPoints = (decimal?)null,
                    MinusPerFault = (decimal?)null,
                    OrderIndex = 0,
                    Metadata = (string?)null,
                    CategoryTags = new[] { "Kitchen-Sync", "FOH-Sync" },
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Sync Temp Check",
                            Description = "Verify prep temp",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            IsCcp = true,
                            IsRisk = false,
                            MinusImpact = (decimal?)null,
                            MaxDeductionPoints = (decimal?)null,
                            OrderIndex = 0,
                            Metadata = (string?)null,
                            CategoryTags = new[] { "CCP-Sync" }
                        }
                    }
                }
            }
        };

        // Save the tree to establish the tags
        var saveResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}/tree", treePayload);
        if (!saveResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SaveTemplateTree failed. Status: {saveResponse.StatusCode}. Body: {await saveResponse.Content.ReadAsStringAsync()}");
        }

        // Act - Trigger Sync from a far-past epoch to retrieve all deltas
        var sinceTimestamp = DateTimeOffset.UtcNow.AddMinutes(-5).ToString("o");
        var syncResponse = await adminClient.GetAsync($"/api/sync/templates?since={Uri.EscapeDataString(sinceTimestamp)}");
        if (!syncResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SyncTemplates failed. Status: {syncResponse.StatusCode}. Body: {await syncResponse.Content.ReadAsStringAsync()}");
        }

        var syncBody = await syncResponse.Content.ReadFromJsonAsync<JsonElement>();

        // Assert groups in sync response contain categoryTags
        Assert.True(syncBody.TryGetProperty("groups", out var groupsElement), "Sync response should contain 'groups' array.");
        var syncGroups = groupsElement.EnumerateArray().ToList();
        var targetGroup = syncGroups.FirstOrDefault(g => g.GetProperty("title").GetString() == "Sync FOH Area");
        
        Assert.NotNull(targetGroup.ValueKind == JsonValueKind.Undefined ? null : (object?)targetGroup);
        Assert.True(targetGroup.TryGetProperty("categoryTags", out var groupTagsElement), "SyncGroupDto should include 'categoryTags' property.");
        Assert.Equal(JsonValueKind.Array, groupTagsElement.ValueKind);
        var groupTagsList = groupTagsElement.EnumerateArray().Select(x => x.GetString()).ToList();
        Assert.Contains("Kitchen-Sync", groupTagsList);
        Assert.Contains("FOH-Sync", groupTagsList);

        // Assert criteria in sync response contain categoryTags
        Assert.True(syncBody.TryGetProperty("criteria", out var criteriaElement), "Sync response should contain 'criteria' array.");
        var syncCriteria = criteriaElement.EnumerateArray().ToList();
        var targetCriterion = syncCriteria.FirstOrDefault(c => c.GetProperty("label").GetString() == "Sync Temp Check");

        Assert.NotNull(targetCriterion.ValueKind == JsonValueKind.Undefined ? null : (object?)targetCriterion);
        Assert.True(targetCriterion.TryGetProperty("categoryTags", out var critTagsElement), "CriterionDto in sync should include 'categoryTags' property.");
        Assert.Equal(JsonValueKind.Array, critTagsElement.ValueKind);
        var critTagsList = critTagsElement.EnumerateArray().Select(x => x.GetString()).ToList();
        Assert.Contains("CCP-Sync", critTagsList);
    }

    // ── TC-CAT-04: Backward Compat — Null tags do not break responses ──
    [Fact]
    public async Task Old_Templates_Project_Null_Category_Tags()
    {
        // Arrange
        var adminClient = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "Legacy Un-tagged Template");

        // Construct request WITHOUT CategoryTags fields
        var treePayload = new
        {
            Title = "Legacy Un-tagged Template",
            Type = "qc",
            Description = "Sync CategoryTags projection test template",
            ScoringLogicConfig = (string?)null,
            DisplayNoun = (string?)null,
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Legacy Area",
                    Description = "FOH hygiene",
                    Weight = (decimal?)10.0m,
                    MaxDeductionPoints = (decimal?)null,
                    MinusPerFault = (decimal?)null,
                    OrderIndex = 0,
                    Metadata = (string?)null,
                    // CategoryTags is explicitly omitted or null
                    CategoryTags = (string[]?)null,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Legacy Temp Check",
                            Description = "Verify prep temp",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            IsCcp = true,
                            IsRisk = false,
                            MinusImpact = (decimal?)null,
                            MaxDeductionPoints = (decimal?)null,
                            OrderIndex = 0,
                            Metadata = (string?)null,
                            // CategoryTags is explicitly omitted or null
                            CategoryTags = (string[]?)null
                        }
                    }
                }
            }
        };

        // Save the tree
        var saveResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}/tree", treePayload);
        if (!saveResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SaveTemplateTree failed. Status: {saveResponse.StatusCode}. Body: {await saveResponse.Content.ReadAsStringAsync()}");
        }

        // Act - Get the template via GET
        var getResponse = await adminClient.GetAsync($"/api/templates/{templateId}");
        if (!getResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"GetTemplate failed. Status: {getResponse.StatusCode}. Body: {await getResponse.Content.ReadAsStringAsync()}");
        }

        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();

        // Assert - Verify it successfully projected as null
        var groupsElement = getBody.GetProperty("groups");
        var group = groupsElement.EnumerateArray().First();
        Assert.True(group.TryGetProperty("categoryTags", out var groupTagsElement));
        Assert.Equal(JsonValueKind.Null, groupTagsElement.ValueKind);

        var criterion = group.GetProperty("criteria").EnumerateArray().First();
        Assert.True(criterion.TryGetProperty("categoryTags", out var critTagsElement));
        Assert.Equal(JsonValueKind.Null, critTagsElement.ValueKind);

        // Act - Verify Sync delta projects them safely as null
        var sinceTimestamp = DateTimeOffset.UtcNow.AddMinutes(-5).ToString("o");
        var syncResponse = await adminClient.GetAsync($"/api/sync/templates?since={Uri.EscapeDataString(sinceTimestamp)}");
        if (!syncResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SyncTemplates failed. Status: {syncResponse.StatusCode}. Body: {await syncResponse.Content.ReadAsStringAsync()}");
        }

        var syncBody = await syncResponse.Content.ReadFromJsonAsync<JsonElement>();
        
        var syncGroups = syncBody.GetProperty("groups").EnumerateArray();
        var targetGroup = syncGroups.FirstOrDefault(g => g.GetProperty("title").GetString() == "Legacy Area");
        Assert.True(targetGroup.TryGetProperty("categoryTags", out var syncGroupTagsElement));
        Assert.Equal(JsonValueKind.Null, syncGroupTagsElement.ValueKind);

        var syncCriteria = syncBody.GetProperty("criteria").EnumerateArray();
        var targetCriterion = syncCriteria.FirstOrDefault(c => c.GetProperty("label").GetString() == "Legacy Temp Check");
        Assert.True(targetCriterion.TryGetProperty("categoryTags", out var syncCritTagsElement));
        Assert.Equal(JsonValueKind.Null, syncCritTagsElement.ValueKind);
    }

    // ── TC-CAT-05: Top-Level Template CategoryTag CRUD and Sync ──
    [Fact]
    public async Task Admin_Can_CRUD_Template_With_TopLevel_CategoryTag()
    {
        // Arrange
        var adminClient = await GetAdminClientAsync();
        
        // 1. Create template with CategoryTag
        var createResponse = await adminClient.PostAsJsonAsync("/api/templates", new
        {
            title = "Template with Top-level Tag",
            type = "qc",
            description = "Top-level tag test",
            categoryTag = "Audits"
        });
        
        if (!createResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"Create template failed. Status: {createResponse.StatusCode}. Body: {await createResponse.Content.ReadAsStringAsync()}");
        }
        
        var createBody = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var templateId = createBody.GetProperty("id").GetString()!;
        Assert.Equal("Audits", createBody.GetProperty("categoryTag").GetString());

        // 2. Get template and verify CategoryTag
        var getResponse = await adminClient.GetAsync($"/api/templates/{templateId}");
        if (!getResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"Get template failed. Status: {getResponse.StatusCode}. Body: {await getResponse.Content.ReadAsStringAsync()}");
        }
        
        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Audits", getBody.GetProperty("categoryTag").GetString());

        // 3. Update template CategoryTag
        var updateResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}", new
        {
            title = "Template with Top-level Tag",
            description = "Top-level tag test updated",
            type = "qc",
            categoryTag = "Assessments"
        });
        
        if (!updateResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"Update template failed. Status: {updateResponse.StatusCode}. Body: {await updateResponse.Content.ReadAsStringAsync()}");
        }

        // 4. Get template again to verify update
        var getResponse2 = await adminClient.GetAsync($"/api/templates/{templateId}");
        var getBody2 = await getResponse2.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Assessments", getBody2.GetProperty("categoryTag").GetString());

        // 5. Save tree and verify CategoryTag propagates
        var treePayload = new
        {
            Title = "Template with Top-level Tag",
            Type = "qc",
            Description = "Top-level tag test updated",
            ScoringLogicConfig = (string?)null,
            DisplayNoun = (string?)null,
            Version = 2,
            CategoryTag = "Assessments",
            Groups = Array.Empty<object>()
        };
        
        var saveResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}/tree", treePayload);
        if (!saveResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SaveTemplateTree failed. Status: {saveResponse.StatusCode}. Body: {await saveResponse.Content.ReadAsStringAsync()}");
        }
        
        var saveBody = await saveResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Assessments", saveBody.GetProperty("categoryTag").GetString());

        // 6. Sync templates and verify CategoryTag is present
        var sinceTimestamp = DateTimeOffset.UtcNow.AddMinutes(-5).ToString("o");
        var syncResponse = await adminClient.GetAsync($"/api/sync/templates?since={Uri.EscapeDataString(sinceTimestamp)}");
        if (!syncResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SyncTemplates failed. Status: {syncResponse.StatusCode}. Body: {await syncResponse.Content.ReadAsStringAsync()}");
        }

        var syncBody = await syncResponse.Content.ReadFromJsonAsync<JsonElement>();
        var syncTemplates = syncBody.GetProperty("templates").EnumerateArray().ToList();
        var targetTemplate = syncTemplates.FirstOrDefault(t => t.GetProperty("id").GetString() == templateId);
        
        Assert.NotNull(targetTemplate.ValueKind == JsonValueKind.Undefined ? null : (object?)targetTemplate);
        Assert.Equal("Assessments", targetTemplate.GetProperty("categoryTag").GetString());
    }
}
