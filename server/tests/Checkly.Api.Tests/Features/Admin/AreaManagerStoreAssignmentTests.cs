using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Admin;

[Trait("Category", "Admin")]
public class AreaManagerStoreAssignmentTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AreaManagerStoreAssignmentTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<Guid> CreateStoreAsync(string name)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = name,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            IsActive = true
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();
        return store.Id;
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task TC1_DbLayer_UniqueIndex_ThrowsOnDuplicateStoreAssignment()
    {
        // Arrange
        var storeId = await CreateStoreAsync("Test Store Unique");
        var am1Id = Guid.NewGuid();
        var am2Id = Guid.NewGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        db.Profiles.Add(new Profile { Id = am1Id, FullName = "AM 1", Email = "am1@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Profiles.Add(new Profile { Id = am2Id, FullName = "AM 2", Email = "am2@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = am1Id, StoreId = storeId, CreatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        // Act & Assert
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = am2Id, StoreId = storeId, CreatedAt = DateTimeOffset.UtcNow });
        
        // This should fail because of a unique index on store_id
        await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task TC2_CreateAM_VacantStore_ReturnsCreated()
    {
        // Arrange
        var storeId = await CreateStoreAsync("Vacant Store");
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var request = new
        {
            email = $"vacant_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "Vacant AM",
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };

        // Act
        var response = await authClient.PostAsJsonAsync("/api/admin/users", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected Created. Status: {response.StatusCode}. Body: {body}");
        }
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task TC3_CreateAM_TakenStore_ReturnsConflict()
    {
        // Arrange
        var storeId = await CreateStoreAsync("Taken Store Create");
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Create the first AM who takes the store
        var firstRequest = new
        {
            email = $"first_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "First AM",
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };
        var firstResponse = await authClient.PostAsJsonAsync("/api/admin/users", firstRequest);
        firstResponse.EnsureSuccessStatusCode();

        // Act
        // Attempt to create a second AM assigning the same store
        var conflictRequest = new
        {
            email = $"second_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "Second AM",
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };
        var response = await authClient.PostAsJsonAsync("/api/admin/users", conflictRequest);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("existingManagerId", out _), "Expected existingManagerId in 409 response");
        Assert.Equal("Store already has an area manager assigned", json.GetProperty("error").GetString());
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task TC4_UpdateAM_TakenStore_ReturnsConflict()
    {
        // Arrange
        var storeId = await CreateStoreAsync("Taken Store Update");
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // First AM takes the store
        var firstRequest = new
        {
            email = $"first_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "First AM",
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };
        var firstResponse = await authClient.PostAsJsonAsync("/api/admin/users", firstRequest);
        firstResponse.EnsureSuccessStatusCode();

        // Register a second AM without the store
        var (_, secondAmId) = await _factory.RegisterUserAsync(client, $"second_{Guid.NewGuid()}@test.com", "Pass123!", "Second AM", "area_manager", adminToken);

        // Act
        // Attempt to update the second AM to take the store
        var conflictRequest = new
        {
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{secondAmId}", conflictRequest);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("existingManagerName", out _), "Expected existingManagerName in 409 response");
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task TC5_UpdateAM_TakenStore_ForceReassign_ReturnsOk()
    {
        // Arrange
        var storeId = await CreateStoreAsync("Force Reassign Store");
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // First AM takes the store
        var firstRequest = new
        {
            email = $"first_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "First AM",
            role = "area_manager",
            assignedStoreIds = new[] { storeId }
        };
        var firstResponse = await authClient.PostAsJsonAsync("/api/admin/users", firstRequest);
        firstResponse.EnsureSuccessStatusCode();

        // Register a second AM without the store
        var (_, secondAmId) = await _factory.RegisterUserAsync(client, $"second_{Guid.NewGuid()}@test.com", "Pass123!", "Second AM", "area_manager", adminToken);

        // Act
        // Attempt to update the second AM to take the store WITH forceReassign = true
        var forceRequest = new
        {
            role = "area_manager",
            assignedStoreIds = new[] { storeId },
            forceReassign = true
        };
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{secondAmId}", forceRequest);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected OK. Status: {response.StatusCode}. Body: {body}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Gap1_UpdateNonAMRole_WithForceReassign_DoesNotConflict()
    {
        // Arrange: Store Manager can be assigned to multiple stores (or rules apply differently)
        // Here we test that forceReassign doesn't break non-AM logic. We will assign the SAME store to two Store Managers.
        var storeId = await CreateStoreAsync("Shared SM Store");
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var firstRequest = new
        {
            email = $"sm1_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "First SM",
            role = "store_manager",
            assignedStoreIds = new[] { storeId }
        };
        var firstResponse = await authClient.PostAsJsonAsync("/api/admin/users", firstRequest);
        firstResponse.EnsureSuccessStatusCode();

        var (_, secondSmId) = await _factory.RegisterUserAsync(client, $"sm2_{Guid.NewGuid()}@test.com", "Pass123!", "Second SM", "store_manager", adminToken);

        // Act
        var updateRequest = new
        {
            role = "store_manager",
            assignedStoreIds = new[] { storeId },
            forceReassign = true // Sending this flag should not trigger AM logic
        };
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{secondSmId}", updateRequest);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected OK. Status: {response.StatusCode}. Body: {body}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Gap2_BulkAssignment_AtomicFailure()
    {
        // Arrange
        var store1 = await CreateStoreAsync("Bulk 1 Vacant");
        var store2 = await CreateStoreAsync("Bulk 2 Taken");
        
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Take store 2
        var firstRequest = new
        {
            email = $"am1_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "First AM",
            role = "area_manager",
            assignedStoreIds = new[] { store2 }
        };
        var firstResponse = await authClient.PostAsJsonAsync("/api/admin/users", firstRequest);
        firstResponse.EnsureSuccessStatusCode();

        // Act
        // Attempt to create AM with both store1 and store2
        var conflictRequest = new
        {
            email = $"am2_{Guid.NewGuid()}@test.com",
            password = "Password123!",
            fullName = "Second AM",
            role = "area_manager",
            assignedStoreIds = new[] { store1, store2 }
        };
        var response = await authClient.PostAsJsonAsync("/api/admin/users", conflictRequest);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);

        // Ensure store1 was NOT assigned to am2 (Atomic failure)
        // Since the user creation failed, we can't query by their ID.
        // We just query the DB to ensure store1 has no AMs.
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var hasAssignments = await db.ProfileStoreAssignments.AnyAsync(a => a.StoreId == store1);
        Assert.False(hasAssignments, "Expected bulk transaction to rollback entirely");
    }
}
