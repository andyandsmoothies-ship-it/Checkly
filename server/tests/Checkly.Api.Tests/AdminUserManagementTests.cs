using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: CreateUser + ResetPassword admin endpoints.
/// Source: analysis_13_gaps.md Slices 2 & 3.
/// All tests RED until endpoints are implemented.
/// </summary>
public class AdminUserManagementTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AdminUserManagementTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ═══════════════════════════════════════════════════
    // Slice 2: CreateUser — POST /admin/users
    // Citation: analysis_13_gaps.md L117-130
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC1: Admin creates a user via POST /admin/users.
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task Admin_Can_Create_User()
    {
        // Arrange — login as bootstrap admin
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act — POST /admin/users (route does not exist yet)
        var response = await client.PostAsJsonAsync("/api/admin/users", new
        {
            email = $"newuser_{Guid.NewGuid():N}@test.com",
            password = "TempPass123!@",
            fullName = "Test User",
            role = "auditor"
        });

        // Assert — expects 201 Created
        // RED: route doesn't exist yet → 405 MethodNotAllowed (POST on GET-only /admin/users)
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    /// <summary>
    /// AC2: Non-admin cannot create users.
    /// SKIP: Cannot test authorization on a route that doesn't exist yet.
    /// Will return 405 (MethodNotAllowed) not 403 (Forbidden). Test after route is implemented.
    /// </summary>
    [Fact]
    public async Task NonAdmin_Cannot_Create_User()
    {
        // Arrange — register a non-admin user
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"auditor_{Guid.NewGuid():N}@test.com", "Audit123!@", "Auditor User", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditorClient.PostAsJsonAsync("/api/admin/users", new
        {
            email = "should-fail@test.com",
            password = "TempPass123!@",
            fullName = "Should Fail",
            role = "auditor"
        });

        // Assert — expects 403 Forbidden
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    /// <summary>
    /// AC3: Duplicate email should be rejected.
    /// RED reason: route does not exist.
    /// </summary>
    [Fact]
    public async Task Duplicate_Email_Rejected()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        var email = $"dup_{Guid.NewGuid():N}@test.com";

        // First create should succeed (once route exists)
        var first = await client.PostAsJsonAsync("/api/admin/users", new
        {
            email,
            password = "TempPass123!@",
            fullName = "First User",
            role = "auditor"
        });

        // Act — second create with same email
        var second = await client.PostAsJsonAsync("/api/admin/users", new
        {
            email,
            password = "TempPass123!@",
            fullName = "Duplicate User",
            role = "auditor"
        });

        // Assert — expects 409 Conflict or 400 BadRequest on duplicate
        // RED: first create also returns 405 since route doesn't exist
        Assert.True(
            second.StatusCode is HttpStatusCode.Conflict or HttpStatusCode.BadRequest,
            $"Expected 409/400 but got {second.StatusCode}");
    }

    // ═══════════════════════════════════════════════════
    // Slice 3: ResetPassword — POST /admin/users/{id}/reset-password
    // Citation: analysis_13_gaps.md L133-145
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC4: Admin resets a user's password. User can login with new password.
    /// RED reason: route does not exist — returns 404.
    /// </summary>
    [Fact]
    public async Task Admin_Can_Reset_Password()
    {
        // Arrange — create a user first via auth register
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (_, userId) = await _factory.RegisterUserAsync(
            client, $"resetme_{Guid.NewGuid():N}@test.com", "OldPass123!@", "Reset Target", "auditor", adminToken);

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act — reset password via admin endpoint
        var response = await client.PostAsJsonAsync($"/api/admin/users/{userId}/reset-password", new
        {
            newPassword = "NewPass456!@"
        });

        // Assert — expects 200 OK
        // RED: route doesn't exist yet → 404 or 405
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    /// <summary>
    /// AC5: Non-admin cannot reset passwords.
    /// SKIP: Cannot test authorization on a route that doesn't exist yet.
    /// </summary>
    [Fact]
    public async Task NonAdmin_Cannot_Reset_Password()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, $"nonreset_{Guid.NewGuid():N}@test.com", "Audit123!@", "Non Admin", "auditor", adminToken);

        var auditorClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await auditorClient.PostAsJsonAsync(
            $"/api/admin/users/{Guid.NewGuid()}/reset-password",
            new { newPassword = "NewPass456!@" });

        // Assert — expects 403
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    /// <summary>
    /// AC6: Reset password for non-existent user returns 404.
    /// SKIP: Currently passes for WRONG reason — gets routing 404, not business 404.
    /// After route is implemented, this test distinguishes "user not found" from "route not found".
    /// </summary>
    [Fact]
    public async Task Reset_NonExistent_User_Returns_404()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act — random GUID that doesn't exist
        var response = await client.PostAsJsonAsync(
            $"/api/admin/users/{Guid.NewGuid()}/reset-password",
            new { newPassword = "NewPass456!@" });

        // Assert — expects 404 NotFound from business logic
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    /// <summary>
    /// AC7: Weak password rejected by Identity policy.
    /// RED reason: route does not exist yet.
    /// </summary>
    [Fact]
    public async Task Weak_Password_Rejected()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (_, userId) = await _factory.RegisterUserAsync(
            client, $"weak_{Guid.NewGuid():N}@test.com", "Strong123!@", "Weak Target", "auditor", adminToken);

        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", adminToken);

        // Act — weak password "123"
        var response = await client.PostAsJsonAsync($"/api/admin/users/{userId}/reset-password", new
        {
            newPassword = "123"
        });

        // Assert — expects 400 BadRequest with password policy message
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
