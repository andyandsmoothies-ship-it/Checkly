using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Notifications;

/// <summary>
/// TDD Tests for F4 IDOR Hardening: Mark Notification Read.
/// </summary>
public class MarkNotificationReadTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public MarkNotificationReadTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task User_CanMarkOwnNotification_Returns204()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var (token, userId) = await _factory.RegisterUserAsync(client, "owner@test.test", "Pass123!@", "Owner", "auditor");
        var notificationId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Notifications.Add(new Notification
            {
                Id = notificationId,
                UserId = userId,
                Type = "test",
                Title = "Test Notification",
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        var authClient = _factory.CreateAuthenticatedClient(token);

        // ACT
        var response = await authClient.PostAsync($"/api/notifications/{notificationId}/read", null);

        // ASSERT
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        // Verify DB update
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var notification = await db.Notifications.FindAsync(notificationId);
            Assert.NotNull(notification?.ReadAt);
        }
    }

    [Fact]
    public async Task User_CannotMarkOtherUsersNotification_Returns404()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var (ownerToken, ownerId) = await _factory.RegisterUserAsync(client, "victim@test.test", "Pass123!@", "Victim", "auditor");
        var (attackerToken, attackerId) = await _factory.RegisterUserAsync(client, "attacker@test.test", "Pass123!@", "Attacker", "auditor");

        var notificationId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Notifications.Add(new Notification
            {
                Id = notificationId,
                UserId = ownerId, // Owned by Victim
                Type = "test",
                Title = "Top Secret",
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        var attackerClient = _factory.CreateAuthenticatedClient(attackerToken);

        // ACT
        var response = await attackerClient.PostAsync($"/api/notifications/{notificationId}/read", null);

        // ASSERT
        // Expect 404 (IDOR Protection via Obscurity)
        // RED CHECK: Currently production returns 204 because it lacks UserId filtering.
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);

        // Verify DB NOT updated
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var notification = await db.Notifications.FindAsync(notificationId);
            Assert.Null(notification?.ReadAt);
        }
    }

    [Fact]
    public async Task MarkRead_NonExistentNotification_Returns404()
    {
        // ARRANGE
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(client, "lonely@test.test", "Pass123!@", "Lonely", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(token);
        var fakeId = Guid.NewGuid();

        // ACT
        var response = await authClient.PostAsync($"/api/notifications/{fakeId}/read", null);

        // ASSERT
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
