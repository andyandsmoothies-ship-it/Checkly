using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class CreateSubmissionClientUuidTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public CreateSubmissionClientUuidTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateSubmission_WithClientProvidedId_CreatesSubmissionWithExactId()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "clientuuid1@test.com", "Aa1234567@", "UUID User 1", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "UUID Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "UUID Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        var clientProvidedId = Guid.NewGuid();
        var requestPayload = new
        {
            Id = clientProvidedId,
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 100m,
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", requestPayload);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            throw new Exception($"Request failed with {response.StatusCode} and body: {contentString}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var returnedId = Guid.Parse(json.GetProperty("id").GetString()!);

        Assert.Equal(clientProvidedId, returnedId);

        // Verify in DB
        var dbSubmission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == clientProvidedId);
        Assert.NotNull(dbSubmission);
        Assert.Equal(clientProvidedId, dbSubmission.Id);
    }

    [Fact]
    public async Task CreateSubmission_WithNoId_GeneratesNewId()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "clientuuid2@test.com", "Aa1234567@", "UUID User 2", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "UUID Template 2", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "UUID Store 2", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", IsActive = true };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criteria);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        var requestPayload = new
        {
            // Omitted Id entirely (Empty State)
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 100m,
            Answers = new[]
            {
                new { CriteriaId = criteria.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", requestPayload);

        // Assert
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var returnedId = Guid.Parse(json.GetProperty("id").GetString()!);

        Assert.NotEqual(Guid.Empty, returnedId);

        // Verify in DB
        var dbSubmission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == returnedId);
        Assert.NotNull(dbSubmission);
    }
}
