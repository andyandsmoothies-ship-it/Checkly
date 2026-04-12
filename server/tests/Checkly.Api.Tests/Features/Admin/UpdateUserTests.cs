using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Admin;

[Trait("Category", "Admin")]
public class UpdateUserTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public UpdateUserTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Admin_CannotDemoteOwnAccount_ReturnsBadRequest()
    {
        // Arrange
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Fetch bootstrap admin's userId
        var listResponse = await authClient.GetAsync("/api/admin/users?search=bootstrap@admin.test");
        listResponse.EnsureSuccessStatusCode();
        var pagedResult = await listResponse.Content.ReadFromJsonAsync<JsonElement>();
        var items = pagedResult.GetProperty("items").EnumerateArray();
        
        Guid? adminUserId = null;
        foreach (var item in items)
        {
            if (item.GetProperty("email").GetString() == "bootstrap@admin.test")
            {
                adminUserId = item.GetProperty("id").GetGuid();
                break;
            }
        }
        
        Assert.NotNull(adminUserId);

        var request = new { role = "auditor" };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{adminUserId.Value}", request);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Contains("Cannot demote your own admin account. Have another admin perform this action.", json.GetProperty("error").GetString()!);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Admin_CanUpdateOtherUser_ReturnsOk()
    {
        // Arrange
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Fetch bootstrap admin's userId to make sure it exists, though not strictly required,
        // we just need to ensure we use a DIFFERENT user. Registering a new one does this.
        var (_, otherUserId) = await _factory.RegisterUserAsync(client, "other_smt99@admin.test", "Pass123!", "Other User", "auditor", adminToken);

        var request = new { role = "store_manager" };

        // Act
        var response = await authClient.PutAsJsonAsync($"/api/admin/users/{otherUserId}", request);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Admin_RoleChange_InvalidatesExistingToken_Returns401()
    {
        // 1. Arrange — Create a user and get their token
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var email = $"revocation_{Guid.NewGuid()}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Pass1234!", "Token User", "store_manager", adminToken);

        // Verify token works initially
        var userClient = _factory.CreateAuthenticatedClient(token);
        var initialResponse = await userClient.GetAsync("/api/notifications");
        Assert.Equal(HttpStatusCode.OK, initialResponse.StatusCode);

        // 2. Act — Admin demotes user to auditor
        var demoteRequest = new { role = "auditor" };
        var demoteResponse = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", demoteRequest);
        demoteResponse.EnsureSuccessStatusCode();

        // 3. Assert — Old token is now rejected
        var postRevokeResponse = await userClient.GetAsync("/api/notifications");
        Assert.Equal(HttpStatusCode.Unauthorized, postRevokeResponse.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Admin_ProfileUpdateOnly_DoesNotInvalidateToken_Returns200()
    {
        // 1. Arrange
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var email = $"profile_update_{Guid.NewGuid()}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Pass1234!", "Original Name", "store_manager", adminToken);

        var userClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act — Admin updates name only (no role change)
        var updateRequest = new { fullName = "Updated Name" };
        var updateResponse = await authClient.PutAsJsonAsync($"/api/admin/users/{userId}", updateRequest);
        updateResponse.EnsureSuccessStatusCode();

        // 3. Assert — Token still works
        var checkResponse = await userClient.GetAsync("/api/notifications");
        Assert.Equal(HttpStatusCode.OK, checkResponse.StatusCode);
    }

    [Fact]
    [Trait("Category", "Admin")]
    public async Task Admin_DeleteUser_InvalidatesToken_Returns401()
    {
        // 1. Arrange
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var email = $"delete_test_{Guid.NewGuid()}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(client, email, "Pass1234!", "Delete Me", "auditor", adminToken);

        var userClient = _factory.CreateAuthenticatedClient(token);

        // 2. Act — Delete user from DB directly in test (simulating admin delete)
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var user = await db.Users.FindAsync(userId);
            if (user != null)
            {
                db.Users.Remove(user);
                await db.SaveChangesAsync();
            }
        }

        // 3. Assert — Token is now rejected
        var checkResponse = await userClient.GetAsync("/api/notifications");
        Assert.Equal(HttpStatusCode.Unauthorized, checkResponse.StatusCode);
    }
}
