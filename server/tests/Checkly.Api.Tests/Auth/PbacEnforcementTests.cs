using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Auth;

/// <summary>
/// ATDD Scenarios for PBAC Server Implementation (Slice 1 & 2).
/// Verifies that new capabilities strictly control access to Submission and Action Plan endpoints.
/// </summary>
public class PbacEnforcementTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public PbacEnforcementTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task SeedCapabilityAsync(string role, string capability)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        
        var exists = await db.RoleCapabilities.AnyAsync(rc => rc.Role == role && rc.Capability == capability);
        if (!exists)
        {
            db.RoleCapabilities.Add(new RoleCapability
            {
                Id = Guid.NewGuid(),
                Role = role,
                Capability = capability,
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        // Force a cache reload for the singleton cache in the test environment
        var cache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
        await cache.InitializeAsync(scope.ServiceProvider);
    }

    [Fact]
    public async Task Auditor_WithSubmissionsCreate_CanStartAudit()
    {
        // ARRANGE
        const string capability = "submissions:create"; // Using string literal as constant doesn't exist yet
        await SeedCapabilityAsync("auditor", capability);
        
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(client, "auditor_can@test.test", "Pass123!@", "Auditor Can", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(token);

        // ACT
        var response = await authClient.PostAsJsonAsync("/api/submissions", new 
        { 
            TemplateId = Guid.NewGuid(),
            StoreId = Guid.NewGuid()
        });

        // ASSERT
        // This should currently fail with 200 or 400 (missing template) because the guard is missing.
        // Once implemented, it should proceed past auth.
        Assert.NotEqual(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task StoreManager_WithoutSubmissionsCreate_IsForbidden()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(client, "sm_cannot@test.test", "Pass123!@", "SM Cannot", "store_manager");
        var authClient = _factory.CreateAuthenticatedClient(token);

        var storeId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Stores.Add(new Store { Id = storeId, Name = "Test Store", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        // ACT
        var response = await authClient.PostAsJsonAsync("/api/submissions", new 
        { 
            templateId = Guid.NewGuid(), // Still fake, but backend might check Store first
            storeId = storeId,
            answers = new List<object>()
        });

        // ASSERT
        // Currently returns 400 or 200. We WANT 403.
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UpdateActionPlan_ClosingWithoutVerifyCapability_IsForbidden()
    {
        // ARRANGE
        const string capability = "action_plans:write";
        await SeedCapabilityAsync("store_manager", capability);

        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(client, "sm_ap@test.test", "Pass123!@", "SM AP", "store_manager");
        var authClient = _factory.CreateAuthenticatedClient(token);

        // Seed Store and Action plan
        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            
            // Need a store to satisfy FK
            db.Stores.Add(new Store { Id = storeId, Name = "Test Store", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            
            db.ActionPlans.Add(new ActionPlan
            {
                Id = planId,
                Status = "pending_verify",
                StoreId = storeId,
                StoreName = "Test Store",
                CriteriaLabel = "Test Criteria",
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        // ACT: Attempt to close the plan (requires action_plans:verify, which SM doesn't have)
        var response = await authClient.PutAsJsonAsync($"/api/action-plans/{planId}", new { status = "closed" });

        // ASSERT
        // Currently returns 200 because no imperative guard exists.
        // We WANT this to be 403.
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
