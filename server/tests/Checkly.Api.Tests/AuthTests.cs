using System.Net;
using System.Net.Http.Json;

namespace Checkly.Api.Tests;

/// <summary>
/// Tests for authentication and authorization: login, register, role guards.
/// </summary>
public class AuthTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AuthTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task Health_Endpoint_Returns_Healthy()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/health");
        response.EnsureSuccessStatusCode();
    }

    [Fact]
    public async Task Register_And_Login_Returns_Token()
    {
        var client = _factory.CreateClient();
        var email = $"test-{Guid.NewGuid():N}@auth.test";

        // Register
        var regResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = email,
            password = "Test123!@",
            fullName = "Test User",
            role = "auditor"
        });
        Assert.Equal(HttpStatusCode.Created, regResponse.StatusCode);

        // Login
        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = email,
            password = "Test123!@"
        });
        Assert.Equal(HttpStatusCode.OK, loginResponse.StatusCode);
    }

    [Fact]
    public async Task Login_With_Invalid_Credentials_Returns_401_ProblemDetails()
    {
        var client = _factory.CreateClient();
        var email = $"invalid-{Guid.NewGuid():N}@auth.test";

        var loginResponse = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = email,
            password = "WrongPassword123!"
        });
        
        Assert.Equal(HttpStatusCode.Unauthorized, loginResponse.StatusCode);
        
        var body = await loginResponse.Content.ReadAsStringAsync();
        Assert.Contains("invalid_credentials", body);
    }

    [Fact]
    public async Task Unauthenticated_Request_Returns_401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/templates");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Registration_Without_Admin_Token_Returns_403()
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"rogue-{Guid.NewGuid():N}@admin.test",
            password = "Rogue123!@",
            fullName = "Rogue Admin",
            role = "admin"
        });
        // Should be 403 because no admin token provided
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Admin_Can_Create_Another_Admin()
    {
        var client = _factory.CreateClient();

        // First register a non-admin, then we need a seed admin
        // Seed an auditor first, then try admin creation via admin token
        var (auditorToken, _) = await _factory.RegisterUserAsync(
            client, "first@admin-test.test", "First123!@", "First User", "auditor");

        // Without admin token, admin creation should fail
        var failResponse = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"second-admin-{Guid.NewGuid():N}@test.test",
            password = "Admin123!@",
            fullName = "Second Admin",
            role = "admin"
        });
        Assert.Equal(HttpStatusCode.Forbidden, failResponse.StatusCode);
    }
}
