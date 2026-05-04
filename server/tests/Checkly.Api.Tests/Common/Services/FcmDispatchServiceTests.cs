using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Tests.Services;

public class FcmDispatchServiceTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public FcmDispatchServiceTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task FcmDispatchService_Silently_Returns_If_User_Has_No_Tokens()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var userId = Guid.NewGuid();

        // This uses reflection to avoid CS0246 while the Builder hasn't implemented it yet. (Valid Red)
        var serviceType = Type.GetType("Checkly.Api.Common.Services.IFcmDispatchService, Checkly.Api");
        if (serviceType == null) throw new NotImplementedException("IFcmDispatchService is not defined yet.");

        var service = scope.ServiceProvider.GetRequiredService(serviceType);

        var method = serviceType.GetMethod("DispatchSyncNeededAsync");
        if (method == null) throw new NotImplementedException("DispatchSyncNeededAsync is not defined yet.");

        // Act
        var task = (Task)method.Invoke(service, new object[] { userId })!;
        await task;

        // Assert
        Assert.True(true); // Should not throw
    }

    [Fact]
    public async Task FcmDispatchService_Does_Not_Delete_InvalidToken123_When_Firebase_Not_Initialized()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var userId = Guid.NewGuid();

        // Insert the magic 'invalid-token-123' token using raw SQL to bypass compiler error for missing DbSet
        using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = "INSERT INTO user_device_tokens (id, user_id, fcm_token, platform, created_at, last_used_at) " +
                              "VALUES (@id, @userId, 'invalid-token-123', 'ios', now(), now())";

        var p1 = command.CreateParameter(); p1.ParameterName = "@id"; p1.Value = Guid.NewGuid(); command.Parameters.Add(p1);
        var p2 = command.CreateParameter(); p2.ParameterName = "@userId"; p2.Value = userId; command.Parameters.Add(p2);

        await db.Database.OpenConnectionAsync();
        await command.ExecuteNonQueryAsync();

        var serviceType = Type.GetType("Checkly.Api.Common.Services.IFcmDispatchService, Checkly.Api");
        if (serviceType == null) throw new NotImplementedException("IFcmDispatchService is not defined yet.");

        var service = scope.ServiceProvider.GetRequiredService(serviceType);

        var method = serviceType.GetMethod("DispatchSyncNeededAsync");
        if (method == null) throw new NotImplementedException("DispatchSyncNeededAsync is not defined yet.");

        // Act
        var task = (Task)method.Invoke(service, new object[] { userId })!;
        await task;

        // Assert
        using var checkCmd = db.Database.GetDbConnection().CreateCommand();
        checkCmd.CommandText = "SELECT COUNT(*) FROM user_device_tokens WHERE user_id = @userId";
        var p3 = checkCmd.CreateParameter(); p3.ParameterName = "@userId"; p3.Value = userId; checkCmd.Parameters.Add(p3);

        var count = (long)(await checkCmd.ExecuteScalarAsync())!;

        // In the test environment, FirebaseAdmin is not initialized.
        // It should simply log a warning and return. It should NOT contain magic fallback logic that deletes 'invalid-token-123'.
        Assert.Equal(1, count); // Token MUST remain.
    }
}
