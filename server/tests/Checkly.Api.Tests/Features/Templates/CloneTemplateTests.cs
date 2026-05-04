using System.Net;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Templates;

[Collection("Sequential")]
public class CloneTemplateTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public CloneTemplateTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CloneTemplate_Returns201_WithDraftCopyWhenSourceExists()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(_factory.CreateClient());
        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"admin_clone_{Guid.NewGuid()}@test.com", "Aa1234567@", "Admin Clone Test", "admin", bootstrapToken);

        var sourceTemplateId = Guid.NewGuid();
        var parentGroupId = Guid.NewGuid();
        var childGroupId = Guid.NewGuid();

        db.Templates.Add(new Template
        {
            Id = sourceTemplateId,
            Title = "Source Template",
            Version = 2,
            IsActive = true,
            Type = "custom",
            Description = "Original description",
            ScoringLogicConfig = "{}",
            DisplayNoun = "Inspection",
            CreatedBy = userId,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.Groups.Add(new Group
        {
            Id = parentGroupId,
            TemplateId = sourceTemplateId,
            ParentId = null,
            Title = "Parent Group",
            Weight = 1.0m,
            OrderIndex = 1,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.Groups.Add(new Group
        {
            Id = childGroupId,
            TemplateId = sourceTemplateId,
            ParentId = parentGroupId,
            Title = "Child Group",
            Weight = 1.0m,
            OrderIndex = 1,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.Criteria.Add(new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = parentGroupId,
            Label = "Crit 1",
            InputType = "pass_fail",
            PointsWeight = 1.0m,
            OrderIndex = 1,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.Criteria.Add(new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = childGroupId,
            Label = "Crit 2",
            InputType = "pass_fail",
            PointsWeight = 1.0m,
            OrderIndex = 1,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        db.Criteria.Add(new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = childGroupId,
            Label = "Crit 3",
            InputType = "numeric",
            PointsWeight = 1.0m,
            OrderIndex = 2,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var client = _factory.CreateAuthenticatedClient(token);

        // Act
        var response = await client.PostAsJsonAsync($"/api/templates/{sourceTemplateId}/clone", new { });

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        var node = JsonNode.Parse(json);
        Assert.NotNull(node);

        var newTemplateIdStr = node["id"]?.GetValue<string>();
        Assert.NotNull(newTemplateIdStr);
        Assert.True(Guid.TryParse(newTemplateIdStr, out var newTemplateId));

        Assert.NotEqual(sourceTemplateId, newTemplateId);
        Assert.True(node["isActive"]?.GetValue<bool>());
        Assert.Equal(1, node["version"]?.GetValue<int>());
        Assert.Equal("Source Template (Copy)", node["title"]?.GetValue<string>());

        // Verify database state: 0 assignments for new template
        var assignmentsCount = await db.TemplateAssignments.CountAsync(x => x.TemplateId == newTemplateId);
        Assert.Equal(0, assignmentsCount);
    }

    [Fact]
    public async Task CloneTemplate_Returns404_WhenSourceTemplateNotFound()
    {
        // Arrange
        var bootstrapToken = await _factory.LoginBootstrapAdminAsync(_factory.CreateClient());
        var (token, _) = await _factory.RegisterUserAsync(_factory.CreateClient(),
            $"admin_clone404_{Guid.NewGuid()}@test.com", "Aa1234567@", "Admin Clone 404", "admin", bootstrapToken);

        var client = _factory.CreateAuthenticatedClient(token);
        var randomId = Guid.NewGuid();

        // Act
        var response = await client.PostAsJsonAsync($"/api/templates/{randomId}/clone", new { });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
