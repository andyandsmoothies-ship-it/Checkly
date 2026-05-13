using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

// Test Plan — ATDD Acceptance Tests for GET /api/sync/submissions
// Coverage:
//   A1. Delta filter: only submissions updated after `since` are returned
//   A2. Voided record has VoidReason + VoidedAt in response
//   A3. Store manager + correct storeId → 200 OK
//   A4. Store manager + wrong storeId → 403 Forbidden
//   A5. Admin with no storeId/areaId scope → 200 OK (admin bypass)
//   A6. Pagination: pageSize is respected
//   E1. No storeId AND no areaId provided → 400 Bad Request

public class SyncSubmissionsEndpointTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SyncSubmissionsEndpointTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private async Task<Guid> SeedStoreAsync(string nameSuffix, Guid? areaId = null)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            AreaId = areaId,
            Name = $"Sync Store {nameSuffix}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return storeId;
    }

    private async Task<Guid> SeedSubmissionAsync(Guid storeId, string status = "completed",
        DateTimeOffset? updatedAt = null, string? voidReason = null)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            Status = status,
            StoreId = storeId,
            StoreName = "Sync Test Store",
            VoidReason = voidReason,
            VoidedAt = voidReason is not null ? DateTimeOffset.UtcNow : null,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = updatedAt ?? DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return submissionId;
    }

    private async Task LinkStoreManagerToStoreAsync(Guid userId, Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FirstAsync(p => p.Id == userId);
        profile.StoreId = storeId;
        await db.SaveChangesAsync();
    }

    private async Task LinkAreaManagerToAreaAsync(Guid userId, Guid areaId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FirstAsync(p => p.Id == userId);
        profile.AreaId = areaId;
        await db.SaveChangesAsync();
    }

    // ── Happy Path ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task SyncSubmissions_WithSince_ReturnsOnlyDelta()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeId = await SeedStoreAsync("delta1");
        var cutoff = DateTimeOffset.UtcNow;

        // Old submission (before cutoff — must NOT appear)
        await SeedSubmissionAsync(storeId, "completed", cutoff.AddHours(-2));
        // New submission (after cutoff — MUST appear)
        var newId = await SeedSubmissionAsync(storeId, "completed", cutoff.AddMinutes(1));

        var sinceParam = Uri.EscapeDataString(cutoff.ToString("O"));
        var url = $"/api/sync/submissions?storeId={storeId}&since={sinceParam}";

        // Act
        var response = await authClient.GetAsync(url);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items");
        Assert.All(items.EnumerateArray(), item =>
        {
            var id = Guid.Parse(item.GetProperty("id").GetString()!);
            Assert.Equal(newId, id);
        });
    }

    [Fact]
    public async Task SyncSubmissions_VoidedRecord_HasVoidFields()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeId = await SeedStoreAsync("void-fields1");
        var submissionId = await SeedSubmissionAsync(storeId, "voided",
            voidReason: "Confirmed contamination found");

        // Act
        var response = await authClient.GetAsync($"/api/sync/submissions?storeId={storeId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        var found = items.Where(i =>
            Guid.Parse(i.GetProperty("id").GetString()!) == submissionId).ToList();

        Assert.Single(found);
        var voidedItem = found[0];
        Assert.Equal("voided", voidedItem.GetProperty("status").GetString());
        Assert.Equal("Confirmed contamination found", voidedItem.GetProperty("voidReason").GetString());
        // voidedAt must be a non-null timestamp
        Assert.True(voidedItem.TryGetProperty("voidedAt", out var voidedAt));
        Assert.NotEqual(JsonValueKind.Null, voidedAt.ValueKind);
    }

    [Fact]
    public async Task SyncSubmissions_AsStoreManager_CorrectStore_Returns200()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (smToken, smUserId) = await _factory.RegisterUserAsync(
            client, $"sm-correct-{Guid.NewGuid()}@test.com", "StMgr123!@", "StoreMgr", "store_manager");

        var storeId = await SeedStoreAsync("sm-correct1");
        await LinkStoreManagerToStoreAsync(smUserId, storeId);
        await SeedSubmissionAsync(storeId);

        var authClient = _factory.CreateAuthenticatedClient(smToken);

        // Act
        var response = await authClient.GetAsync($"/api/sync/submissions?storeId={storeId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SyncSubmissions_AsAreaManager_CorrectArea_Returns200()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (amToken, amUserId) = await _factory.RegisterUserAsync(
            client, $"am-correct-{Guid.NewGuid()}@test.com", "AreaMgr123!@", "AreaMgr", "area_manager");

        var areaId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = "Test Area", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        var storeId = await SeedStoreAsync("am-correct1", areaId: areaId);

        // Profile.AreaId is left null so old logic fails
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = amUserId, StoreId = storeId });
            await db.SaveChangesAsync();
        }

        await SeedSubmissionAsync(storeId);

        var authClient = _factory.CreateAuthenticatedClient(amToken);

        // Act - request by areaId
        var response = await authClient.GetAsync($"/api/sync/submissions?areaId={areaId}");

        // Assert - Expect 200 because AM has junction row for the only store in area
        // Currently fails (returns 403) because Profile.AreaId != areaId
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SyncSubmissions_AsAreaManager_MissingOneStoreInJunction_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (amToken, amUserId) = await _factory.RegisterUserAsync(
            client, $"am-partial-{Guid.NewGuid()}@test.com", "AreaMgr123!@", "AreaMgr", "area_manager");

        var areaId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = "Test Area", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        var storeId1 = await SeedStoreAsync("am-partial1", areaId: areaId);
        var storeId2 = await SeedStoreAsync("am-partial2", areaId: areaId);

        // Set Profile.AreaId to match areaId so old logic passes
        await LinkAreaManagerToAreaAsync(amUserId, areaId);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            // ONLY assign store1, missing store2
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = amUserId, StoreId = storeId1 });
            await db.SaveChangesAsync();
        }

        var authClient = _factory.CreateAuthenticatedClient(amToken);

        // Act - request by areaId
        var response = await authClient.GetAsync($"/api/sync/submissions?areaId={areaId}");

        // Assert - Expect 403 because AM doesn't have ALL stores in the area.
        // Currently fails (returns 200 OK) because old logic only checks Profile.AreaId == areaId
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task SyncSubmissions_AsStoreManager_WrongStore_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (smToken, smUserId) = await _factory.RegisterUserAsync(
            client, $"sm-wrong-{Guid.NewGuid()}@test.test", "StMgr123!@", "StoreMgrWrong", "store_manager");

        var ownStoreId = await SeedStoreAsync("sm-wrong-own");
        var otherStoreId = await SeedStoreAsync("sm-wrong-other");

        // Link to ownStoreId — querying otherStoreId should be FORBIDDEN
        await LinkStoreManagerToStoreAsync(smUserId, ownStoreId);
        await SeedSubmissionAsync(otherStoreId);

        var authClient = _factory.CreateAuthenticatedClient(smToken);

        // Act
        var response = await authClient.GetAsync($"/api/sync/submissions?storeId={otherStoreId}");

        // Assert — IDOR must block cross-store access
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task SyncSubmissions_AsAdmin_NoScopeRequired_Returns200()
    {
        // Arrange — admin can query without storeId or areaId
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act — no storeId, no areaId bound — admin gets all
        var response = await authClient.GetAsync("/api/sync/submissions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SyncSubmissions_Pagination_RespectsLimit_And_ReturnsHasNextPage()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeId = await SeedStoreAsync("pagination1");
        // Seed 5 submissions
        for (var i = 0; i < 5; i++)
            await SeedSubmissionAsync(storeId);

        // Act — request limit 2
        var response = await authClient.GetAsync(
            $"/api/sync/submissions?storeId={storeId}&limit=2");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Equal(2, items.Count);
        Assert.True(body.GetProperty("hasNextPage").GetBoolean());
    }

    [Fact]
    public async Task SyncSubmissions_Pagination_Cursor_ReturnsNextPage()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeId = await SeedStoreAsync("pagination2");
        var time1 = DateTimeOffset.UtcNow.AddMinutes(-10);
        var time2 = DateTimeOffset.UtcNow.AddMinutes(-5);
        
        var sub1 = await SeedSubmissionAsync(storeId, updatedAt: time1);
        var sub2 = await SeedSubmissionAsync(storeId, updatedAt: time2);
        
        var time1Param = Uri.EscapeDataString(time1.ToString("O"));
        
        // Act - use sub1 as cursor
        var response = await authClient.GetAsync(
            $"/api/sync/submissions?storeId={storeId}&cursorUpdatedAt={time1Param}&cursorId={sub1}&limit=2");
            
        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.Single(items);
        Assert.Equal(sub2, Guid.Parse(items[0].GetProperty("id").GetString()!));
        Assert.False(body.GetProperty("hasNextPage").GetBoolean());
    }

    [Fact]
    public async Task SyncSubmissions_Pagination_Cursor_TieBreaker()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeId = await SeedStoreAsync("pagination3");
        var sharedTime = DateTimeOffset.UtcNow.AddMinutes(-10);
        
        var sub1 = await SeedSubmissionAsync(storeId, updatedAt: sharedTime);
        var sub2 = await SeedSubmissionAsync(storeId, updatedAt: sharedTime);
        
        var list = new[] { sub1, sub2 }.OrderBy(x => x).ToList();
        var first = list[0];
        var second = list[1];
        
        var sharedTimeParam = Uri.EscapeDataString(sharedTime.ToString("O"));
        
        // Act - use first as cursor
        var response = await authClient.GetAsync(
            $"/api/sync/submissions?storeId={storeId}&cursorUpdatedAt={sharedTimeParam}&cursorId={first}&limit=2");
            
        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.Contains(items, i => Guid.Parse(i.GetProperty("id").GetString()!) == second);
        Assert.DoesNotContain(items, i => Guid.Parse(i.GetProperty("id").GetString()!) == first);
    }

    // ── Error Paths ────────────────────────────────────────────────────────────

    [Fact]
    public async Task SyncSubmissions_MissingTenantScope_Returns400()
    {
        // Arrange — non-admin with no storeId or areaId
        var client = _factory.CreateClient();
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"auditor-scope-{Guid.NewGuid()}@test.test", "Aud12345!@", "ScopeAuditor", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act — no storeId, no areaId
        var response = await authClient.GetAsync("/api/sync/submissions");

        // Assert — Rule 1: unbounded non-admin syncs are rejected
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
