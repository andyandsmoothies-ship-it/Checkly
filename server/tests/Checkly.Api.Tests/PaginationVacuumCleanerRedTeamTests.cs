using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.ActionPlans;
using Checkly.Api.Features.Stores;
using Checkly.Api.Features.Submissions;
using Checkly.Api.Features.Templates;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Security;

/// <summary>
/// P1.1 Red Team: Pagination Vacuum Cleaner (Resource Exhaustion)
/// 
/// Tests the resilience of list endpoints against:
///   - pageSize overflow (DoS)
///   - page integer overflow (Infrastructure Exception)
///   - page/pageSize underflow (Math formatting)
///   - Non-integer injection (Model binding)
/// </summary>
public class PaginationVacuumCleanerRedTeamTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public PaginationVacuumCleanerRedTeamTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    private async Task<string> GetAuditorTokenAsync()
    {
        using var scope = _fixture.Services.CreateScope();
        var client = _fixture.CreateClient();
        
        // Use a unique email to avoid collisions in the Sequential test run
        var uniqueEmail = $"auditor-p11-{Guid.NewGuid():N}@redteam.test";
        var (token, _) = await _fixture.RegisterUserAsync(
            client, uniqueEmail, "Aa1234567@", "Auditor P11", "auditor");
        
        return token;
    }

    [Theory]
    [InlineData("/api/templates")]
    [InlineData("/api/submissions")]
    [InlineData("/api/stores")]
    [InlineData("/api/action-plans")]
    public async Task Pagination_WithPageSizeOverflow_ClampsToMax(string endpoint)
    {
        // Arrange
        var token = await GetAuditorTokenAsync();
        var client = _fixture.CreateAuthenticatedClient(token);

        // Act:pageSize=5000000 (V1)
        var response = await client.GetAsync($"{endpoint}?pageSize=5000000");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        
        var pageSize = json.RootElement.GetProperty("pageSize").GetInt32();
        Assert.InRange(pageSize, 1, 200); // Most are clamped to 200 or 100
    }

    [Theory]
    [InlineData("/api/templates")]
    [InlineData("/api/submissions")]
    [InlineData("/api/stores")]
    [InlineData("/api/action-plans")]
    public async Task Pagination_WithPageSizeUnderflow_ClampsToMin(string endpoint)
    {
        // Arrange
        var token = await GetAuditorTokenAsync();
        var client = _fixture.CreateAuthenticatedClient(token);

        // Act: pageSize=0 (V2) or pageSize=-999 (V3)
        var response0 = await client.GetAsync($"{endpoint}?pageSize=0");
        var responseNeg = await client.GetAsync($"{endpoint}?pageSize=-999");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response0.StatusCode);
        Assert.Equal(HttpStatusCode.OK, responseNeg.StatusCode);
        
        var json0 = await response0.Content.ReadFromJsonAsync<JsonElement>();
        var jsonNeg = await responseNeg.Content.ReadFromJsonAsync<JsonElement>();
        
        Assert.Equal(1, json0.GetProperty("pageSize").GetInt32());
        Assert.Equal(1, jsonNeg.GetProperty("pageSize").GetInt32());
    }

    [Theory]
    [InlineData("/api/templates")]
    [InlineData("/api/submissions")]
    [InlineData("/api/stores")]
    [InlineData("/api/action-plans")]
    public async Task Pagination_WithPageIntegerOverflow_ReturnsEmptyButSuccess(string endpoint)
    {
        // Arrange
        var token = await GetAuditorTokenAsync();
        var client = _fixture.CreateAuthenticatedClient(token);

        // Act: page=2147483647 (V4)
        var response = await client.GetAsync($"{endpoint}?page=2147483647&pageSize=50");

        // Assert
        // We expect a 200 OK with 0 items, NOT a 500 Internal Server Error
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = json.GetProperty("items");
        
        Assert.Equal(0, items.GetArrayLength());
        Assert.Equal(2147483647, json.GetProperty("page").GetInt32());
    }

    [Theory]
    [InlineData("/api/templates")]
    [InlineData("/api/submissions")]
    [InlineData("/api/stores")]
    [InlineData("/api/action-plans")]
    public async Task Pagination_WithNonIntegerParams_UsesDefaults(string endpoint)
    {
        // Arrange
        var token = await GetAuditorTokenAsync();
        var client = _fixture.CreateAuthenticatedClient(token);

        // Act: pageSize=abc (V5)
        var response = await client.GetAsync($"{endpoint}?pageSize=abc&page=xyz");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, json.GetProperty("page").GetInt32());
        Assert.Equal(50, json.GetProperty("pageSize").GetInt32());
    }

    [Theory]
    [InlineData("/api/templates")]
    [InlineData("/api/submissions")]
    [InlineData("/api/stores")]
    [InlineData("/api/action-plans")]
    public async Task Pagination_WithNoParams_UsesDefaults(string endpoint)
    {
        // Arrange
        var token = await GetAuditorTokenAsync();
        var client = _fixture.CreateAuthenticatedClient(token);

        // Act: No params (V6)
        var response = await client.GetAsync(endpoint);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, json.GetProperty("page").GetInt32());
        Assert.Equal(50, json.GetProperty("pageSize").GetInt32());
    }
}
