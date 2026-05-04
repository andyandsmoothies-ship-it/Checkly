using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Admin;

[Trait("Category", "Admin")]
public class UpdateUserVirtualAreaTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public UpdateUserVirtualAreaTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task TC_3_1_UpdatingAM_WithVirtualAreaId_CreatesAssignmentsForAllActiveStoresInArea()
    {
        // TC-3.1: Updating AM with `virtualAreaId=X` creates assignments for all active stores in area X
        // Rule: from implementation_plan_..._slice3_admin_api.md
        
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Seed Area and Stores
        var areaId = Guid.NewGuid();
        var store1Id = Guid.NewGuid();
        var store2Id = Guid.NewGuid();
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Area_{areaId}" });
            db.Stores.Add(new Store { Id = store1Id, Name = $"Store1_{store1Id}", AreaId = areaId, IsActive = true });
            db.Stores.Add(new Store { Id = store2Id, Name = $"Store2_{store2Id}", AreaId = areaId, IsActive = true });
            await db.SaveChangesAsync();
        }

        var (_, userId) = await _factory.RegisterUserAsync(client, $"am1_{Guid.NewGuid()}@test.com", "Pass123!", "AM User", "auditor", adminToken);

        var request = new
        {
            role = "area_manager",
            virtualAreaId = areaId
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = await db.ProfileStoreAssignments
                .Where(a => a.ProfileId == userId)
                .Select(a => a.StoreId)
                .ToListAsync();
                
            Assert.Equal(2, assignments.Count);
            Assert.Contains(store1Id, assignments);
            Assert.Contains(store2Id, assignments);
        }
    }

    [Fact]
    public async Task TC_3_2_UpdatingAM_WithAssignedStoreIds_UpsertsDirectAssignments_AndIsIdempotent()
    {
        // TC-3.2: Updating AM with assignedStoreIds=[A,B] upserts direct assignments and does not duplicate existing rows
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var areaId = Guid.NewGuid();
        var storeA = Guid.NewGuid();
        var storeB = Guid.NewGuid();
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Area_{areaId}" });
            db.Stores.Add(new Store { Id = storeA, Name = $"StoreA_{storeA}", AreaId = areaId, IsActive = true });
            db.Stores.Add(new Store { Id = storeB, Name = $"StoreB_{storeB}", AreaId = areaId, IsActive = true });
            await db.SaveChangesAsync();
        }

        var (_, userId) = await _factory.RegisterUserAsync(client, $"am2_{Guid.NewGuid()}@test.com", "Pass123!", "AM User", "area_manager", adminToken);

        // Pre-assign A
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = userId, StoreId = storeA });
            await db.SaveChangesAsync();
        }

        var request = new
        {
            role = "area_manager",
            assignedStoreIds = new[] { storeA, storeB }
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = await db.ProfileStoreAssignments
                .Where(a => a.ProfileId == userId)
                .Select(a => a.StoreId)
                .ToListAsync();
                
            Assert.Equal(2, assignments.Count);
            Assert.Contains(storeA, assignments);
            Assert.Contains(storeB, assignments);
        }
    }

    [Fact]
    public async Task TC_3_3_UpdateAM_OccupiedLegacyArea_DoesNotReturn409()
    {
        // TC-3.3: S10 removed: update to area_manager with occupied legacy area does not return 409
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var areaId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Occupied_{areaId}" });
            await db.SaveChangesAsync();
        }

        // Occupy the area with another user (legacy style AreaId assignment)
        var (_, occupantId) = await _factory.RegisterUserAsync(client, $"occupant_{Guid.NewGuid()}@test.com", "Pass123!", "Occupant", "area_manager", adminToken);
        var occupantRequest = new { role = "area_manager", areaId = areaId };
        await authClient.PutAsJsonAsync($"/api/admin/users/{occupantId}", occupantRequest);

        // Now try to update another user to the same areaId
        var (_, newcomerId) = await _factory.RegisterUserAsync(client, $"newcomer_{Guid.NewGuid()}@test.com", "Pass123!", "Newcomer", "auditor", adminToken);
        var newcomerRequest = new { role = "area_manager", areaId = areaId };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{newcomerId}", newcomerRequest);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task TC_3_4_MixedPayloadUnion_ResultsInUnionSet()
    {
        // TC-3.4: Mixed payload union: virtualAreaId + extra assignedStoreIds results in union set
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var areaId = Guid.NewGuid();
        var storeInArea = Guid.NewGuid();
        var otherAreaId = Guid.NewGuid();
        var extraStore = Guid.NewGuid();
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Area_{areaId}" });
            db.Stores.Add(new Store { Id = storeInArea, Name = $"StoreA_{storeInArea}", AreaId = areaId, IsActive = true });
            db.Areas.Add(new Area { Id = otherAreaId, Name = $"Area_{otherAreaId}" });
            db.Stores.Add(new Store { Id = extraStore, Name = $"StoreExt_{extraStore}", AreaId = otherAreaId, IsActive = true });
            await db.SaveChangesAsync();
        }

        var (_, userId) = await _factory.RegisterUserAsync(client, $"am3_{Guid.NewGuid()}@test.com", "Pass123!", "AM User", "auditor", adminToken);

        var request = new
        {
            role = "area_manager",
            virtualAreaId = areaId,
            assignedStoreIds = new[] { extraStore }
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = await db.ProfileStoreAssignments
                .Where(a => a.ProfileId == userId)
                .Select(a => a.StoreId)
                .ToListAsync();
                
            Assert.Equal(2, assignments.Count);
            Assert.Contains(storeInArea, assignments);
            Assert.Contains(extraStore, assignments);
        }
    }

    [Fact]
    public async Task TC_3_5_InvalidAssignedStoreIds_Returns400()
    {
        // TC-3.5: Invalid assignedStoreIds containing unknown store returns 400 with clear error
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var (_, userId) = await _factory.RegisterUserAsync(client, $"am4_{Guid.NewGuid()}@test.com", "Pass123!", "AM User", "auditor", adminToken);

        var fakeStoreId = Guid.NewGuid();
        var request = new
        {
            role = "area_manager",
            assignedStoreIds = new[] { fakeStoreId }
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("One or more assigned stores do not exist", body);
    }

    [Fact]
    public async Task TC_3_6_NonAdminUpdate_Forbidden()
    {
        // TC-3.6: Non-admin update still forbidden even with new payload fields
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        
        var (_, adminId) = await _factory.RegisterUserAsync(client, $"adm_{Guid.NewGuid()}@test.com", "Pass123!", "Admin", "admin", adminToken);
        var (auditorToken, _) = await _factory.RegisterUserAsync(client, $"auditor_{Guid.NewGuid()}@test.com", "Pass123!", "Auditor", "auditor", adminToken);

        var authClient = _factory.CreateAuthenticatedClient(auditorToken);

        var request = new
        {
            role = "area_manager",
            virtualAreaId = Guid.NewGuid(),
            assignedStoreIds = new[] { Guid.NewGuid() }
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{adminId}", request);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC_3_8_EmptyAssignmentsAndNoVirtualAreaId_ClearsAllAssignments()
    {
        // Gap Analysis: Updating AM with empty assignedStoreIds and no virtualAreaId clears all assignments.
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var areaId = Guid.NewGuid();
        var storeA = Guid.NewGuid();
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Area_{areaId}" });
            db.Stores.Add(new Store { Id = storeA, Name = $"StoreA_{storeA}", AreaId = areaId, IsActive = true });
            await db.SaveChangesAsync();
        }

        var (_, userId) = await _factory.RegisterUserAsync(client, $"am5_{Guid.NewGuid()}@test.com", "Pass123!", "AM User", "area_manager", adminToken);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = userId, StoreId = storeA });
            await db.SaveChangesAsync();
        }

        var request = new
        {
            role = "area_manager",
            assignedStoreIds = Array.Empty<Guid>(),
            virtualAreaId = (Guid?)null
        };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = await db.ProfileStoreAssignments
                .Where(a => a.ProfileId == userId)
                .CountAsync();
                
            Assert.Equal(0, assignments);
        }
    }
}
