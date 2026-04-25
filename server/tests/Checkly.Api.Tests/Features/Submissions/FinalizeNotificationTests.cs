using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class FinalizeNotificationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public FinalizeNotificationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task FinalizeSubmission_Completed_InsertAuditSubmittedNotificationForStoreManager()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        // 1. Create the store manager
        var smReg = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"sm_{Guid.NewGuid()}@test.com", "Aa1234567@", "Store Manager", "store_manager");

        // 2. Create the auditor
        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        db.Templates.Add(new Template { Id = templateId, Title = "Notification Test", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Notification Store", IsActive = true });
        
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
        
        // Update the profile to link to the store (bypassing API limitations)
        var smProfile = await db.Profiles.FindAsync(smReg.UserId);
        Assert.NotNull(smProfile);
        smProfile.StoreId = storeId;
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
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Ensure Notification was inserted for the store manager
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.UserId == smReg.UserId);
        Assert.NotNull(notification);
        Assert.Equal("audit_submitted", notification.Type);
        Assert.Contains($"/submissions/{submissionId}", notification.ActionUrl ?? "");
    }

    [Fact]
    public async Task FinalizeSubmission_NullStoreManagerId_DoesNotInsertNotification()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid(); // Note: No store manager linked to this store
        var submissionId = Guid.NewGuid();

        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        db.Templates.Add(new Template { Id = templateId, Title = "Notification Test 2", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Orphan Store", IsActive = true });
        
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
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        // Ensure NO notification was inserted of type 'audit_submitted'
        var count = await db.Notifications.CountAsync(n => n.Type == "audit_submitted");
        Assert.Equal(0, count);
    }

    [Fact]
    public async Task FinalizeSubmission_ConcurrencyConflict_DoesNotInsertNotification()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        // 1. Create the store manager
        var smReg = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"sm_{Guid.NewGuid()}@test.com", "Aa1234567@", "Store Manager", "store_manager");

        // 2. Create the auditor
        var auditorReg = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Assigned Auditor", "auditor");

        db.Templates.Add(new Template { Id = templateId, Title = "Notification Test Conflict", Version = 1, IsActive = true, ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}" });
        db.Stores.Add(new Store { Id = storeId, Name = "Conflict Store", IsActive = true });
        
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
        
        var smProfile = await db.Profiles.FindAsync(smReg.UserId);
        Assert.NotNull(smProfile);
        smProfile.StoreId = storeId;
        await db.SaveChangesAsync();

        var conflictFactory = _factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                var descriptor = services.SingleOrDefault(d => d.ServiceType == typeof(DbContextOptions<Checkly.Api.Common.Persistence.AppDbContext>));
                if (descriptor != null) services.Remove(descriptor);

                services.AddDbContext<Checkly.Api.Common.Persistence.AppDbContext>(options =>
                {
                    options.UseNpgsql("Host=localhost;Database=checkly_test;Username=postgres;Password=Aa1234567@");
                    options.AddInterceptors(new ConcurrencyThrowingInterceptor());
                });
            });
        });

        var client = conflictFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", auditorReg.Token);
        
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

        // Ensure NO notification was inserted despite the method returning Conflict
        var count = await db.Notifications.CountAsync(n => n.Type == "audit_submitted" && n.UserId == smReg.UserId);
        Assert.Equal(0, count);
    }

    private class ConcurrencyThrowingInterceptor : Microsoft.EntityFrameworkCore.Diagnostics.SaveChangesInterceptor
    {
        public override ValueTask<Microsoft.EntityFrameworkCore.Diagnostics.InterceptionResult<int>> SavingChangesAsync(
            Microsoft.EntityFrameworkCore.Diagnostics.DbContextEventData eventData, 
            Microsoft.EntityFrameworkCore.Diagnostics.InterceptionResult<int> result, 
            CancellationToken cancellationToken = default)
        {
            if (eventData.Context is Checkly.Api.Common.Persistence.AppDbContext dbContext)
            {
                var isFinalizing = dbContext.ChangeTracker.Entries<Submission>()
                    .Any(e => e.State == EntityState.Modified);
                
                if (isFinalizing)
                {
                    throw new DbUpdateConcurrencyException("Simulated concurrency conflict");
                }
            }
            return base.SavingChangesAsync(eventData, result, cancellationToken);
        }
    }
}
