using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Checkly.Api.Tests.Features.Notifications;

[Trait("Category", "Reminder")]
[Collection("ApiCollection")]
public class ReminderServiceRetentionTests(TestWebApplicationFactory fixture)
    : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private IServiceProvider _sp = null!;

    public async Task InitializeAsync()
    {
        _sp = fixture.Services;
        fixture.EnsureDatabaseCreated();
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.ExecuteSqlRawAsync("SELECT 1;"); // warm up connection
    }

    public Task DisposeAsync() => Task.CompletedTask;

    /// <summary>
    /// T6: Notifications older than 90 days must be deleted by RunRetentionCleanup.
    /// </summary>
    [Fact]
    public async Task RunRetentionCleanup_OldNotifications_ArePurged()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Resolve bootstrap admin to satisfy the FK on Notification.UserId
        var adminUser = await db.Users.FirstAsync(u => u.Email == "bootstrap@admin.test");

        var oldNotificationId = Guid.NewGuid();
        db.Notifications.Add(new Checkly.Api.Common.Persistence.Entities.Notification
        {
            Id = oldNotificationId,
            UserId = adminUser.Id,
            Type = "test_old",
            Title = "Old Notification",
            Message = "This should be purged",
            ActionUrl = null,
            ReadAt = null,
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-91), // 91 days old → past the 90-day cutoff
        });
        await db.SaveChangesAsync();

        var service = new ReminderService(
            _sp.GetRequiredService<IServiceScopeFactory>(),
            NullLogger<ReminderService>.Instance);

        // Act — call RunRetentionCleanup directly (internal via InternalsVisibleTo)
        // Note: the 24h guard now lives in ExecuteAsync, so this always runs when called directly.
        await service.RunRetentionCleanup(db, CancellationToken.None);

        // Assert
        var exists = await db.Notifications.AnyAsync(n => n.Id == oldNotificationId);
        Assert.False(exists, "Notification older than 90 days must be purged by RunRetentionCleanup.");
    }

    /// <summary>
    /// T7: Recent notifications must NOT be deleted by RunRetentionCleanup.
    /// </summary>
    [Fact]
    public async Task RunRetentionCleanup_RecentNotifications_AreKept()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var adminUser = await db.Users.FirstAsync(u => u.Email == "bootstrap@admin.test");

        var recentNotificationId = Guid.NewGuid();
        db.Notifications.Add(new Checkly.Api.Common.Persistence.Entities.Notification
        {
            Id = recentNotificationId,
            UserId = adminUser.Id,
            Type = "test_recent",
            Title = "Recent Notification",
            Message = "This must NOT be purged",
            ActionUrl = null,
            ReadAt = null,
            CreatedAt = DateTimeOffset.UtcNow, // today → within the 90-day window
        });
        await db.SaveChangesAsync();

        var service = new ReminderService(
            _sp.GetRequiredService<IServiceScopeFactory>(),
            NullLogger<ReminderService>.Instance);

        // Act
        await service.RunRetentionCleanup(db, CancellationToken.None);

        // Assert
        var exists = await db.Notifications.AnyAsync(n => n.Id == recentNotificationId);
        Assert.True(exists, "Recent notifications (within 90 days) must NOT be purged by RunRetentionCleanup.");
    }
}
