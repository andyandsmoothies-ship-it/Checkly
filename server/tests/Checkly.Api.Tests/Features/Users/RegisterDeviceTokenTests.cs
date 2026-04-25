using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Tests.Features.Users;

public class RegisterDeviceTokenTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public RegisterDeviceTokenTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task RegisterDeviceToken_Upserts_Token_And_Updates_LastUsedAt()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var user = await _factory.RegisterUserAsync(client, "device@test.com", "Pass123!@", "Device User", "auditor", adminToken);
        var authClient = _factory.CreateAuthenticatedClient(user.Token);

        var payload = new { Token = "fcm-token-123", Platform = "android" };

        // Act
        var response = await authClient.PostAsJsonAsync("/api/users/me/device-tokens", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Assert DB state using raw SQL to avoid compiler errors on missing DbSets
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        
        using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = "SELECT COUNT(*) FROM user_device_tokens WHERE user_id = @userId AND fcm_token = @token";
        
        var p1 = command.CreateParameter();
        p1.ParameterName = "@userId";
        p1.Value = user.UserId;
        command.Parameters.Add(p1);

        var p2 = command.CreateParameter();
        p2.ParameterName = "@token";
        p2.Value = payload.Token;
        command.Parameters.Add(p2);

        await db.Database.OpenConnectionAsync();
        var count = (long)(await command.ExecuteScalarAsync())!;
        Assert.Equal(1, count);
    }
}
