using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// ATDD RED tests for INFRA-001 AP Count Leak.
/// Workflow: /tdd (SDET Execution)
/// </summary>
public class Analytics_GetAnalytics_OpenAPs_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Analytics_GetAnalytics_OpenAPs_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<(Guid StoreAId, Guid StoreBId)> SeedTestDataAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeAId = Guid.NewGuid();
        var storeBId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeAId, Name = "Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = storeBId, Name = "Store B", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        // Seed 3 APs in Store A
        for (int i = 0; i < 3; i++)
        {
            db.ActionPlans.Add(new ActionPlan
            {
                Id = Guid.NewGuid(), StoreId = storeAId, StoreName = "Store A",
                CriteriaLabel = $"A-{i}", GroupTitle = "G", Status = "open",
                CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        // Seed 5 APs in Store B
        for (int i = 0; i < 5; i++)
        {
            db.ActionPlans.Add(new ActionPlan
            {
                Id = Guid.NewGuid(), StoreId = storeBId, StoreName = "Store B",
                CriteriaLabel = $"B-{i}", GroupTitle = "G", Status = "open",
                CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        await db.SaveChangesAsync();

        return (storeAId, storeBId);
    }

    private async Task<HttpClient> CreateManagerClientAsync(string role, Guid? storeId = null)
    {
        var client = _factory.CreateClient();
        var email = $"{role}-{Guid.NewGuid():N}@test.com";

        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Sm12345!@", "Test User", role);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null)
        {
            profile.StoreId = storeId;
            await db.SaveChangesAsync();
        }

        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    [Fact]
    public async Task StoreManager_GetAnalytics_OpenAPs_OnlyReturnsOwnStore()
    {
        // Arrange
        var (storeAId, storeBId) = await SeedTestDataAsync();
        var client = await CreateManagerClientAsync("store_manager", storeId: storeAId);

        // Act
        var response = await client.GetAsync("/api/analytics");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = body.GetProperty("kpis");
        var openAPs = kpis.GetProperty("openAPs").GetInt32();

        Assert.Equal(3, openAPs);
    }

    [Fact]
    public async Task Admin_GetAnalytics_OpenAPs_ReturnsGlobalTotal()
    {
        // Arrange
        var client = await CreateAdminClientAsync();
        
        // Get baseline open APs count
        var baseResponse = await client.GetAsync("/api/analytics");
        var baseKpis = (await baseResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("kpis");
        var baselineAPs = baseKpis.GetProperty("openAPs").GetInt32();

        var (storeAId, storeBId) = await SeedTestDataAsync();

        // Act
        var response = await client.GetAsync("/api/analytics");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = body.GetProperty("kpis");
        var openAPs = kpis.GetProperty("openAPs").GetInt32();

        Assert.Equal(baselineAPs + 8, openAPs);
    }
}
