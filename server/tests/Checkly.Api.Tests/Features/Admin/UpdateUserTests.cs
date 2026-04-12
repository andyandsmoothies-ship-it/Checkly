using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
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
}
