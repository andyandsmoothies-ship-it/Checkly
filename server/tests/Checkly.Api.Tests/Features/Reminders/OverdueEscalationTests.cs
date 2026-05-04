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

        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        // Create Area Manager
        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Areas.Add(new Area { Id = areaId, Name = "Overdue Area" });
        db.Stores.Add(new Store { Id = storeId, Name = "Overdue Store", AreaId = areaId, IsActive = true });
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

        // Link AM to Area
        var amProfile = await db.Profiles.FindAsync(amReg.UserId);
        Assert.NotNull(amProfile);
        amProfile.AreaId = areaId;
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

        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Areas.Add(new Area { Id = areaId, Name = "Dup Area" });
        db.Stores.Add(new Store { Id = storeId, Name = "Dup Store", AreaId = areaId, IsActive = true });
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

        var amProfile = await db.Profiles.FindAsync(amReg.UserId);
        amProfile!.AreaId = areaId;
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

        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        db.Areas.Add(new Area { Id = areaId, Name = "Orphan Area" });
        db.Stores.Add(new Store { Id = storeId, Name = "Orphan Store", AreaId = areaId, IsActive = true });
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

        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var apId = Guid.NewGuid();

        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager", "area_manager");

        db.Areas.Add(new Area { Id = areaId, Name = "Closed Area" });
        db.Stores.Add(new Store { Id = storeId, Name = "Closed Store", AreaId = areaId, IsActive = true });
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

        var amProfile = await db.Profiles.FindAsync(amReg.UserId);
        amProfile!.AreaId = areaId;
        await db.SaveChangesAsync();

        var service = CreateService(scope.ServiceProvider.GetRequiredService<IServiceScopeFactory>());

        // Act
        await service.SendOverdueEscalations(db, CancellationToken.None);

        // Assert
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.ActionUrl == $"/action-plans/{apId}" && n.Type == "action_plan_overdue_escalation");
        Assert.Null(notification);
    }
}
