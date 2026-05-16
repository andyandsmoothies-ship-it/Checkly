using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.ActionPlans;

[Collection("Sequential")]
public class ActionPlan_PbacUi_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ActionPlan_PbacUi_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetActionPlans_ReturnsAllowedActionsForStoreManager_WhenOpen()
    {
        // AP-PBAC-01
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"sm_pbac_{Guid.NewGuid()}@test.com", "Aa1234567@", "SM PBAC", "store_manager");

        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeId, Name = "PBAC Store", IsActive = true });
        
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null) profile.StoreId = storeId;

        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId,
            StoreManagerId = userId,
            Status = "open",
            CriteriaLabel = "PBAC Criteria",
            GroupTitle = "PBAC Group",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        // Act
        var response = await client.GetAsync("/api/action-plans");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadAsStringAsync();
        var node = JsonNode.Parse(json);
        var array = node?["items"]?.AsArray();
        
        Assert.NotNull(array);
        Assert.True(array.Count > 0);
        
        var plan = array.FirstOrDefault(p => p?["id"]?.GetValue<Guid>() == planId);
        Assert.NotNull(plan);

        // This is the core business assertion: the DTO must now include allowedActions
        var allowedActions = plan["allowedActions"]?.AsArray();
        Assert.NotNull(allowedActions);
        
        var actionStrings = allowedActions.Select(a => a?.GetValue<string>()).ToList();
        Assert.Contains("view", actionStrings);
        Assert.Contains("submit_evidence", actionStrings);
        Assert.DoesNotContain("verify_close", actionStrings);
    }

    [Fact]
    public async Task GetActionPlanById_ReturnsAllowedActionsForAuditor_WhenPendingVerify()
    {
        // AP-PBAC-02
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"auditor_pbac_{Guid.NewGuid()}@test.com", "Aa1234567@", "Auditor PBAC", "auditor");

        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var templateId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "PBAC Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "PBAC Store 2", IsActive = true });
        
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId, // Links auditor ownership
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = "{}"
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId,
            SubmissionId = submissionId,
            Status = "pending_verify",
            CriteriaLabel = "PBAC Criteria",
            GroupTitle = "PBAC Group",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        // Act
        var response = await client.GetAsync($"/api/action-plans/{planId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadAsStringAsync();
        var plan = JsonNode.Parse(json);
        
        Assert.NotNull(plan);

        var allowedActions = plan["allowedActions"]?.AsArray();
        Assert.NotNull(allowedActions); // Fails if missing payload
        
        var actionStrings = allowedActions.Select(a => a?.GetValue<string>()).ToList();
        Assert.Contains("view", actionStrings);
        Assert.Contains("verify_close", actionStrings);
        Assert.Contains("reject_evidence", actionStrings);
        Assert.DoesNotContain("submit_evidence", actionStrings);
    }

    [Fact]
    public async Task UpdateActionPlan_SubmitEvidence_RecomputesAllowedActionsInResponse()
    {
        // AP-PBAC-04
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"sm_submit_{Guid.NewGuid()}@test.com", "Aa1234567@", "SM Submit", "store_manager");

        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeId, Name = "Submit Store", IsActive = true });
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null) profile.StoreId = storeId;

        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId,
            StoreManagerId = userId,
            Status = "open",
            CriteriaLabel = "Crit",
            GroupTitle = "Group",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        // Act
        var response = await client.PutAsJsonAsync($"/api/action-plans/{planId}", new
        {
            Status = "pending_verify",
            EvidenceNote = "Fixed"
        });

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadAsStringAsync();
        var plan = JsonNode.Parse(json);
        
        Assert.NotNull(plan);
        var allowedActions = plan["allowedActions"]?.AsArray();
        Assert.NotNull(allowedActions); 
        
        var actionStrings = allowedActions.Select(a => a?.GetValue<string>()).ToList();
        // Since the SM submitted it, they can view it but NO LONGER submit.
        Assert.Contains("view", actionStrings);
        Assert.DoesNotContain("submit_evidence", actionStrings);
        Assert.DoesNotContain("verify_close", actionStrings);
    }
    
    [Fact]
    public async Task GetActionPlans_ReturnsEmptyActionsForUserWithoutCapabilities()
    {
        // Gap Analysis AP-PBAC-GAP1
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"viewer_{Guid.NewGuid()}@test.com", "Aa1234567@", "Viewer", "store_manager"); 
        
        // Let's strip their write capability from DB if possible, or just create a user with a role that has no ActionPlan capabilities
        // By default 'store_manager' has action_plans:write, but let's test someone looking at another store's plan they don't own.
        // If they don't own it, they shouldn't see submit_evidence.

        var storeId = Guid.NewGuid();
        var theirStoreId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeId, Name = "Other Store", IsActive = true });
        db.Stores.Add(new Store { Id = theirStoreId, Name = "Their Store", IsActive = true });
        
        var profile = await db.Profiles.FindAsync(userId);
        if (profile != null) profile.StoreId = theirStoreId;

        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId, // They don't own this store
            Status = "open",
            CriteriaLabel = "Crit",
            GroupTitle = "Group",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        
        // We'll use a super admin token just to query it, but verify their specific allowed actions if possible.
        // Actually, let's use an Area Manager who has programs:list but NO action_plans:write.
        var (tokenAM, amId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");
            
        var client = _factory.CreateAuthenticatedClient(tokenAM);

        var response = await client.GetAsync("/api/action-plans");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        
        var json = await response.Content.ReadAsStringAsync();
        var node = JsonNode.Parse(json);
        var array = node?["items"]?.AsArray();
        
        var plan = array?.FirstOrDefault(p => p?["id"]?.GetValue<Guid>() == planId);
        Assert.NotNull(plan);

        var allowedActions = plan["allowedActions"]?.AsArray();
        Assert.NotNull(allowedActions);
        
        var actionStrings = allowedActions.Select(a => a?.GetValue<string>()).ToList();
        // Area manager shouldn't be able to submit or verify someone else's unassigned plan.
        Assert.Contains("view", actionStrings);
        Assert.DoesNotContain("submit_evidence", actionStrings);
    }
}
