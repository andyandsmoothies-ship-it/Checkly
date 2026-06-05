using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Store Management Improvements (Slice 1)
/// Tests backend server filtering for Province, District, and Manager.
/// </summary>
public class StoreManagement_Slice1_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public StoreManagement_Slice1_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> AdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private Task<HttpClient> UnauthedClientAsync()
    {
        return Task.FromResult(_factory.CreateClient());
    }

    // Helper to create a store
    private static async Task<string> CreateStoreAsync(HttpClient admin, string province, string? district)
    {
        var createResp = await admin.PostAsJsonAsync("/api/stores", new 
        { 
            name = $"Test Store {_runId} {Guid.NewGuid().ToString("N")[..4]}", 
            province,
            district
        });
        if (!createResp.IsSuccessStatusCode) 
            Assert.Fail($"Setup failed: could not create store. Status: {createResp.StatusCode}. Body: {await createResp.Content.ReadAsStringAsync()}");
            
        var body = await createResp.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    private async Task AssignManagerAsync(string storeId, string managerId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            StoreId = Guid.Parse(storeId),
            ProfileId = Guid.Parse(managerId)
        });
        await db.SaveChangesAsync();
    }

    [Fact]
    public async Task Unauthorized_Cannot_List_Stores()
    {
        var client = await UnauthedClientAsync();
        var response = await client.GetAsync("/api/stores?province=Test");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Province_Filter_Returns_Only_Matching_Stores()
    {
        var admin = await AdminClientAsync();
        var provinceA = "Hà Nội";
        var provinceB = "Đà Nẵng";
        
        await CreateStoreAsync(admin, provinceA, "Dist1");
        await CreateStoreAsync(admin, provinceB, "Dist2");

        var response = await admin.GetAsync($"/api/stores?province={Uri.EscapeDataString(provinceA)}");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.NotEmpty(items);
        Assert.All(items, item => Assert.Equal(provinceA, item.GetProperty("addressProvince").GetString()));
    }

    [Fact]
    public async Task Filters_Trim_Whitespace()
    {
        var admin = await AdminClientAsync();
        var province = "Bình Dương";
        await CreateStoreAsync(admin, province, "Dist");

        // Pass with surrounding whitespace
        var response = await admin.GetAsync($"/api/stores?province={Uri.EscapeDataString("   " + province + "   ")}");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.NotEmpty(items);
        Assert.Equal(province, items.First().GetProperty("addressProvince").GetString());
    }

    [Fact]
    public async Task District_Unassigned_Returns_Null_Or_Empty_Districts()
    {
        var admin = await AdminClientAsync();
        var province = "Cần Thơ";
        
        // Create store with null district
        await CreateStoreAsync(admin, province, null);
        // Create store with empty district
        await CreateStoreAsync(admin, province, "");
        // Create store with valid district
        await CreateStoreAsync(admin, province, "ValidDist");

        var response = await admin.GetAsync($"/api/stores?province={Uri.EscapeDataString(province)}&district=Unassigned");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.NotEmpty(items);
        Assert.All(items, item => 
        {
            var dist = item.GetProperty("addressDistrict").GetString();
            Assert.True(string.IsNullOrEmpty(dist));
        });
    }

    [Fact]
    public async Task ManagerName_Filter_Matches_Assigned_Manager()
    {
        var admin = await AdminClientAsync();
        var province = "Hải Phòng";
        
        // Setup: Create a new user (Manager)
        var regResp = await admin.PostAsJsonAsync("/api/admin/users", new 
        { 
            email = $"manager_{_runId}@checkly.test", 
            password = "Manager123!@",
            fullName = "Andy Smith",
            role = "store_manager" 
        });
        if (!regResp.IsSuccessStatusCode) Assert.Fail($"Setup failed: {await regResp.Content.ReadAsStringAsync()}");
        var userBody = await regResp.Content.ReadFromJsonAsync<JsonElement>();
        var managerId = userBody.GetProperty("id").GetString()!;

        var storeId = await CreateStoreAsync(admin, province, "Dist");
        await AssignManagerAsync(storeId, managerId);

        // Act: Filter by "Andy"
        var response = await admin.GetAsync($"/api/stores?managerName=Andy");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        Assert.NotEmpty(items);
        // We assert that the returned store has this manager.
        Assert.Contains(items, item => item.GetProperty("managerName").GetString()!.Contains("Andy"));
    }

    [Fact]
    public async Task ManagerName_Not_Found_Returns_Empty()
    {
        var admin = await AdminClientAsync();
        
        var response = await admin.GetAsync($"/api/stores?managerName=NonExistentUser12345");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var items = body.GetProperty("items").EnumerateArray().ToList();
        
        // This is a RED test expecting it to be empty because the filtering logic doesn't exist yet!
        // Wait, if the endpoint doesn't implement managerName filtering, it will return ALL stores.
        // And we expect it to return 0. So it will fail!
        Assert.Empty(items);
    }

    // ─── Reference Endpoint Tests ─────────────────────────────────────────────

    [Fact]
    public async Task GetDistricts_Returns_Unique_Active_Districts()
    {
        var admin = await AdminClientAsync();
        var province = "Đồng Nai";
        
        await CreateStoreAsync(admin, province, "Dist A");
        await CreateStoreAsync(admin, province, "Dist A"); // Duplicate
        await CreateStoreAsync(admin, province, "Dist B");
        await CreateStoreAsync(admin, province, ""); // Should be filtered out
        await CreateStoreAsync(admin, province, null); // Should be filtered out

        var response = await admin.GetAsync($"/api/reference/districts?province={Uri.EscapeDataString(province)}");
        
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var districts = body.EnumerateArray().Select(x => x.GetString()).ToList();
        
        Assert.Equal(2, districts.Count);
        Assert.Contains("Dist A", districts);
        Assert.Contains("Dist B", districts);
    }
}
