using System.Net;
using System.Net.Http.Json;
using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Auth;

/// <summary>
/// Upserts a role-capability row using PostgreSQL ON CONFLICT DO NOTHING.
/// Prevents the TOCTOU race condition when multiple xUnit tests try to seed
/// the same (role, capability) pair in parallel.
/// </summary>
file static class CapabilityHelper
{
    public static Task UpsertAsync(AppDbContext db, string role, string capability)
        => db.Database.ExecuteSqlRawAsync(
            """
            INSERT INTO role_capabilities (id, role, capability, created_at)
            VALUES (gen_random_uuid(), {0}, {1}, now())
            ON CONFLICT (role, capability) DO NOTHING
            """, role, capability);
}

public class IdorGuardTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public IdorGuardTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated(); // Required: hydrates PBAC cache and ensures DB schema ready
    }

    [Fact]
    public async Task IDOR_RS_01_Admin_CanReviewAnySubmission()
    {
        // 1. Arrange
        var client = _factory.CreateClient();

        // Registering a second admin requires an existing admin bearer token.
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var uid = Guid.NewGuid().ToString("N")[..8];
        var (token, _) = await _factory.RegisterUserAsync(
            client, $"admin_idor_{uid}@checkly.com", "Password123!", "Admin IDOR", "admin",
            adminToken: bootstrapToken);
        var (_, auditorId) = await _factory.RegisterUserAsync(
            client, $"auditor_idor_{uid}@checkly.com", "Password123!", "Auditor IDOR", "auditor");

        Guid submissionId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Seed capability (idempotent upsert — safe under parallel test execution)
            await CapabilityHelper.UpsertAsync(db, "admin", AppCapabilities.SubmissionsReview);

            // Seed a submission owned by the auditor
            var store = new Store { Id = Guid.NewGuid(), Name = $"Store IDOR 1 {uid}" };
            db.Stores.Add(store);
            var submission = new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = store.Id,
                StoreName = store.Name,
                AuditorId = auditorId,
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.Submissions.Add(submission);
            await db.SaveChangesAsync();
            submissionId = submission.Id;

            // Refresh PBAC cache after capability seeding
            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            await pbacCache.InitializeAsync(scope.ServiceProvider);
        }

        var authenticatedClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act — use the exact submission seeded above (deterministic)
        var response = await authenticatedClient.PutAsJsonAsync(
            $"/api/submissions/{submissionId}/review", new { status = "approved" });

        // 3. Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode); // Admin must bypass IDOR guard
    }

    [Fact]
    public async Task IDOR_RS_02_AreaManager_CanReviewSubmissionInOwnArea()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var uid = Guid.NewGuid().ToString("N")[..8];
        var (token, amId) = await _factory.RegisterUserAsync(
            client, $"am_own_{uid}@checkly.com", "Password123!", "AM Own", "area_manager");

        Guid submissionId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var amProfile = await db.Profiles.FirstAsync(p => p.Id == amId);

            var area = new Area { Id = Guid.NewGuid(), Name = $"Area Own {uid}" };
            amProfile.AreaId = area.Id;
            db.Areas.Add(area);

            var store = new Store { Id = Guid.NewGuid(), Name = $"Store Own {uid}", AreaId = area.Id };
            db.Stores.Add(store);

            var submission = new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = store.Id,
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.Submissions.Add(submission);

            await CapabilityHelper.UpsertAsync(db, "area_manager", AppCapabilities.SubmissionsReview);

            await db.SaveChangesAsync();
            submissionId = submission.Id;

            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            await pbacCache.InitializeAsync(scope.ServiceProvider);
        }

        var authenticatedClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var response = await authenticatedClient.PutAsJsonAsync(
            $"/api/submissions/{submissionId}/review", new { status = "approved" });

        // 3. Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task IDOR_RS_03_AreaManager_IsForbiddenFromReviewingCrossAreaSubmission()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var uid = Guid.NewGuid().ToString("N")[..8];
        var (token, amId) = await _factory.RegisterUserAsync(
            client, $"am_cross_{uid}@checkly.com", "Password123!", "AM Cross", "area_manager");

        Guid crossAreaSubmissionId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var amProfile = await db.Profiles.FirstAsync(p => p.Id == amId);

            var areaA = new Area { Id = Guid.NewGuid(), Name = $"Area A {uid}" };
            var areaB = new Area { Id = Guid.NewGuid(), Name = $"Area B {uid}" };
            amProfile.AreaId = areaA.Id;
            db.Areas.AddRange(areaA, areaB);

            // Submission is in area B — the area manager is assigned to area A
            var storeInB = new Store { Id = Guid.NewGuid(), Name = $"Store in B {uid}", AreaId = areaB.Id };
            db.Stores.Add(storeInB);

            var submission = new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = storeInB.Id,
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.Submissions.Add(submission);

            await CapabilityHelper.UpsertAsync(db, "area_manager", AppCapabilities.SubmissionsReview);

            await db.SaveChangesAsync();
            crossAreaSubmissionId = submission.Id;

            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            await pbacCache.InitializeAsync(scope.ServiceProvider);
        }

        var authenticatedClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var response = await authenticatedClient.PutAsJsonAsync(
            $"/api/submissions/{crossAreaSubmissionId}/review", new { status = "approved" });

        // 3. Assert — IDOR guard must block cross-area access
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task IDOR_AP_01_Auditor_CanUpdateOwnActionPlan()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var uid = Guid.NewGuid().ToString("N")[..8];
        var (token, auditorId) = await _factory.RegisterUserAsync(
            client, $"auditor_ap_{uid}@checkly.com", "Password123!", "Auditor AP", "auditor");

        Guid actionPlanId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var store = new Store { Id = Guid.NewGuid(), Name = $"Store AP {uid}" };
            db.Stores.Add(store);

            // Submission is owned by this auditor — the guard must resolve this link
            var submission = new Submission
            {
                Id = Guid.NewGuid(),
                StoreId = store.Id,
                AuditorId = auditorId,
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.Submissions.Add(submission);

            var plan = new ActionPlan
            {
                Id = Guid.NewGuid(),
                SubmissionId = submission.Id, // Link enables AuditorId resolution in handler
                StoreId = store.Id,
                Status = "open",
                CriteriaLabel = "Test Criteria",
                GroupTitle = "Test",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.ActionPlans.Add(plan);

            await CapabilityHelper.UpsertAsync(db, "auditor", AppCapabilities.ActionPlansWrite);

            await db.SaveChangesAsync();
            actionPlanId = plan.Id;

            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            await pbacCache.InitializeAsync(scope.ServiceProvider);
        }

        var authenticatedClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var response = await authenticatedClient.PutAsJsonAsync(
            $"/api/action-plans/{actionPlanId}", new { planDescription = "Updated from TDD" });

        // 3. Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task IDOR_AP_02_StoreManager_IsForbiddenFromUpdatingCrossStoreActionPlan()
    {
        // 1. Arrange
        var client = _factory.CreateClient();
        var uid = Guid.NewGuid().ToString("N")[..8];
        var (token, smId) = await _factory.RegisterUserAsync(
            client, $"sm_idor_{uid}@checkly.com", "Password123!", "SM IDOR", "store_manager");

        Guid crossStorePlanId;
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var smProfile = await db.Profiles.FirstAsync(p => p.Id == smId);

            var storeA = new Store { Id = Guid.NewGuid(), Name = $"Store A {uid}" };
            var storeB = new Store { Id = Guid.NewGuid(), Name = $"Store B {uid}" };
            smProfile.StoreId = storeA.Id;
            db.Stores.AddRange(storeA, storeB);

            // Plan belongs to Store B — store manager is assigned to Store A
            var plan = new ActionPlan
            {
                Id = Guid.NewGuid(),
                StoreId = storeB.Id,
                Status = "open",
                CriteriaLabel = "Cross Store Plan",
                GroupTitle = "Test",
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.ActionPlans.Add(plan);

            await CapabilityHelper.UpsertAsync(db, "store_manager", AppCapabilities.ActionPlansWrite);

            await db.SaveChangesAsync();
            crossStorePlanId = plan.Id;

            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            await pbacCache.InitializeAsync(scope.ServiceProvider);
        }

        var authenticatedClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act
        var response = await authenticatedClient.PutAsJsonAsync(
            $"/api/action-plans/{crossStorePlanId}", new { planDescription = "Hacker update" });

        // 3. Assert — IDOR guard must block cross-store access
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
