using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.ActionPlans;

public class UpdateActionPlan_StaleStateConflict_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public UpdateActionPlan_StaleStateConflict_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<(HttpClient Client, Guid UserId)> CreateStoreManagerClientAsync()
    {
        var client = _factory.CreateClient();
        var email = $"sm-{Guid.NewGuid():N}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, "SmTest1!@", "Test SM", "store_manager");
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<(Guid StoreId, Guid ProfileId, Guid SubmissionId, Guid ActionPlanId)> SeedClosedActionPlanAsync(string status)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = "Stale State Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Use the existing helper to create the user, then we extract the ID
        var client = _factory.CreateClient();
        var email = $"sm-{Guid.NewGuid():N}@test.com";
        var (_, smId) = await _factory.RegisterUserAsync(client, email, "SmTest1!@", "Test SM", "store_manager");

        db.Profiles.Add(new Profile
        {
            Id = smId,
            FullName = "SM",
            Email = email,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            StoreId = storeId,
            StoreName = "Stale State Store",
            AuditorId = Guid.NewGuid(),
            ScoringMode = "penalty",
            Status = "draft",
            TotalScore = 0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var apId = Guid.NewGuid();
        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            StoreId = storeId,
            StoreManagerId = smId,
            SubmissionId = submissionId,
            CriteriaLabel = "H1",
            GroupTitle = "HOSPITALITY",
            Status = status,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        return (storeId, smId, submissionId, apId);
    }

    private async Task<HttpClient> GetAuthenticatedClientForUser(Guid userId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FindAsync(userId);
        
        var client = _factory.CreateClient();
        // Assume password is "SM123!@" from seeding. Actually, it's easier to just register a new user in the test.
        // I will change the Seed method to return the token too. Let's fix that.
        return client; // Unused, replaced by better approach below
    }
    
    // Better seeding method returning the ready-to-use authenticated client.
    private async Task<(HttpClient Client, Guid ActionPlanId)> SeedActionPlanAndClientAsync(string status)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = "Stale State Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var (client, smId) = await CreateStoreManagerClientAsync();

        // Save the Store first so the FK is valid before we update the Profile's StoreId.
        await db.SaveChangesAsync();

        // RegisterUserAsync already creates the Profile row. We just need to update its StoreId.
        using (var updateScope = _factory.Services.CreateScope())
        {
            var updateDb = updateScope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await updateDb.Profiles.FindAsync(smId);
            if (profile is not null)
            {
                profile.StoreId = storeId;
                await updateDb.SaveChangesAsync();
            }
        }

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            StoreId = storeId,
            StoreName = "Stale State Store",
            AuditorId = Guid.NewGuid(),
            ScoringMode = "penalty",
            Status = "draft",
            TotalScore = 0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var apId = Guid.NewGuid();
        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            StoreId = storeId,
            StoreManagerId = smId,
            SubmissionId = submissionId,
            CriteriaLabel = "H1",
            GroupTitle = "HOSPITALITY",
            Status = status,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        return (client, apId);

    }

    [Fact]
    public async Task UpdateActionPlan_WhenPersistedPlanIsClosed_AndRequestAttemptsPendingVerify_Returns409ProblemDetailsCodeActionPlanAlreadyClosed()
    {
        // Arrange
        var (client, apId) = await SeedActionPlanAndClientAsync("closed");
        var payload = new { status = "pending_verify", evidenceNote = "Stale offline update" };

        // Act
        var response = await client.PutAsJsonAsync($"/api/action-plans/{apId}", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode); // Will fail (currently returns OK or similar)

        var problemDetails = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(problemDetails.TryGetProperty("code", out var codeElement), "ProblemDetails is missing 'code' extension");
        Assert.Equal("action_plan_already_closed", codeElement.GetString());
    }

    [Fact]
    public async Task UpdateActionPlan_WhenStalePendingVerifyIsRejected_DoesNotMutateStatus_AndWritesAuditLog()
    {
        // Arrange
        var (client, apId) = await SeedActionPlanAndClientAsync("closed");
        var payload = new { status = "pending_verify", evidenceNote = "Stale offline update" };

        // Act
        await client.PutAsJsonAsync($"/api/action-plans/{apId}", payload);

        // Assert
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var ap = await db.ActionPlans.FindAsync(apId);
        Assert.Equal("closed", ap!.Status); // Must remain closed

        var auditLog = await db.SystemLogs.FirstOrDefaultAsync(l => 
            l.EntityType == "ActionPlan" && 
            l.EntityId == apId && 
            l.Action == "action_plan_update_rejected");
            
        Assert.NotNull(auditLog); // Audit log must be written for forensic visibility
    }

    [Fact]
    public async Task UpdateActionPlan_WhenOpenPlanMovesToPendingVerify_StillReturns200AndSetsEvidenceMetadata()
    {
        // Arrange
        var (client, apId) = await SeedActionPlanAndClientAsync("open"); // Legitimate open plan
        var payload = new { status = "pending_verify", evidenceNote = "Valid update" };

        // Act
        var response = await client.PutAsJsonAsync($"/api/action-plans/{apId}", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var ap = await db.ActionPlans.FindAsync(apId);
        
        Assert.Equal("pending_verify", ap!.Status);
        Assert.NotNull(ap.EvidenceSubmittedAt);
    }
}
