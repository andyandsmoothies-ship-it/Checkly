using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 1: Audit Template CategoryTags Integration
/// Source: implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md
/// 
/// These tests verify that when saving/updating a template tree via PUT /api/templates/{id}/tree,
/// we can associate CategoryTags (list of strings) with both Groups and Criteria, and they are
/// retrieved correctly via GET /api/templates/{id}.
/// </summary>
public class TemplateCategoryTagsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public TemplateCategoryTagsTests(TestWebApplicationFactory factory)
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
            description = "Sync CategoryTags test template"
        });
        
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Setup failed: Could not create template. Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    // ── TC-CAT-01: Admin Can Save Group With Category Tags ──
    [Fact]
    public async Task Admin_Can_Save_Group_With_Category_Tags()
    {
        // Arrange
        var adminClient = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "Template for Group Tags");

        // Construct request with dynamic/anonymous object to bypass C# compilation gates
        // before DTO records have the CategoryTags fields.
        var treePayload = new
        {
            Title = "Template for Group Tags",
            Type = "qc",
            Description = "Sync CategoryTags test template",
            ScoringLogicConfig = (string?)null,
            DisplayNoun = (string?)null,
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Kitchen Area",
                    Description = "FOH hygiene",
                    Weight = (decimal?)10.0m,
                    MaxDeductionPoints = (decimal?)null,
                    MinusPerFault = (decimal?)null,
                    OrderIndex = 0,
                    Metadata = (string?)null,
                    CategoryTags = new[] { "Food Safety", "Hygiene" },
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act - Save the tree
        var saveResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}/tree", treePayload);
        if (!saveResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SaveTemplateTree failed. Status: {saveResponse.StatusCode}. Body: {await saveResponse.Content.ReadAsStringAsync()}");
        }

        // Act - Get the template to verify persistence and projection
        var getResponse = await adminClient.GetAsync($"/api/templates/{templateId}");
        if (!getResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"GetTemplate failed. Status: {getResponse.StatusCode}. Body: {await getResponse.Content.ReadAsStringAsync()}");
        }

        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();

        // Assert
        Assert.True(getBody.TryGetProperty("groups", out var groupsElement), "Response should contain 'groups' array.");
        Assert.Equal(JsonValueKind.Array, groupsElement.ValueKind);
        Assert.NotEmpty(groupsElement.EnumerateArray());

        var firstGroup = groupsElement.EnumerateArray().First();
        
        var hasCategoryTags = firstGroup.TryGetProperty("categoryTags", out var tagsElement);
        Assert.True(hasCategoryTags, "Response should include 'categoryTags' property for groups.");
        
        if (tagsElement.ValueKind == JsonValueKind.Null)
        {
            Assert.Fail("Group 'categoryTags' was returned as null.");
        }

        Assert.Equal(JsonValueKind.Array, tagsElement.ValueKind);
        var tagsList = tagsElement.EnumerateArray().Select(x => x.GetString()).ToList();
        
        Assert.Contains("Food Safety", tagsList);
        Assert.Contains("Hygiene", tagsList);
    }

    // ── TC-CAT-02: Admin Can Save Criterion With Category Tags ──
    [Fact]
    public async Task Admin_Can_Save_Criterion_With_Category_Tags()
    {
        // Arrange
        var adminClient = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(adminClient, "Template for Criterion Tags");

        // Construct request payload with a Criterion containing CategoryTags
        var treePayload = new
        {
            Title = "Template for Criterion Tags",
            Type = "qc",
            Description = "Sync CategoryTags test template",
            ScoringLogicConfig = (string?)null,
            DisplayNoun = (string?)null,
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Food Preparation",
                    Description = "FOH hygiene",
                    Weight = (decimal?)10.0m,
                    MaxDeductionPoints = (decimal?)null,
                    MinusPerFault = (decimal?)null,
                    OrderIndex = 0,
                    Metadata = (string?)null,
                    CategoryTags = new[] { "Food Safety" },
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Temperature Check",
                            Description = "Verify prep temp",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            IsCcp = true,
                            IsRisk = false,
                            MinusImpact = (decimal?)null,
                            MaxDeductionPoints = (decimal?)null,
                            OrderIndex = 0,
                            Metadata = (string?)null,
                            CategoryTags = new[] { "Critical Control Point" }
                        }
                    }
                }
            }
        };

        // Act - Save the tree
        var saveResponse = await adminClient.PutAsJsonAsync($"/api/templates/{templateId}/tree", treePayload);
        if (!saveResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"SaveTemplateTree failed. Status: {saveResponse.StatusCode}. Body: {await saveResponse.Content.ReadAsStringAsync()}");
        }

        // Act - Get the template to verify persistence and projection
        var getResponse = await adminClient.GetAsync($"/api/templates/{templateId}");
        if (!getResponse.IsSuccessStatusCode)
        {
            Assert.Fail($"GetTemplate failed. Status: {getResponse.StatusCode}. Body: {await getResponse.Content.ReadAsStringAsync()}");
        }

        var getBody = await getResponse.Content.ReadFromJsonAsync<JsonElement>();

        // Assert
        Assert.True(getBody.TryGetProperty("groups", out var groupsElement), "Response should contain 'groups' array.");
        Assert.Equal(JsonValueKind.Array, groupsElement.ValueKind);
        Assert.NotEmpty(groupsElement.EnumerateArray());

        var firstGroup = groupsElement.EnumerateArray().First();
        
        Assert.True(firstGroup.TryGetProperty("criteria", out var criteriaElement), "Group should contain 'criteria' array.");
        Assert.Equal(JsonValueKind.Array, criteriaElement.ValueKind);
        Assert.NotEmpty(criteriaElement.EnumerateArray());

        var firstCriterion = criteriaElement.EnumerateArray().First();
        
        var hasCategoryTags = firstCriterion.TryGetProperty("categoryTags", out var tagsElement);
        Assert.True(hasCategoryTags, "Response should include 'categoryTags' property for criteria.");
        
        if (tagsElement.ValueKind == JsonValueKind.Null)
        {
            Assert.Fail("Criterion 'categoryTags' was returned as null.");
        }

        Assert.Equal(JsonValueKind.Array, tagsElement.ValueKind);
        var tagsList = tagsElement.EnumerateArray().Select(x => x.GetString()).ToList();
        
        Assert.Contains("Critical Control Point", tagsList);
    }
}
