using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.GlobalRisks;

/// <summary>
/// ATDD: Slice 2 Global Risk CRUD Endpoints
/// Tests for T1-T12 in implementation_plan_slice2_globalrisk_1a91f14b.md
/// All tests RED until endpoints are implemented.
/// </summary>
[Collection("Sequential")]
public class GlobalRiskApiTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GlobalRiskApiTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ═══════════════════════════════════════════════════
    // POST /api/global-risks
    // ═══════════════════════════════════════════════════

    [Fact]
    public async Task Admin_Can_Create_GlobalRisk()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.PostAsJsonAsync("/api/global-risks", new
        {
            label = "Test Risk",
            description = "A test risk"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task Create_GlobalRisk_EmptyLabel_Returns_BadRequest()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.PostAsJsonAsync("/api/global-risks", new
        {
            label = "",
            description = "A test risk"
        });

        // Currently returns 404 since route missing. Expected 400.
        Assert.True(
            response.StatusCode is HttpStatusCode.BadRequest,
            $"Expected 400 but got {response.StatusCode}");
    }

    [Fact]
    public async Task NonAdmin_Cannot_Create_GlobalRisk()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"auditor_post_{Guid.NewGuid():N}@test.com", "Audit123!@", "Auditor", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.PostAsJsonAsync("/api/global-risks", new
        {
            label = "Should Fail",
            description = "Fail"
        });

        // Expect 403 Forbidden
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ═══════════════════════════════════════════════════
    // GET /api/global-risks
    // ═══════════════════════════════════════════════════

    [Fact]
    public async Task Admin_Can_List_GlobalRisks()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.GetAsync("/api/global-risks");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task AnyAuthenticatedUser_Can_List_GlobalRisks()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"auditor_get_{Guid.NewGuid():N}@test.com", "Audit123!@", "Auditor", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.GetAsync("/api/global-risks");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Unauthenticated_Cannot_List_GlobalRisks()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/global-risks");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ═══════════════════════════════════════════════════
    // PUT /api/global-risks/{id}
    // ═══════════════════════════════════════════════════

    [Fact]
    public async Task Admin_Can_Update_GlobalRisk()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var risk = new GlobalRisk { Id = Guid.NewGuid(), Label = "Old Label", IsActive = true };
        db.GlobalRisks.Add(risk);
        await db.SaveChangesAsync();

        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.PutAsJsonAsync($"/api/global-risks/{risk.Id}", new
        {
            label = "New Label",
            description = "New Desc",
            isActive = false
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Update_NonExistent_GlobalRisk_Returns_NotFound()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.PutAsJsonAsync($"/api/global-risks/{Guid.NewGuid()}", new
        {
            label = "Doesn't Matter"
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ═══════════════════════════════════════════════════
    // DELETE /api/global-risks/{id}
    // ═══════════════════════════════════════════════════

    [Fact]
    public async Task Admin_Can_SoftDelete_GlobalRisk()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var risk = new GlobalRisk { Id = Guid.NewGuid(), Label = "To Delete", IsActive = true };
        db.GlobalRisks.Add(risk);
        await db.SaveChangesAsync();

        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.DeleteAsync($"/api/global-risks/{risk.Id}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task SoftDelete_Sets_IsActive_False_NotPhysicalDelete()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var riskId = Guid.NewGuid();
        var risk = new GlobalRisk { Id = riskId, Label = "To Delete", IsActive = true };
        db.GlobalRisks.Add(risk);
        await db.SaveChangesAsync();

        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.DeleteAsync($"/api/global-risks/{riskId}");

        // Validate soft delete in a fresh scope if it didn't return 404
        if (response.StatusCode == HttpStatusCode.OK)
        {
            using var verifyScope = _factory.Services.CreateScope();
            var verifyDb = verifyScope.ServiceProvider.GetRequiredService<AppDbContext>();
            var deletedRisk = await verifyDb.GlobalRisks.FindAsync(riskId);
            
            Assert.NotNull(deletedRisk);
            Assert.False(deletedRisk.IsActive);
        }
        else
        {
            // Fail the test cleanly because route doesn't exist yet
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }
    }

    [Fact]
    public async Task Delete_NonExistent_GlobalRisk_Returns_NotFound()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.DeleteAsync($"/api/global-risks/{Guid.NewGuid()}");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task NonAdmin_Cannot_Delete_GlobalRisk()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"auditor_del_{Guid.NewGuid():N}@test.com", "Audit123!@", "Auditor", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        var response = await auditorClient.DeleteAsync($"/api/global-risks/{Guid.NewGuid()}");

        // Expect 403 Forbidden
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
