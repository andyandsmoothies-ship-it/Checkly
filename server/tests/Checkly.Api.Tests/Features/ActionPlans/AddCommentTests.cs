using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.ActionPlans;

[Collection("Sequential")]
public class AddCommentTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AddCommentTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task AddComment_ValidRequest_Returns201AndNotificationInserted()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, storeManagerId) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"sm_{Guid.NewGuid()}@test.com", "Aa1234567@", "SM User", "store_manager");

        var (_, auditorId) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"auditor_{Guid.NewGuid()}@test.com", "Aa1234567@", "Auditor User", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Test Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Test Store", IsActive = true });
        
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
            TemplateSnapshot = "{}"
        });

        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId,
            StoreManagerId = storeManagerId,
            SubmissionId = submissionId,
            Status = "open",
            CriteriaLabel = "Fix the lights",
            GroupTitle = "Exterior",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var client = _factory.CreateAuthenticatedClient(token);
        
        var payload = new { body = "This is a comment" };

        // Act
        var response = await client.PostAsJsonAsync($"/api/action-plans/{planId}/comments", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Ensure comment returned in payload
        var json = await response.Content.ReadAsStringAsync();
        var node = JsonNode.Parse(json);
        Assert.NotNull(node);
        Assert.Equal("This is a comment", node["body"]?.GetValue<string>());
        Assert.NotNull(node["id"]);
        Assert.Equal(storeManagerId.ToString(), node["userId"]?.GetValue<string>());

        // Ensure Notification was inserted for the auditor
        var notification = await db.Notifications.FirstOrDefaultAsync(n => n.UserId == auditorId);
        Assert.NotNull(notification);
        Assert.Equal("action_plan_comment_added", notification.Type);
        Assert.Contains("This is a comment", notification.Message);
    }

    [Fact]
    public async Task AddComment_ActionPlanNotFound_Returns404()
    {
        // Arrange
        var (token, _) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"sm_{Guid.NewGuid()}@test.com", "Aa1234567@", "SM User", "store_manager");

        var client = _factory.CreateAuthenticatedClient(token);
        var payload = new { body = "Comment on nothing" };

        // Act
        var response = await client.PostAsJsonAsync($"/api/action-plans/{Guid.NewGuid()}/comments", payload);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task AddComment_NoLinkedSubmission_SkipsNotification()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var (token, storeManagerId) = await _factory.RegisterUserAsync(_factory.CreateClient(), 
            $"sm_{Guid.NewGuid()}@test.com", "Aa1234567@", "SM User", "store_manager");
        
        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        db.Stores.Add(new Store { Id = storeId, Name = "Test Store", IsActive = true });
        
        db.ActionPlans.Add(new ActionPlan
        {
            Id = planId,
            StoreId = storeId,
            StoreManagerId = storeManagerId,
            SubmissionId = null, // No submission link
            Status = "open",
            CriteriaLabel = "Fix the lights",
            GroupTitle = "Exterior",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var client = _factory.CreateAuthenticatedClient(token);
        
        var payload = new { body = "This is a comment" };

        // Act
        var response = await client.PostAsJsonAsync($"/api/action-plans/{planId}/comments", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Ensure NO Notification was inserted for any auditor, since we don't know the auditor
        var notificationsCount = await db.Notifications.CountAsync(n => n.Type == "action_plan_comment_added");
        Assert.Equal(0, notificationsCount);
    }
}
