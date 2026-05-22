using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Programs;

public class GetMyAssignments_Pagination_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GetMyAssignments_Pagination_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ── Setup Helpers ────────────────────────────────────────────────────────

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<(HttpClient Client, Guid UserId)> CreateStoreManagerAsync(string email)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, "SmTest123!@", "Test SM", "store_manager", adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task LinkStoreManagerToStoreAsync(Guid userId, Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var profile = await db.Profiles.FirstAsync(p => p.Id == userId);
        profile.StoreId = storeId;
        await db.SaveChangesAsync();
    }

    private async Task<Guid> CreateTemplateAsync(HttpClient adminClient, string title)
    {
        var response = await adminClient.PostAsJsonAsync("/api/templates", new { title, type = "qc" });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/stores", new { name, province = "Hà Nội" });
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> AssignProgramAsync(HttpClient adminClient, Guid templateId, Guid storeId, string title, DateTimeOffset deadline)
    {
        var request = new
        {
            templateId = templateId,
            storeIds = new[] { storeId },
            deadline = deadline,
            category = "Testing",
            title = title
        };
        var response = await adminClient.PostAsJsonAsync("/api/programs", request);
        Assert.True(response.IsSuccessStatusCode, "Failed to assign program.");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("programId").GetString()!);
    }

    private async Task SeedBulkAssignmentsAsync(Guid templateId, Guid storeId, int count)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var programs = new List<ChecklyProgram>();
        var assignments = new List<ProgramAssignment>();

        var deadline = DateTimeOffset.UtcNow.AddDays(7);

        for (int i = 0; i < count; i++)
        {
            var program = new ChecklyProgram
            {
                Id = Guid.NewGuid(),
                TemplateId = templateId,
                Title = $"Bulk Program {i}",
                Category = "Testing",
                Deadline = deadline,
                CreatedAt = DateTimeOffset.UtcNow
            };
            programs.Add(program);

            var assignment = new ProgramAssignment
            {
                Id = Guid.NewGuid(),
                ProgramId = program.Id,
                StoreId = storeId,
                Status = "pending",
                CreatedAt = DateTimeOffset.UtcNow
            };
            assignments.Add(assignment);
        }

        db.Programs.AddRange(programs);
        db.ProgramAssignments.AddRange(assignments);
        await db.SaveChangesAsync();
    }

    // ── Tests ────────────────────────────────────────────────────────────────

    [Fact]
    public async Task BE_GMA_BOUND_01_WhenStoreHas201Assignments_DefaultRequest_ReturnsFirst50ItemsAndTotal201()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"bound01-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Bound01 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Bound01 Template");

        await SeedBulkAssignmentsAsync(templateId, storeId, 201);

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my");

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(201, body.GetProperty("total").GetInt32());
        Assert.Equal(1, body.GetProperty("page").GetInt32());
        Assert.Equal(50, body.GetProperty("pageSize").GetInt32());

        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Equal(50, items.Count);
    }

    [Fact]
    public async Task BE_GMA_BOUND_02_WhenPageSizeExceeds200_ClampsTo200()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"bound02-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Bound02 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Bound02 Template");

        await SeedBulkAssignmentsAsync(templateId, storeId, 201);

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my?pageSize=999");

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(201, body.GetProperty("total").GetInt32());
        Assert.Equal(200, body.GetProperty("pageSize").GetInt32());

        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Equal(200, items.Count);
    }

    [Fact]
    public async Task BE_GMA_BOUND_03_WhenRequestedPageOverflows_ReturnsEmptyItemsWithTotal()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"bound03-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Bound03 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Bound03 Template");

        await SeedBulkAssignmentsAsync(templateId, storeId, 10);

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my?page=5&pageSize=50");

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(10, body.GetProperty("total").GetInt32());
        Assert.Equal(5, body.GetProperty("page").GetInt32());

        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Empty(items);
    }

    [Fact]
    public async Task BE_GMA_BOUND_04_WhenProfileHasNoStore_ReturnsEmptyPagedResult()
    {
        // Arrange
        var (smClient, smId) = await CreateStoreManagerAsync($"bound04-{Guid.NewGuid()}@test.test");
        // We INTENTIONALLY DO NOT link the SM to any store.

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my");

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(0, body.GetProperty("total").GetInt32());
        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Empty(items);
    }

    [Fact]
    public async Task GAP_AC1_WhenPageIsZeroOrNegative_ClampsToOne()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"gap01-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Gap01 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Gap01 Template");

        await SeedBulkAssignmentsAsync(templateId, storeId, 10);

        // Act
        var response = await smClient.GetAsync("/api/programs/assignments/my?page=-5");

        // Assert
        if (!response.IsSuccessStatusCode) Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(1, body.GetProperty("page").GetInt32());
        var items = body.GetProperty("items").EnumerateArray().ToList();
        Assert.Equal(10, items.Count);
    }

    [Fact]
    public async Task GAP_AC2_WhenSortKeysAreIdentical_UsesIdAsTiebreakerForStablePaging()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (smClient, smId) = await CreateStoreManagerAsync($"gap02-{Guid.NewGuid()}@test.test");
        var storeId = await CreateStoreAsync(adminClient, "Gap02 Store");
        await LinkStoreManagerToStoreAsync(smId, storeId);
        var templateId = await CreateTemplateAsync(adminClient, "Gap02 Template");

        // Seed 10 assignments with the EXACT SAME deadline
        var sameDeadline = DateTimeOffset.UtcNow.AddDays(3);
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var programs = new List<ChecklyProgram>();
            var assignments = new List<ProgramAssignment>();
            for (int i = 0; i < 10; i++)
            {
                var p = new ChecklyProgram
                {
                    Id = Guid.NewGuid(),
                    TemplateId = templateId,
                    Title = $"Gap02 Program {i}",
                    Category = "Testing",
                    Deadline = sameDeadline,
                    CreatedAt = DateTimeOffset.UtcNow
                };
                programs.Add(p);
                var a = new ProgramAssignment
                {
                    Id = Guid.NewGuid(),
                    ProgramId = p.Id,
                    StoreId = storeId,
                    Status = "pending",
                    CreatedAt = DateTimeOffset.UtcNow
                };
                assignments.Add(a);
            }
            db.Programs.AddRange(programs);
            db.ProgramAssignments.AddRange(assignments);
            await db.SaveChangesAsync();
        }

        // Act
        // Fetch page 1 (pageSize 5)
        var response1 = await smClient.GetAsync("/api/programs/assignments/my?page=1&pageSize=5");
        if (!response1.IsSuccessStatusCode) Assert.Fail($"Status: {response1.StatusCode}. Body: {await response1.Content.ReadAsStringAsync()}");
        var body1 = await response1.Content.ReadFromJsonAsync<JsonElement>();
        var items1 = body1.GetProperty("items").EnumerateArray().Select(x => x.GetProperty("id").GetString()).ToList();

        // Fetch page 2 (pageSize 5)
        var response2 = await smClient.GetAsync("/api/programs/assignments/my?page=2&pageSize=5");
        if (!response2.IsSuccessStatusCode) Assert.Fail($"Status: {response2.StatusCode}. Body: {await response2.Content.ReadAsStringAsync()}");
        var body2 = await response2.Content.ReadFromJsonAsync<JsonElement>();
        var items2 = body2.GetProperty("items").EnumerateArray().Select(x => x.GetProperty("id").GetString()).ToList();

        // Assert: Ensure no duplicate IDs between page 1 and page 2 (Stable Paging)
        var overlap = items1.Intersect(items2);
        Assert.Empty(overlap);
    }
}
