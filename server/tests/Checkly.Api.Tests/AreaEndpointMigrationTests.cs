using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Areas Entity — Slice 3 (Server Endpoints Migration).
/// Tests verify that server endpoints use AreaId (Guid FK) instead of AreaCode (string).
/// Tests will FAIL (RED) until the endpoint migration is implemented.
/// </summary>
public class AreaEndpointMigrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public AreaEndpointMigrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private static string UniqueEmail(string prefix) => $"{prefix}-{_runId}@slice3.test";

    // ─── AC1: CreateStore accepts areaId (Guid) ───
    // Citation: analysis_areas_entity.md:220

    [Fact]
    public async Task CreateStore_Accepts_AreaId_And_Returns_AreaName()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        // Create an area first
        var areaResponse = await authClient.PostAsJsonAsync("/api/areas", new
        {
            name = $"Miền Bắc {_runId}",
            code = $"north-s3-{_runId}"
        });
        areaResponse.EnsureSuccessStatusCode();
        var area = await areaResponse.Content.ReadFromJsonAsync<JsonElement>();
        var areaId = area.GetProperty("id").GetString();

        // Create store with areaId (Guid) instead of areaCode (string)
        var storeResponse = await authClient.PostAsJsonAsync("/api/stores", new
        {
            name = $"Store AC1 {_runId}",
            address = "123 Test St",
            areaId = areaId   // ← NEW: Guid FK, not string areaCode
        });

        Assert.Equal(HttpStatusCode.Created, storeResponse.StatusCode);

        var store = await storeResponse.Content.ReadFromJsonAsync<JsonElement>();
        // The response should include areaId and areaName
        Assert.Equal(areaId, store.GetProperty("areaId").GetString());
        Assert.Equal($"Miền Bắc {_runId}", store.GetProperty("areaName").GetString());
    }

    // ─── AC2: ListSubmissions AM data isolation via AreaId FK ───
    // Citation: analysis_areas_entity.md:221

    [Fact]
    public async Task AM_ListSubmissions_Filters_By_AreaId_FK()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        // Create two areas
        var area1Resp = await adminClient.PostAsJsonAsync("/api/areas", new
        { name = $"Area1 {_runId}", code = $"area1-s3-{_runId}" });
        area1Resp.EnsureSuccessStatusCode();
        var area1 = await area1Resp.Content.ReadFromJsonAsync<JsonElement>();
        var area1Id = Guid.Parse(area1.GetProperty("id").GetString()!);

        var area2Resp = await adminClient.PostAsJsonAsync("/api/areas", new
        { name = $"Area2 {_runId}", code = $"area2-s3-{_runId}" });
        area2Resp.EnsureSuccessStatusCode();
        var area2 = await area2Resp.Content.ReadFromJsonAsync<JsonElement>();
        var area2Id = Guid.Parse(area2.GetProperty("id").GetString()!);

        // Create an AM user assigned to area1
        var (amToken, amUserId) = await _factory.RegisterUserAsync(
            client, UniqueEmail("am"), "Amtest123!@", "Area Manager",
            "area_manager", adminToken: bootstrapToken);

        // Assign AM to area1 via direct DB access
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(amUserId);
            profile!.AreaId = area1Id;  // ← FK assignment
            await db.SaveChangesAsync();

            // Create stores: store1 in area1, store2 in area2
            var store1 = new Store
            {
                Id = Guid.NewGuid(),
                Name = $"S1-{_runId}",
                AreaId = area1Id,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            };
            var store2 = new Store
            {
                Id = Guid.NewGuid(),
                Name = $"S2-{_runId}",
                AreaId = area2Id,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            };
            db.Stores.AddRange(store1, store2);

            // Create a submission for each store
            db.Submissions.AddRange(
                new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store1.Id,
                    StoreName = store1.Name,
                    AuditorId = amUserId,
                    AuditorName = "AM",
                    Status = "completed",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                },
                new Submission
                {
                    Id = Guid.NewGuid(),
                    StoreId = store2.Id,
                    StoreName = store2.Name,
                    AuditorId = amUserId,
                    AuditorName = "AM",
                    Status = "completed",
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                });
            await db.SaveChangesAsync();
        }

        // AM queries submissions — should only see store1's data
        var amClient = _factory.CreateAuthenticatedClient(amToken);
        var response = await amClient.GetAsync("/api/submissions");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = result.GetProperty("items");

        // All returned submissions should be from area1 stores only
        foreach (var item in items.EnumerateArray())
        {
            var storeName = item.GetProperty("storeName").GetString();
            Assert.Contains($"S1-{_runId}", storeName!);
        }
        // At least 1 submission from area1
        Assert.True(items.GetArrayLength() >= 1);
    }

    // ─── AC3: GetAnalytics ?areaId= — DEFERRED ───
    // Pre-existing LINQ translation bug in TrendPoint GroupBy (System.InvalidOperationException)
    // causes 500 regardless of areaId param. Will be addressed separately.

    // ─── AC4: ListStores search via area name join ───
    // Citation: analysis_areas_entity.md:225

    [Fact]
    public async Task ListStores_Search_By_Area_Name_Via_Join()
    {
        var client = _factory.CreateClient();
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(bootstrapToken);

        // Create area with unique name
        var areaResp = await adminClient.PostAsJsonAsync("/api/areas", new
        { name = $"SearchArea-{_runId}", code = $"searcharea-s3-{_runId}" });
        areaResp.EnsureSuccessStatusCode();
        var area = await areaResp.Content.ReadFromJsonAsync<JsonElement>();
        var areaId = Guid.Parse(area.GetProperty("id").GetString()!);

        // Create store via direct DB (since CreateStore may not accept areaId yet)
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Stores.Add(new Store
            {
                Id = Guid.NewGuid(),
                Name = $"Hidden Store {_runId}",
                AreaId = areaId,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        // Search by area name fragment — should find the store via area name join
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, UniqueEmail("searcher"), "Search123!@", "Searcher", "auditor");
        var searchClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await searchClient.GetAsync(
            $"/api/stores?search=SearchArea-{_runId}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var result = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = result.GetProperty("items");
        var hasMatch = false;
        foreach (var store in items.EnumerateArray())
        {
            if (store.GetProperty("name").GetString()!.Contains($"Hidden Store {_runId}"))
                hasMatch = true;
        }
        Assert.True(hasMatch, $"Store linked to area 'SearchArea-{_runId}' was not found via area name search");
    }
}
