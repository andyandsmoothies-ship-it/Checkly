using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// Integration tests for Province Analytics (Slice 2).
/// Note: GetAreaLeaderboard endpoint was removed in SL-5 purge.
/// </summary>
public class ProvinceLeaderboardEndpointTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ProvinceLeaderboardEndpointTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetAnalytics_ByStoreId_ReturnsInsights_FromProvinceBenchmark()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        var uniqueProvince = $"Danang-{Guid.NewGuid():N}";
        db.Stores.Add(new Store 
        { 
            Id = storeId, 
            Name = "Insights Store", 
            Address2 = new StoreAddress { Province = uniqueProvince },
            CreatedAt = DateTimeOffset.UtcNow, 
            UpdatedAt = DateTimeOffset.UtcNow 
        });

        db.StoreAnalyticsSnapshots.Add(
            new StoreAnalyticsSnapshot { StoreId = storeId, AvgScore30d = 85m, UpdatedAt = DateTimeOffset.UtcNow }
        );

        // We simulate that the province has a benchmark snapshot
        // (RED: ProvinceBenchmarkSnapshot doesn't exist yet, so we have to use raw SQL to insert, or we wait for Builder to create it)
        // Since we are writing the RED test, we can use the non-existent class, causing a compiler error.
        var provinceSnapshot = new Checkly.Api.Common.Persistence.Entities.ProvinceBenchmarkSnapshot
        {
            Province = uniqueProvince,
            TotalAuditCount = 10,
            OverallAvgScore = 80m,
            CategoryAverages = "{\"Service\": 75.0, \"Cleanliness\": 82.0}",
            LastCalculatedAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Add(provinceSnapshot);
        await db.SaveChangesAsync();

        // Act (TC-SL2-06)
        var response = await adminClient.GetAsync($"/api/analytics?storeId={storeId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        
        Assert.True(json.TryGetProperty("insights", out var insights), "Response should contain insights");
        Assert.Equal(JsonValueKind.Array, insights.ValueKind);
        Assert.True(insights.GetArrayLength() > 0, "Insights should be generated from the ProvinceBenchmarkSnapshot");
        
        Assert.True(json.TryGetProperty("radarData", out var radarData), "Response should contain radarData");
    }
}
