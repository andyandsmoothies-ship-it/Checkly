using System.Net;
using System.Net.Http.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class FinalizeSubmissionConcurrencyTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public FinalizeSubmissionConcurrencyTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task FinalizeSubmission_WhenConcurrentRequests_ExactlyOneSucceeds()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"concur_{Guid.NewGuid()}@test.com", "Aa1234567@", "Concur Auditor", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Concur Test", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Concur Store", IsActive = true });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = 1.0m };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = "{\"Groups\":[{\"Id\":\"" + group.Id + "\",\"Title\":\"G1\",\"Criteria\":[{\"Id\":\"" + criteria.Id + "\",\"Label\":\"C1\",\"InputType\":\"pass_fail\",\"PointsWeight\":10}]}]}"
        });

        await db.SaveChangesAsync();

        var client1 = _factory.CreateAuthenticatedClient(token);
        var client2 = _factory.CreateAuthenticatedClient(token);
        
        var payload = new
        {
            ClientScore = 100m,
            SectionScores = "{\"G1\":{\"score\":10,\"maxScore\":10}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 10m, Value = "conform" }
            }
        };

        // Act
        // Fire two requests simultaneously
        var task1 = client1.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);
        var task2 = client2.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        await Task.WhenAll(task1, task2);
        var response1 = await task1;
        var response2 = await task2;

        // Assert
        var results = new[] { response1.StatusCode, response2.StatusCode };
        
        // One must be 200, one must be 409
        // NOTE: In SQLite, this might fail (both 200) because SQLite serializes writes.
        // We expect it to be RED now because both will return 200 (or one might hit the sequential guard if timing is "lucky")
        // but it won't return the *concurrency* conflict message.
        Assert.Contains(HttpStatusCode.OK, results);
        Assert.Contains(HttpStatusCode.Conflict, results);

        if (response1.StatusCode == HttpStatusCode.Conflict)
        {
            var content = await response1.Content.ReadAsStringAsync();
            Assert.Contains("Submission is being finalized by another request. Please retry.", content);
        }
        else if (response2.StatusCode == HttpStatusCode.Conflict)
        {
            var content = await response2.Content.ReadAsStringAsync();
            Assert.Contains("Submission is being finalized by another request. Please retry.", content);
        }
    }

    [Fact]
    public void FinalizeSubmission_ConcurrencyToken_IsRegisteredOnSubmission()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        // Act
        var entityType = db.Model.FindEntityType(typeof(Submission));
        var rowVersion = entityType?.FindProperty("RowVersion");

        // Assert
        Assert.NotNull(rowVersion); // RowVersion property must exist
        Assert.True(rowVersion.IsConcurrencyToken); // Must be a concurrency token
        Assert.Equal("xmin", rowVersion.GetColumnName()); // Must map to xmin
    }

    [Fact]
    public async Task FinalizeSubmission_WhenConcurrencyError_DoesNotDuplicateActionPlans()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"concur_ap_{Guid.NewGuid()}@test.com", "Aa1234567@", "AP Auditor", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "AP Concur", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "AP Store", IsActive = true });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = 1.0m };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria); // Note: this criteria doesn't trigger action plan by default unless failed.
        
        // Make it a failure to trigger an action plan
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = "{\"Groups\":[{\"Id\":\"" + group.Id + "\",\"Title\":\"G1\",\"Criteria\":[{\"Id\":\"" + criteria.Id + "\",\"Label\":\"C1\",\"InputType\":\"pass_fail\",\"PointsWeight\":10}]}]}"
        });

        await db.SaveChangesAsync();

        var client1 = _factory.CreateAuthenticatedClient(token);
        var client2 = _factory.CreateAuthenticatedClient(token);
        
        var payload = new
        {
            ClientScore = 0m,
            SectionScores = "{\"G1\":{\"score\":0,\"maxScore\":10}}",
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 0m, Value = "non_conform" }
            }
        };

        // Act
        var task1 = client1.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);
        var task2 = client2.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        await Task.WhenAll(task1, task2);

        // Assert
        var response1 = await task1;
        var response2 = await task2;
        var response1Body = await response1.Content.ReadAsStringAsync();
        var response2Body = await response2.Content.ReadAsStringAsync();

        var results = new[] { response1.StatusCode, response2.StatusCode };
        Assert.Contains(HttpStatusCode.OK, results);
        Assert.Contains(HttpStatusCode.Conflict, results);

        // One of the bodies should contain the conflict message
        var bodies = response1Body + response2Body;
        Assert.Contains("Submission is being finalized by another request. Please retry.", bodies);
        
        using var verifyScope = _factory.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();
        
        var actionPlanCount = await verifyDb.ActionPlans.CountAsync(ap => ap.SubmissionId == submissionId);
        
        // Expected exactly 1 action plan (if one succeeded and one failed)
        // or 2 if the bug exists.
        Assert.Equal(1, actionPlanCount);
    }
}
