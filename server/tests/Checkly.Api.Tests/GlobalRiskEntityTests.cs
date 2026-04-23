using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Checkly.Api.Tests;

public class GlobalRiskEntityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public GlobalRiskEntityTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GlobalRisk_CanInsertAndRetrieve()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk
        {
            Id = Guid.NewGuid(),
            Label = "Test Global Risk",
            Description = "Description",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        // Act
        db.GlobalRisks.Add(globalRisk);
        await db.SaveChangesAsync();

        // Assert
        var retrieved = await db.GlobalRisks.FindAsync(globalRisk.Id);
        Assert.NotNull(retrieved);
        Assert.Equal("Test Global Risk", retrieved.Label);
    }

    [Fact]
    public async Task GlobalRisk_IsActive_DefaultsToTrue()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk
        {
            Id = Guid.NewGuid(),
            Label = "Default Active Test"
        };

        // Act
        db.GlobalRisks.Add(globalRisk);
        await db.SaveChangesAsync();

        // Assert
        var retrieved = await db.GlobalRisks.FindAsync(globalRisk.Id);
        Assert.NotNull(retrieved);
        Assert.True(retrieved.IsActive);
    }

    [Fact]
    public Task GlobalRisk_UpdatedAt_IsIndexed_ForDeltaSync()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var entityType = db.Model.FindEntityType(typeof(GlobalRisk));
        var indexes = entityType?.GetIndexes();

        // Assert
        Assert.NotNull(entityType);
        Assert.NotNull(indexes);
        Assert.Contains(indexes, i => i.Properties.Any(p => p.Name == "UpdatedAt"));

        return Task.CompletedTask;
    }


    [Fact]
    public async Task SubmissionRisk_CanInsertWithValidFKs()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk { Id = Guid.NewGuid(), Label = "FK Test Risk" };
        db.GlobalRisks.Add(globalRisk);

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = null,
            StoreId = null,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Submissions.Add(submission);
        await db.SaveChangesAsync();

        var submissionRisk = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };

        // Act
        db.SubmissionRisks.Add(submissionRisk);
        await db.SaveChangesAsync();

        // Assert
        var retrieved = await db.SubmissionRisks.FindAsync(submissionRisk.Id);
        Assert.NotNull(retrieved);
        Assert.Equal(submissionRisk.GlobalRiskId, retrieved.GlobalRiskId);
    }

    [Fact]
    public async Task SubmissionRisk_UniqueConstraint_PreventsDuplicateTrigger()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk { Id = Guid.NewGuid(), Label = "Unique Constraint Risk" };
        db.GlobalRisks.Add(globalRisk);

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = null,
            StoreId = null,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Submissions.Add(submission);
        await db.SaveChangesAsync();

        var risk1 = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.SubmissionRisks.Add(risk1);
        await db.SaveChangesAsync();

        var risk2 = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };

        // Act
        db.SubmissionRisks.Add(risk2);
        var act = async () => await db.SaveChangesAsync();

        // Assert
        await Assert.ThrowsAsync<DbUpdateException>(act);
    }

    [Fact]
    public async Task SubmissionRisk_CascadeDelete_WhenSubmissionDeleted()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk { Id = Guid.NewGuid(), Label = "Cascade Risk" };
        db.GlobalRisks.Add(globalRisk);

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = null,
            StoreId = null,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Submissions.Add(submission);
        await db.SaveChangesAsync();

        var risk = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.SubmissionRisks.Add(risk);
        await db.SaveChangesAsync();

        // Act
        db.Submissions.Remove(submission);
        await db.SaveChangesAsync();

        // Assert
        var retrieved = await db.SubmissionRisks.FindAsync(risk.Id);
        Assert.Null(retrieved);
    }

    [Fact]
    public async Task SubmissionRisk_Restrict_WhenGlobalRiskDeleted()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk { Id = Guid.NewGuid(), Label = "Restrict Risk" };
        db.GlobalRisks.Add(globalRisk);

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = null,
            StoreId = null,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Submissions.Add(submission);
        await db.SaveChangesAsync();

        var risk = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.SubmissionRisks.Add(risk);
        await db.SaveChangesAsync();

        // Act — use a fresh scope so EF change tracker has no in-memory nav collection.
        // Without this, EF throws InvalidOperationException (client-side) before the DB
        // RESTRICT constraint can fire as DbUpdateException.
        using var deleteScope = _factory.Services.CreateScope();
        var deleteDb = deleteScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var riskToDelete = await deleteDb.GlobalRisks.FindAsync(globalRisk.Id);
        deleteDb.GlobalRisks.Remove(riskToDelete!);
        var act = async () => await deleteDb.SaveChangesAsync();

        // Assert
        await Assert.ThrowsAsync<DbUpdateException>(act);
    }

    [Fact]
    public async Task Submission_NavigationProperty_LoadsSubmissionRisks()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var globalRisk = new GlobalRisk { Id = Guid.NewGuid(), Label = "Nav Prop Risk" };
        db.GlobalRisks.Add(globalRisk);

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            TemplateId = null,
            StoreId = null,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Submissions.Add(submission);
        await db.SaveChangesAsync();

        var risk = new SubmissionRisk
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            GlobalRiskId = globalRisk.Id,
            TriggeredAt = DateTimeOffset.UtcNow,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.SubmissionRisks.Add(risk);
        await db.SaveChangesAsync();

        // Act
        var retrievedSubmission = await db.Submissions
            .Include(s => s.SubmissionRisks)
            .FirstOrDefaultAsync(s => s.Id == submission.Id);

        // Assert
        Assert.NotNull(retrievedSubmission);
        Assert.NotNull(retrievedSubmission.SubmissionRisks);
        Assert.Single(retrievedSubmission.SubmissionRisks);
        Assert.Equal(risk.Id, retrievedSubmission.SubmissionRisks.First().Id);
    }
}
