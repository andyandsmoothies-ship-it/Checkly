using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class FinalizeSubmission_ManagerSnapshot_EdgeTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public FinalizeSubmission_ManagerSnapshot_EdgeTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task FinalizeSubmission_WhenAmProfileIsDeletedBeforeFinalization_SucceedsWithNullAmInfo()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        // 1. Create Area Manager
        var amReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"am_{Guid.NewGuid()}@test.com", "Aa1234567@", "Area Manager User", "area_manager");

        // 2. Create Auditor
        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        db.Templates.Add(new Template { Id = templateId, Title = "Snapshot Test", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Snapshot Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = 1.0m };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorReg.UserId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = $"{{\"groups\":[{{\"id\":\"{group.Id}\",\"title\":\"G1\",\"criteria\":[{{\"id\":\"{criteria.Id}\",\"groupId\":\"{group.Id}\",\"label\":\"C1\",\"inputType\":\"pass_fail\",\"pointsWeight\":10}}]}}]}}"
        });

        await db.SaveChangesAsync();

        // Link Area Manager to Store via junction table
        db.ProfileStoreAssignments.Add(new ProfileStoreAssignment
        {
            ProfileId = amReg.UserId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        // Act - Delete the AM Profile from db (simulating AM profile deletion)
        var amProfile = await db.Profiles.FindAsync(amReg.UserId);
        Assert.NotNull(amProfile);
        db.Profiles.Remove(amProfile);
        await db.SaveChangesAsync();

        // Client is logged in as AUDITOR
        var client = _factory.CreateAuthenticatedClient(auditorReg.Token);

        var payload = new
        {
            ClientScore = 100m,
            SectionScores = $"{{\"G1\":{{\"score\":10,\"maxScore\":10}}}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 10m, Value = "conform" }
            }
        };

        var response = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Load fresh DB context to verify snapshot fields are null
        using var assertScope = _factory.Services.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var finalizedSub = await assertDb.Submissions.FindAsync(submissionId);

        Assert.NotNull(finalizedSub);
        Assert.Equal("completed", finalizedSub.Status);

        // Properties under test must be null since AM profile is deleted
        Assert.Null(finalizedSub.AreaManagerId);
        Assert.Null(finalizedSub.AreaManagerName);
    }

    [Fact]
    public async Task FinalizeSubmission_WhenSubmissionIsAlreadyCompleted_ReturnsConflictAndDoesNotMutate()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        // 1. Create Auditor
        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        db.Templates.Add(new Template { Id = templateId, Title = "Snapshot Test", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Snapshot Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = 1.0m };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        var originalAmId = Guid.NewGuid();
        var originalAmName = "Original AM Name";
        var originalSmId = Guid.NewGuid();
        var originalSmName = "Original SM Name";

        var completedSubmission = new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorReg.UserId,
            Status = "completed", // already completed
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = $"{{\"groups\":[{{\"id\":\"{group.Id}\",\"title\":\"G1\",\"criteria\":[{{\"id\":\"{criteria.Id}\",\"groupId\":\"{group.Id}\",\"label\":\"C1\",\"inputType\":\"pass_fail\",\"pointsWeight\":10}}]}}]}}",
            // Preset snapshots that should NOT be modified
            AreaManagerId = originalAmId,
            AreaManagerName = originalAmName,
            StoreManagerId = originalSmId,
            StoreManagerName = originalSmName
        };
        db.Submissions.Add(completedSubmission);

        await db.SaveChangesAsync();

        // Client is logged in as AUDITOR
        var client = _factory.CreateAuthenticatedClient(auditorReg.Token);

        var payload = new
        {
            ClientScore = 100m,
            SectionScores = $"{{\"G1\":{{\"score\":10,\"maxScore\":10}}}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 10m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);

        // Load fresh DB context to verify snapshot fields are untouched
        using var assertScope = _factory.Services.CreateScope();
        var assertDb = assertScope.ServiceProvider.GetRequiredService<AppDbContext>();
        var finalizedSub = await assertDb.Submissions.FindAsync(submissionId);

        Assert.NotNull(finalizedSub);
        Assert.Equal("completed", finalizedSub.Status);
        Assert.Equal(originalAmId, finalizedSub.AreaManagerId);
        Assert.Equal(originalAmName, finalizedSub.AreaManagerName);
        Assert.Equal(originalSmId, finalizedSub.StoreManagerId);
        Assert.Equal(originalSmName, finalizedSub.StoreManagerName);
    }
}
