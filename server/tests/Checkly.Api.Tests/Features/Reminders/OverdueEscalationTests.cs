using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace Checkly.Api.Tests.Features.Reminders;

[Collection("Sequential")]
public class OverdueEscalationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public OverdueEscalationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private ReminderService CreateService(IServiceScopeFactory scopeFactory)
    {
        return new ReminderService(
            scopeFactory,
            null!, // DistributedLockManager not needed for internal method testing
            NullLogger<ReminderService>.Instance);
    }

    [Fact]
    public async Task SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        // Create Area Manager
        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Stores.Add(new Store { Id = storeId, Name = "Overdue Store", IsActive = true });
        db.Templates.Add(new Template { Id = Guid.NewGuid(), Title = "Template", Version = 1, IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = storeId,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            SubmissionId = submissionId,
            CriteriaLabel = "Fix the lights",
            StoreId = storeId,
            StoreName = "Overdue Store",
            Status = "overdue", // Status is overdue
            Deadline = DateTimeOffset.UtcNow.AddDays(-2), // 48 hours ago
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        // Link AM to Store via ProfileStoreAssignment
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = amReg.UserId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "action_plan_overdue_escalation");
        Assert.NotNull(notification);
        Assert.Equal(amReg.UserId, notification.UserId);
    }

    [Fact]
    public async Task SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Stores.Add(new Store { Id = storeId, Name = "Dup Store", IsActive = true });
        db.Templates.Add(new Template { Id = Guid.NewGuid(), Title = "Template", Version = 1, IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = storeId,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            SubmissionId = submissionId,
            CriteriaLabel = "Duplicate test",
            StoreId = storeId,
            StoreName = "Dup Store",
            Status = "overdue",
            Deadline = DateTimeOffset.UtcNow.AddDays(-2),
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Pre-insert the notification to simulate it already escalated
        db.Notifications.Add(new Notification
        {
            Id = Guid.NewGuid(),
            UserId = amReg.UserId,
            Type = "action_plan_overdue_escalation",
            Title = "Already Escalated",
            ActionUrl = $"/action-plans/{apId}",
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = amReg.UserId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notifications = await db.Notifications
            .Where(n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "action_plan_overdue_escalation")
            .ToListAsync();

        Assert.Single(notifications); // Should only be the one we seeded, no duplicate created
    }

    [Fact]
    public async Task SendOverdueEscalations_NoAreaManager_SkipsAP()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeId, Name = "Orphan Store", IsActive = true });
        db.Templates.Add(new Template { Id = Guid.NewGuid(), Title = "Template", Version = 1, IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = storeId,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            SubmissionId = submissionId,
            CriteriaLabel = "No AM test",
            StoreId = storeId,
            StoreName = "Orphan Store",
            Status = "overdue",
            Deadline = DateTimeOffset.UtcNow.AddDays(-2),
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        // Notice: We do not create or link an area manager to this area.

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "action_plan_overdue_escalation");
        Assert.Null(notification); // No notification generated
    }

    [Fact]
    public async Task SendOverdueEscalations_ClosedPlan_SkipsAP()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Stores.Add(new Store { Id = storeId, Name = "Closed Store", IsActive = true });
        db.Templates.Add(new Template { Id = Guid.NewGuid(), Title = "Template", Version = 1, IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = storeId,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = apId,
            SubmissionId = submissionId,
            CriteriaLabel = "Closed test",
            StoreId = storeId,
            StoreName = "Closed Store",
            Status = "closed", // Even if it was overdue, it's closed now
            Deadline = DateTimeOffset.UtcNow.AddDays(-2),
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = amReg.UserId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "action_plan_overdue_escalation");
        Assert.Null(notification);
    }

    [Fact]
    public async Task SendOverdueEscalations_MultipleStores_SendsToRespectiveManagers()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var store1Id = Guid.NewGuid();
        var submission1Id = Guid.NewGuid();
        var ap1Id = Guid.NewGuid();

        var store2Id = Guid.NewGuid();
        var submission2Id = Guid.NewGuid();
        var ap2Id = Guid.NewGuid();

        // Create 2 Area Managers
        var am1Reg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am1_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager One", "area_manager");
        var am2Reg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am2_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager Two", "area_manager");

        db.Stores.Add(new Store { Id = store1Id, Name = "Store One", IsActive = true });
        db.Stores.Add(new Store { Id = store2Id, Name = "Store Two", IsActive = true });
        
        db.Templates.Add(new Template { Id = Guid.NewGuid(), Title = "Template", Version = 1, IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = submission1Id,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = store1Id,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        db.Submissions.Add(new Submission
        {
            Id = submission2Id,
            TemplateId = db.Templates.Local.First().Id,
            StoreId = store2Id,
            AuditorId = Guid.NewGuid(),
            Status = "completed",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = ap1Id,
            SubmissionId = submission1Id,
            CriteriaLabel = "Multi test 1",
            StoreId = store1Id,
            StoreName = "Store One",
            Status = "overdue",
            Deadline = DateTimeOffset.UtcNow.AddDays(-2),
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });
        db.ActionPlans.Add(new ActionPlan
        {
            Id = ap2Id,
            SubmissionId = submission2Id,
            CriteriaLabel = "Multi test 2",
            StoreId = store2Id,
            StoreName = "Store Two",
            Status = "overdue",
            Deadline = DateTimeOffset.UtcNow.AddDays(-2),
            CreatedAt = DateTimeOffset.UtcNow.AddDays(-5),
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        // Link AM1 to Store 1 and AM2 to Store 2 via ProfileStoreAssignment
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = am1Reg.UserId,
            StoreId = store1Id,
            CreatedAt = DateTimeOffset.UtcNow
        });
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = am2Reg.UserId,
            StoreId = store2Id,
            CreatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notifications = await db.Notifications
            .Where(n => n.Type == "action_plan_overdue_escalation"
                     && (n.ActionUrl == $"/action-plans/{ap1Id}" || n.ActionUrl == $"/action-plans/{ap2Id}"))
            .ToListAsync();

        Assert.Equal(2, notifications.Count);
        Assert.Contains(notifications, n => n.UserId == am1Reg.UserId && n.ActionUrl == $"/action-plans/{ap1Id}");
        Assert.Contains(notifications, n => n.UserId == am2Reg.UserId && n.ActionUrl == $"/action-plans/{ap2Id}");
    }
}
