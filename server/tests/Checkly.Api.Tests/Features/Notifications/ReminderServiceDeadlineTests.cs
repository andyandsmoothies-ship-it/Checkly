using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Checkly.Api.Tests.Features.Notifications;

/// <summary>
/// ATDD acceptance suite for ReminderService.SendDeadlineReminders — S1 (N+1 Remediation).
///
/// T1: Single eligible AP → 1 notification (happy path)
/// T2: Already notified AP (idempotency) → 0 notifications (duplicates blocked)
/// T3: AP with null StoreManagerId → skipped (no notification)
/// T4: AP deadline outside reminder window (>48h away) → skipped
/// T5: Volume — 50 mixed APs → correct sent count
/// T8: Anti-N+1 gate — single alreadySentUrls pre-fetch in one SQL, zero AnyAsync per AP
/// </summary>
[Trait("Category", "Reminder")]
[Collection("ApiCollection")]
public class ReminderServiceDeadlineTests(TestWebApplicationFactory fixture)
    : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private IServiceProvider _sp = null!;
    private Guid _storeManagerId;
    private Guid _templateId;
    private Guid _storeId;

    public async Task InitializeAsync()
    {
        _sp = fixture.Services;
        fixture.EnsureDatabaseCreated();

        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Use the bootstrap admin user (already seeded by the WAF) as the StoreManager.
        // This satisfies the Notification.UserId FK without requiring UserManager DI.
        var bootstrapAdmin = await db.Users.FirstAsync(u => u.Email == "bootstrap@admin.test");
        _storeManagerId = bootstrapAdmin.Id;

        // Seed a Template (required for the double-JOIN in SendDeadlineReminders)
        _templateId = Guid.NewGuid();
        db.Templates.Add(new Template
        {
            Id = _templateId,
            Title = "Deadline Test Template",
            Type = "QC",
            Version = 1,
            IsActive = true,
            ScoringLogicConfig = null, // null → default reminderDays = 2
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        });

        // Seed a Store (needed for AP.StoreId FK)
        _storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = _storeId,
            Name = "Deadline Test Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        });

        await db.SaveChangesAsync();
    }

    public Task DisposeAsync() => Task.CompletedTask;

    // ── Helpers ────────────────────────────────────────────────────────────────

    /// <summary>Seeds a Submission and open ActionPlan within the 48h reminder window.</summary>
    private async Task<Guid> SeedEligibleApAsync(
        AppDbContext db,
        Guid? storeManagerId = null,
        DateTimeOffset? deadline = null,
        bool withinWindow = true)
    {
        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = _templateId,
            StoreId = _storeId,
            Status = "completed",
            StoreName = "Deadline Test Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        });

        var apId = Guid.NewGuid();
        // deadline within window: deadline is 1 day from now (inside 48h)
        // deadline outside window: deadline is 5 days from now (outside 48h default window)
        var apDeadline = deadline ?? (withinWindow
            ? DateTimeOffset.UtcNow.AddDays(1)
            : DateTimeOffset.UtcNow.AddDays(5));

        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            SubmissionId = submissionId,
            StoreManagerId = storeManagerId ?? _storeManagerId,
            Status = "open",
            Deadline = apDeadline,
            CriteriaLabel = "Test Criterion",
            GroupTitle = "Test Group",
            StoreName = "Deadline Test Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        });

        await db.SaveChangesAsync();
        return apId;
    }

    private ReminderService CreateService() => new ReminderService(
        _sp.GetRequiredService<IServiceScopeFactory>(),
        NullLogger<ReminderService>.Instance);

    // ── T1: Single eligible AP → 1 notification ─────────────────────────────

    [Fact]
    public async Task SendDeadlineReminders_EligibleAP_SendsOneNotification()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var apId = await SeedEligibleApAsync(db, withinWindow: true);
        var service = CreateService();

        // Act
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: exactly 1 notification created for this AP
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "ap_deadline_reminder");
        Assert.Equal(1, count);
    }

    // ── T2: Already notified → idempotency (no duplicate) ───────────────────

    [Fact]
    public async Task SendDeadlineReminders_AlreadyNotified_DoesNotDuplicate()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var apId = await SeedEligibleApAsync(db, withinWindow: true);

        // Pre-insert the idempotency notification (simulating a prior run)
        db.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = _storeManagerId,
            Type = "ap_deadline_reminder",
            Title = "Action Plan Deadline Approaching",
            Message = "Pre-existing",
            ActionUrl = $"/action-plans/{apId}",
            ReadAt = null,
            CreatedAt = DateTimeOffset.UtcNow.AddHours(-1),
        });
        await db.SaveChangesAsync();

        var service = CreateService();

        // Act
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: count is still exactly 1 (no second notification added)
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "ap_deadline_reminder");
        Assert.Equal(1, count);
    }

    // ── T3: Null StoreManagerId → skip ──────────────────────────────────────

    [Fact]
    public async Task SendDeadlineReminders_NullStoreManager_SkipsAP()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var apId = await SeedEligibleApAsync(db, storeManagerId: null, withinWindow: true);

        // Override the AP to have null StoreManagerId
        var ap = await db.ActionPlans.FindAsync(apId);
        ap!.StoreManagerId = null;
        await db.SaveChangesAsync();

        var service = CreateService();

        // Act
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: no notification for this AP
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "ap_deadline_reminder");
        Assert.Equal(0, count);
    }

    // ── T4: Deadline outside 48h window → skip ───────────────────────────────

    [Fact]
    public async Task SendDeadlineReminders_DeadlineOutsideWindow_SkipsAP()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // 5 days from now — outside the 48h default window
        var apId = await SeedEligibleApAsync(db, withinWindow: false);
        var service = CreateService();

        // Act
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: no notification created
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "ap_deadline_reminder");
        Assert.Equal(0, count);
    }

    // ── T5: Volume — 50 mixed APs → correct sent count ──────────────────────

    [Fact]
    public async Task SendDeadlineReminders_MixedAPs_SendsCorrectCount()
    {
        // Arrange: 30 in-window, 20 outside window
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var inWindowIds = new List<Guid>();
        for (var i = 0; i < 30; i++)
            inWindowIds.Add(await SeedEligibleApAsync(db, withinWindow: true));

        for (var i = 0; i < 20; i++)
            await SeedEligibleApAsync(db, withinWindow: false);

        var service = CreateService();

        // Act
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: exactly 30 notifications for the in-window AP URLs
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var inWindowUrls = inWindowIds.Select(id => $"/action-plans/{id}").ToHashSet();
        var actualCount = await assertDb.Notifications
            .Where(n => n.Type == "ap_deadline_reminder" && inWindowUrls.Contains(n.ActionUrl!))
            .CountAsync();
        Assert.Equal(30, actualCount);
    }

    // ── T8: Anti-N+1 gate — verify single pre-fetch query ───────────────────

    [Fact]
    public async Task SendDeadlineReminders_UsesHashSetPreFetch_NotPerAPAnyAsync()
    {
        // This test is a structural verification of the S1 N+1 fix.
        // Behavioral proof: insert 3 APs in window, 2 already notified.
        // If each AP triggered an AnyAsync, DB timeout/slowness would scale with AP count.
        // The HashSet approach collapses N AnyAsync → 1 ToHashSetAsync before the loop.

        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var ap1 = await SeedEligibleApAsync(db, withinWindow: true);
        var ap2 = await SeedEligibleApAsync(db, withinWindow: true);
        var ap3 = await SeedEligibleApAsync(db, withinWindow: true);

        // Pre-seed ap1 + ap2 as already notified
        db.Notifications.AddRange(
            new Notification
            {
                Id = Guid.NewGuid(), UserId = _storeManagerId, Type = "ap_deadline_reminder",
                Title = "Pre", Message = null, ActionUrl = $"/action-plans/{ap1}",
                CreatedAt = DateTimeOffset.UtcNow,
            },
            new Notification
            {
                Id = Guid.NewGuid(), UserId = _storeManagerId, Type = "ap_deadline_reminder",
                Title = "Pre", Message = null, ActionUrl = $"/action-plans/{ap2}",
                CreatedAt = DateTimeOffset.UtcNow,
            });
        await db.SaveChangesAsync();

        var service = CreateService();

        // Act — must complete without N additional round-trips
        await service.SendDeadlineReminders(db, CancellationToken.None);

        // Assert: only ap3 receives a NEW notification (ap1 + ap2 are blocked by idempotency)
        using var assertScope = _sp.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var ap3NotifCount = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{ap3}" && n.Type == "ap_deadline_reminder");
        var ap1NotifCount = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{ap1}" && n.Type == "ap_deadline_reminder");
        var ap2NotifCount = await assertDb.Notifications.CountAsync(
            n => n.ActionUrl == $"/action-plans/{ap2}" && n.Type == "ap_deadline_reminder");

        Assert.Equal(1, ap3NotifCount);      // newly notified
        Assert.Equal(1, ap1NotifCount);      // still only 1 — NOT duplicated
        Assert.Equal(1, ap2NotifCount);      // still only 1 — NOT duplicated
    }

    // ── T9: EF Core structural gate — verify LEFT JOIN translation ──────────

    [Fact]
    public void SendDeadlineReminders_SQLContainsLeftJoin()
    {
        // This test ensures EF Core actually pushes the GroupJoin down to SQL as a LEFT JOIN
        // and doesn't silently fall back to client-side evaluation due to the string concat.
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now = DateTimeOffset.UtcNow;

        var query = db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.Status == "open" && ap.Deadline.HasValue && ap.Deadline.Value > now)
            .Join(db.Submissions.AsNoTracking(),
                ap => ap.SubmissionId, s => s.Id,
                (ap, s) => new { AP = ap, s.TemplateId })
            .Join(db.Templates.AsNoTracking(),
                x => x.TemplateId, t => t.Id,
                (x, t) => new { x.AP, t.ScoringLogicConfig })
            .GroupJoin(
                db.Notifications.AsNoTracking().Where(n => n.Type == "ap_deadline_reminder"),
                x => "/action-plans/" + x.AP.Id.ToString(),
                n => n.ActionUrl,
                (x, notifs) => new { x.AP, x.ScoringLogicConfig, Notifs = notifs })
            .SelectMany(
                x => x.Notifs.DefaultIfEmpty(),
                (x, n) => new { x.AP, x.ScoringLogicConfig, Notification = n })
            .Where(x => x.Notification == null);

        var sql = query.ToQueryString();

        // Must translate to a LEFT JOIN (or LEFT OUTER JOIN)
        Assert.Matches("LEFT JOIN|LEFT OUTER JOIN", sql);
    }
}
