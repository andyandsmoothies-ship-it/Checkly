using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Auth;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Tests.Features.Auth;

public class SyncProfileTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SyncProfileTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task TC4_1_AreaManager_Returns_AssignedStoreIds()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var client = _factory.CreateClient();
        var (token, userId) = await _factory.RegisterUserAsync(client, "am_sync_41@test.com", "Password123!", "Area Manager", "area_manager");
        
        // Setup direct profile store assignments
        var profile = await db.Profiles.SingleAsync(p => p.Id == userId);
        var store1Id = Guid.NewGuid();
        var store2Id = Guid.NewGuid();
        
        db.Stores.Add(new Store { Id = store1Id, Name = "Sync Store 1", IsActive = true, CreatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = store2Id, Name = "Sync Store 2", IsActive = true, CreatedAt = DateTimeOffset.UtcNow });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = profile.Id, StoreId = store1Id });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = profile.Id, StoreId = store2Id });
        await db.SaveChangesAsync();

        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await client.GetAsync("/api/sync/profile");

        // Assert - expecting 404 infra failure since endpoint doesn't exist yet
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK, but got {response.StatusCode}. Route may be missing.");
        }

        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var assignedStoreIds = json.GetProperty("assignedStoreIds").EnumerateArray().Select(x => x.GetGuid()).ToList();
        
        Assert.Contains(store1Id, assignedStoreIds);
        Assert.Contains(store2Id, assignedStoreIds);
        Assert.Equal("area_manager", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task TC4_2_NonAM_Returns_Empty_AssignedStoreIds()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (token, userId) = await _factory.RegisterUserAsync(client, "auditor_sync_42@test.com", "Password123!", "Auditor", "auditor");
        
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await client.GetAsync("/api/sync/profile");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK, but got {response.StatusCode}. Route may be missing.");
        }

        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        
        // Assert assignedStoreIds is null or empty
        if (json.TryGetProperty("assignedStoreIds", out var assignedProp))
        {
            if (assignedProp.ValueKind != System.Text.Json.JsonValueKind.Null)
            {
                Assert.Empty(assignedProp.EnumerateArray());
            }
        }
    }

    [Fact]
    public async Task TC4_6_SyncProfile_Excludes_Inactive_Stores()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var client = _factory.CreateClient();
        var (token, userId) = await _factory.RegisterUserAsync(client, "am_sync_46@test.com", "Password123!", "Area Manager", "area_manager");
        
        var profile = await db.Profiles.SingleAsync(p => p.Id == userId);
        var activeStoreId = Guid.NewGuid();
        var inactiveStoreId = Guid.NewGuid();
        
        db.Stores.Add(new Store { Id = activeStoreId, Name = "Active Sync Store", IsActive = true, CreatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = inactiveStoreId, Name = "Inactive Sync Store", IsActive = false, CreatedAt = DateTimeOffset.UtcNow });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = profile.Id, StoreId = activeStoreId });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = profile.Id, StoreId = inactiveStoreId });
        await db.SaveChangesAsync();

        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await client.GetAsync("/api/sync/profile");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK, but got {response.StatusCode}. Route may be missing.");
        }

        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        var assignedStoreIds = json.GetProperty("assignedStoreIds").EnumerateArray().Select(x => x.GetGuid()).ToList();
        
        Assert.Contains(activeStoreId, assignedStoreIds);
        Assert.DoesNotContain(inactiveStoreId, assignedStoreIds);
    }
    
    [Fact]
    public async Task TC4_7_RoleDowngrade_IgnoresStaleAssignments()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var client = _factory.CreateClient();
        
        // Start as AM, assign a store
        var (token, userId) = await _factory.RegisterUserAsync(client, "downgraded_sync_47@test.com", "Password123!", "Area Manager", "area_manager");
        
        var profile = await db.Profiles.SingleAsync(p => p.Id == userId);
        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store { Id = storeId, Name = "Stale Sync Store", IsActive = true, CreatedAt = DateTimeOffset.UtcNow });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = profile.Id, StoreId = storeId });
        await db.SaveChangesAsync();

        // Downgrade to auditor
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);
        var updateResponse = await adminClient.PutAsJsonAsync($"/api/admin/users/{userId}", new { role = "auditor" });
        if (!updateResponse.IsSuccessStatusCode) Assert.Fail($"Update failed: {updateResponse.StatusCode} {await updateResponse.Content.ReadAsStringAsync()}");
        


        // Act - Re-login to get the new role
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new { email = profile.Email, password = "Password123!" });
        if (!loginResponse.IsSuccessStatusCode) Assert.Fail($"Login failed: {loginResponse.StatusCode} {await loginResponse.Content.ReadAsStringAsync()}");
        var loginJson = await loginResponse.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        token = loginJson.GetProperty("token").GetString()!;
        var freshClient = _factory.CreateClient();
        freshClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        // Act
        var response = await freshClient.GetAsync("/api/sync/profile");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Expected 200 OK, but got {response.StatusCode}. Route may be missing. Error: {err}");
        }

        var json = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        if (json.TryGetProperty("assignedStoreIds", out var assignedProp) && assignedProp.ValueKind != System.Text.Json.JsonValueKind.Null)
        {
            Assert.Empty(assignedProp.EnumerateArray());
        }
    }
}
