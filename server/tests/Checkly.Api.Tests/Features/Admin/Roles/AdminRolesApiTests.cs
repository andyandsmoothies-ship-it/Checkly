using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests.Features.Admin.Roles;

/// <summary>
/// ATDD: Admin Roles API tests for PBAC Slice 1.
/// Source: implementation_plan_admin_roles_api.md.resolved.
/// Testing 5 new endpoints for capability management.
/// 
/// ISOLATION: Implements IAsyncLifetime.DisposeAsync to scrub mutated role_capabilities
/// rows after the class finishes. Without this, GrantCapability tests leak
/// capabilities (e.g. auditor/templates:create) that break Auditor_Cannot_Create_Template
/// in other test classes.
/// </summary>
public class AdminRolesApiTests : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private readonly TestWebApplicationFactory _factory;

    public AdminRolesApiTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    public Task InitializeAsync() => Task.CompletedTask;

    /// <summary>
    /// Cleans up any role_capabilities rows written by this test class.
    /// Keeps only the rows seeded by migrations (admin:manage_roles + the baseline
    /// capability set from AddRoleCapabilities migration).
    /// Reloads the PBAC cache so downstream test classes see a clean state.
    /// </summary>
    public async Task DisposeAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Remove ONLY the specific capabilities that this test class mutates.
        // Broad deletes (e.g. WHERE role != 'admin') break tests that depend on
        // submissions:list being present for non-admin roles (seeded in Program.cs startup).
        var toClean = new[] { "templates:create", "templates:delete" };
        await db.RoleCapabilities
            .Where(rc => rc.Role == "auditor" && toClean.Contains(rc.Capability))
            .ExecuteDeleteAsync();

        // Reload the PBAC cache so downstream test classes see a clean state.
        var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
        await pbacCache.InitializeAsync(scope.ServiceProvider);
    }

    /// <summary>
    /// AC-01: GetRoles_Admin_Returns200WithFourRoles
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GetRoles_Admin_Returns200WithFourRoles()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act
        var response = await client.GetAsync("/api/admin/roles");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        // Will verify JSON structure when it passes
    }

    /// <summary>
    /// AC-02: GetCapabilityCatalog_AnyAdmin_Returns200
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GetCapabilityCatalog_AnyAdmin_Returns200()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act
        var response = await client.GetAsync("/api/admin/capabilities/catalog");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    /// <summary>
    /// AC-03: GrantCapability_Valid_Returns204
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_Valid_Returns204()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act
        var response = await client.PostAsync("/api/admin/roles/auditor/capabilities/templates:create", null);

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    /// <summary>
    /// AC-04: GrantCapability_AlreadyExists_Returns204
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_AlreadyExists_Returns204()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // First grant
        await client.PostAsync("/api/admin/roles/auditor/capabilities/templates:create", null);

        // Act - Second grant
        var response = await client.PostAsync("/api/admin/roles/auditor/capabilities/templates:create", null);

        // Assert - Should be idempotent 204
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    /// <summary>
    /// AC-05: GrantCapability_InvalidCapability_Returns400
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_InvalidCapability_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act - Capability not in catalog
        var response = await client.PostAsync("/api/admin/roles/auditor/capabilities/made:up", null);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    /// <summary>
    /// AC-06: GrantCapability_InvalidRole_Returns400
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_InvalidRole_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act - Invalid role `ceo`
        var response = await client.PostAsync("/api/admin/roles/ceo/capabilities/templates:create", null);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    /// <summary>
    /// AC-07: RevokeCapability_Exists_Returns204
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task RevokeCapability_Exists_Returns204()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        await client.PostAsync("/api/admin/roles/auditor/capabilities/templates:delete", null);

        // Act
        var response = await client.DeleteAsync("/api/admin/roles/auditor/capabilities/templates:delete");

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    /// <summary>
    /// AC-08: RevokeCapability_NotExists_Returns204
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task RevokeCapability_NotExists_Returns204()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act
        var response = await client.DeleteAsync("/api/admin/roles/auditor/capabilities/templates:delete");

        // Assert - Idempotent
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    /// <summary>
    /// AC-09: GrantCapability_NonAdmin_Returns403
    /// SKIP: Cannot test authorization on a route that doesn't exist yet. Returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_NonAdmin_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"bad_{Guid.NewGuid():N}@test.com", "Audit123!@", "Bad Actor", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditorClient.PostAsync("/api/admin/roles/auditor/capabilities/templates:create", null);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    /// <summary>
    /// AC-10: RevokeCapability_AdminSelfLockout_Returns400
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task RevokeCapability_AdminSelfLockout_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act - Try to revoke own ability to manage roles
        var response = await client.DeleteAsync("/api/admin/roles/admin/capabilities/admin:manage_roles");

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode); // Or 403
    }

    /// <summary>
    /// AC-11: GrantCapability_CaseInsensitiveRole_Returns400
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task GrantCapability_CaseInsensitiveRole_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act - Send capital ADMIN instead of admin
        var response = await client.PostAsync("/api/admin/roles/ADMIN/capabilities/templates:create", null);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
