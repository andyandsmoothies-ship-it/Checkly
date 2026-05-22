using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Programs;

public class Program_Slice5_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public Program_Slice5_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<(HttpClient token, Guid userId)> CreateRoleClientAsync(string email, string role)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, $"Test123!@#{role}", $"Test {role}", role, adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<(Guid programId, Guid templateId)> CreateProgramAsync(HttpClient adminClient, int numStores, int daysToDeadline)
    {
        var tplResp = await adminClient.PostAsJsonAsync("/api/templates", new { title = $"Tpl-{Guid.NewGuid()}", type = "checklist" });
        tplResp.EnsureSuccessStatusCode();
        var templateId = (await tplResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var storeIds = new List<Guid>();
        for (int i = 0; i < numStores; i++)
        {
            var storeResp = await adminClient.PostAsJsonAsync("/api/stores", new { name = $"Store-{Guid.NewGuid()}", province = "Hà Nội" });
            storeIds.Add((await storeResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid());
        }

        var createResp = await adminClient.PostAsJsonAsync("/api/programs", new
        {
            templateId,
            storeIds = storeIds.ToArray(),
            deadline = DateTimeOffset.UtcNow.AddDays(7), // Always create with future deadline to bypass API validation
            category = "Slice5",
            title = $"Program-{Guid.NewGuid()}"
        });
        createResp.EnsureSuccessStatusCode();
        var programId = (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("programId").GetGuid();

        return (programId, templateId);
    }

    [Fact]
    public async Task TC1_Valid_HQ_Summary_Request_Calculates_Counts()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (programId, _) = await CreateProgramAsync(adminClient, 5, 7); // Future deadline

        // Manually manipulate assignments for varied statuses
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = db.ProgramAssignments.Where(a => a.ProgramId == programId).ToList();

            assignments[0].Status = "pending";
            assignments[1].Status = "pending";
            assignments[2].Status = "submitted";
            assignments[3].Status = "needs_revision";
            assignments[4].Status = "verified";
            await db.SaveChangesAsync();
        }

        // Act
        var response = await adminClient.GetAsync($"/api/programs/{programId}/summary");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(5, json.GetProperty("total").GetInt32());
        Assert.Equal(2, json.GetProperty("pending").GetInt32());
        Assert.Equal(0, json.GetProperty("overdue").GetInt32()); // Deadline in future
        Assert.Equal(1, json.GetProperty("submitted").GetInt32());
        Assert.Equal(1, json.GetProperty("needsRevision").GetInt32());
        Assert.Equal(1, json.GetProperty("verified").GetInt32());

        // Completion Rate = (1 submitted + 1 needs_rev + 1 verified) / 5 = 3/5 = 60
        Assert.Equal(60, json.GetProperty("completionRate").GetInt32());
    }

    [Fact]
    public async Task TC2_StoreManager_Cannot_Get_Summary()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (programId, _) = await CreateProgramAsync(adminClient, 1, 7);
        var (smClient, _) = await CreateRoleClientAsync($"sm-{Guid.NewGuid()}@test.test", "store_manager");

        // Act
        var response = await smClient.GetAsync($"/api/programs/{programId}/summary");

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task TC3_Program_Not_Found_Returns_404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.GetAsync($"/api/programs/{Guid.NewGuid()}/summary");

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task TC4_Dynamic_Overdue_Calculation()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        // Create with future deadline (via API defaults), then mutate
        var (programId, _) = await CreateProgramAsync(adminClient, 3, 7);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var program = db.Programs.Single(p => p.Id == programId);
            program.Deadline = DateTimeOffset.UtcNow.AddDays(-1); // Mutate deadline to be in the past

            var assignments = db.ProgramAssignments.Where(a => a.ProgramId == programId).ToList();

            assignments[0].Status = "pending";
            assignments[1].Status = "pending";
            assignments[2].Status = "submitted";
            await db.SaveChangesAsync();
        }

        // Act
        var response = await adminClient.GetAsync($"/api/programs/{programId}/summary");

        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();

        // Assert
        Assert.Equal(3, json.GetProperty("total").GetInt32());
        // Since deadline is passed, the 2 pending should be counted as overdue, NOT pending.
        Assert.Equal(0, json.GetProperty("pending").GetInt32());
        Assert.Equal(2, json.GetProperty("overdue").GetInt32());
        Assert.Equal(1, json.GetProperty("submitted").GetInt32());

        // Completion Rate = (1 submitted) / 3 = 33%
        Assert.Equal(33, json.GetProperty("completionRate").GetInt32());
    }

    [Fact]
    public async Task GapAC1_Empty_Program_Calculates_Zero_Safely()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        // Create with 1 store to bypass API validation, then delete it manually
        var (programId, _) = await CreateProgramAsync(adminClient, 1, 7);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var assignments = db.ProgramAssignments.Where(a => a.ProgramId == programId).ToList();
            db.ProgramAssignments.RemoveRange(assignments);
            await db.SaveChangesAsync();
        }

        // Act
        var response = await adminClient.GetAsync($"/api/programs/{programId}/summary");

        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();

        // Assert
        Assert.Equal(0, json.GetProperty("total").GetInt32());
        Assert.Equal(0, json.GetProperty("pending").GetInt32());
        Assert.Equal(0, json.GetProperty("completionRate").GetInt32());
    }

    [Fact]
    public async Task GapAC2_Tenant_Isolation_Excludes_Other_Programs()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var (programIdA, _) = await CreateProgramAsync(adminClient, 2, 7);
        var (programIdB, _) = await CreateProgramAsync(adminClient, 5, 7);

        // Act
        var responseA = await adminClient.GetAsync($"/api/programs/{programIdA}/summary");
        var responseB = await adminClient.GetAsync($"/api/programs/{programIdB}/summary");

        if (!responseA.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK but got {responseA.StatusCode}.");
        }

        // Assert
        var jsonA = await responseA.Content.ReadFromJsonAsync<JsonElement>();
        var jsonB = await responseB.Content.ReadFromJsonAsync<JsonElement>();

        Assert.Equal(2, jsonA.GetProperty("total").GetInt32());
        Assert.Equal(5, jsonB.GetProperty("total").GetInt32());
    }
}
