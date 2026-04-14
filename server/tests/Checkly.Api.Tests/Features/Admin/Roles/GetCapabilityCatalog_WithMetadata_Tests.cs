using System.Net;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Admin.Roles;

/// <summary>
/// ATDD: TDD tests for PBAC Slice 2 Additive Schema in capability catalog.
/// Source: implementation_plan.md.resolved.
/// Testing that GetCapabilityCatalog returns the new CapabilityMetadata block.
/// </summary>
public class GetCapabilityCatalog_WithMetadata_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GetCapabilityCatalog_WithMetadata_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    /// <summary>
    /// AC: GetCapabilityCatalog_ReturnsMetadataBlock
    /// RED reason: API route doesn't return capabilityMetadata dictionary yet.
    /// </summary>
    [Fact]
    public async Task GetCapabilityCatalog_ReturnsMetadataBlock()
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

        var jsonStr = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(jsonStr);

        // The response should have the "capabilityMetadata" property
        Assert.True(json.RootElement.TryGetProperty("capabilityMetadata", out var metaBlock), 
            "The response JSON must contain a 'capabilityMetadata' property.");
            
        Assert.Equal(JsonValueKind.Object, metaBlock.ValueKind);
        
        // Assert that a specific metadata block exists
        Assert.True(metaBlock.TryGetProperty("templates:create", out var templateCreateMeta), 
            "Expected metadata for 'templates:create' to be present.");
            
        Assert.True(templateCreateMeta.TryGetProperty("label", out var labelProp));
        Assert.Equal("Create Templates", labelProp.GetString());
        
        Assert.True(templateCreateMeta.TryGetProperty("group", out var groupProp));
        Assert.Equal("Templates", groupProp.GetString());
    }
}
