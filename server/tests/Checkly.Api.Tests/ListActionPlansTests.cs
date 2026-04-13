using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD RED tests for Action Plans Area Scoping.
/// Workflow: /atdd (SDET Execution)
/// </summary>
public class ListActionPlansTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ListActionPlansTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    /// <summary>
    /// Seeds two areas, two stores, and two action plans (one in each area).
    /// </summary>
    private async Task<(Guid Area1Id, Guid Area2Id, Guid Store1Id, Guid Store2Id)> SeedTestDataAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var area1Id = Guid.NewGuid();
        var area2Id = Guid.NewGuid();
        var store1Id = Guid.NewGuid();
        var store2Id = Guid.NewGuid();

        db.Areas.Add(new Area { Id = area1Id, Name = "Area 1", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Areas.Add(new Area { Id = area2Id, Name = "Area 2", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        db.Stores.Add(new Store { Id = store1Id, Name = "Store 1", AreaId = area1Id, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = store2Id, Name = "Store 2", AreaId = area2Id, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        // Add one action plan for each store
        db.ActionPlans.Add(new ActionPlan
        {
            Id = Guid.NewGuid(), StoreId = store1Id, StoreName = "Store 1",
            CriteriaLabel = "H1", GroupTitle = "HOSPITALITY", Status = "open",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = Guid.NewGuid(), StoreId = store2Id, StoreName = "Store 2",
            CriteriaLabel = "H2", GroupTitle = "HYGIENE", Status = "open",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        return (area1Id, area2Id, store1Id, store2Id);
    }

    private async Task<(HttpClient Client, Guid UserId)> CreateManagerClientAsync(string role, Guid? areaId = null, Guid? storeId = null)
    {
        var client = _factory.CreateClient();
        var email = $"{role}-{Guid.NewGuid():N}@test.com";

        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Sm12345!@", "Test Manager", role);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null)
        {
            profile.AreaId = areaId;
            profile.StoreId = storeId;
            await db.SaveChangesAsync();
        }

        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    // ==========================================
    // TESTS
    // ==========================================

    [Fact]
    public async Task AM_GetsList_ReturnsPlansForStoresInArea()
    {
        // Arrange
        var (area1Id, _, store1Id, _) = await SeedTestDataAsync();
        var (client, _) = await CreateManagerClientAsync("area_manager", areaId: area1Id);

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.NotEmpty(items);
        Assert.All(items, i => Assert.Equal(store1Id.ToString(), i.GetProperty("storeId").GetString()));
    }

    [Fact]
    public async Task AM_GetsList_ExcludesPlansFromStoresOutsideArea()
    {
        // Arrange
        var (area1Id, area2Id, store1Id, store2Id) = await SeedTestDataAsync();
        var (client, _) = await CreateManagerClientAsync("area_manager", areaId: area1Id);

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.DoesNotContain(items, i => i.GetProperty("storeId").GetString() == store2Id.ToString());
    }

    [Fact]
    public async Task AM_Unscoped_GetsList_ReturnsEmpty()
    {
        // Arrange
        await SeedTestDataAsync();
        // AreaId is explicitly null
        var (client, _) = await CreateManagerClientAsync("area_manager", areaId: null);

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.Empty(items);
    }

    [Fact]
    public async Task Auditor_GetsList_ReturnsEmpty()
    {
        // Arrange
        await SeedTestDataAsync();
        var (client, _) = await CreateManagerClientAsync("auditor");

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.Empty(items);
    }

    [Fact]
    public async Task SM_GetsList_ReturnsPlansForAssignedStore()
    {
        // Arrange
        var (_, _, store1Id, store2Id) = await SeedTestDataAsync();
        var (client, _) = await CreateManagerClientAsync("store_manager", storeId: store1Id);

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.NotEmpty(items);
        Assert.All(items, i => Assert.Equal(store1Id.ToString(), i.GetProperty("storeId").GetString()));
    }
}
