using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")]
public class DualLayerScoringIntegrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public DualLayerScoringIntegrationTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    private async Task<(HttpClient Client, Guid TemplateId, Guid StoreId, Guid SubmissionId, Guid CriteriaId)> SeedDataAsync(string scoringMode = "accumulation", decimal weight = 0, decimal pointsWeight = 10)
    {
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var baseClient = _fixture.CreateClient();
        var (token, userId) = await _fixture.RegisterUserAsync(baseClient, $"dual_{Guid.NewGuid():N}@test.com", "Aa1234567@", "Trans Test", "admin", await _fixture.LoginBootstrapAdminAsync(baseClient));
        var client = _fixture.CreateAuthenticatedClient(token);

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Tx Test", Version = 1, IsActive = true, ScoringLogicConfig = $"{{\"scoringMode\":\"{scoringMode}\"}}", CreatedBy = userId, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = storeId, Name = "Tx Store", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "G1", IsActive = true, Weight = weight, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        db.Groups.Add(group);
        var criteria = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = pointsWeight, IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };
        db.Criteria.Add(criteria);

        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        return (client, templateId, storeId, submissionId, criteria.Id);
    }

    // TC-S1-01
    [Fact]
    public async Task FinalizeSubmission_AccumulationMode_SetsRawScoreFields()
    {
        // Arrange
        var setup = await SeedDataAsync("accumulation", weight: 0, pointsWeight: 10);
        // numericValue=0 → binary pass → earns full 10 points (Flutter binary accumulation logic)
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };

        // Act
        var response = await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        var rawEarned = doc.RootElement.GetProperty("rawEarnedPoints").GetDecimal();
        var rawMax = doc.RootElement.GetProperty("rawMaxPoints").GetDecimal();
        var isWeighted = doc.RootElement.GetProperty("isWeighted").ValueKind;
        
        // numericValue=0 (no faults) → binary pass → earned = full pointsWeight = 10
        Assert.Equal(10m, rawEarned);
        Assert.Equal(10m, rawMax);
        Assert.Equal(JsonValueKind.Null, isWeighted);
    }

    // TC-S1-02
    [Fact]
    public async Task FinalizeSubmission_PenaltyWeightedMode_RawFieldsAreNull_IsWeightedTrue()
    {
        // Arrange
        var setup = await SeedDataAsync("penalty", weight: 100, pointsWeight: 10);
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };

        // Act
        var response = await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        var rawEarned = doc.RootElement.GetProperty("rawEarnedPoints").ValueKind;
        var rawMax = doc.RootElement.GetProperty("rawMaxPoints").ValueKind;
        var isWeighted = doc.RootElement.GetProperty("isWeighted").GetBoolean();
        
        Assert.Equal(JsonValueKind.Null, rawEarned);
        Assert.Equal(JsonValueKind.Null, rawMax);
        Assert.True(isWeighted);
    }

    // TC-S1-03
    [Fact]
    public async Task FinalizeSubmission_PenaltyUnweightedMode_IsWeightedFalse()
    {
        // Arrange
        var setup = await SeedDataAsync("penalty", weight: 0, pointsWeight: 10);
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };

        // Act
        var response = await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        var isWeighted = doc.RootElement.GetProperty("isWeighted").GetBoolean();
        Assert.False(isWeighted);
    }

    // TC-S1-04
    [Fact]
    public async Task FinalizeSubmission_SurveyMode_AllRawFieldsNull()
    {
        // Arrange
        var setup = await SeedDataAsync("survey", weight: 0, pointsWeight: 0);
        var requestPayload = new { ClientScore = 0m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "some input" } } };

        // Act
        var response = await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        Assert.Equal(JsonValueKind.Null, doc.RootElement.GetProperty("rawEarnedPoints").ValueKind);
        Assert.Equal(JsonValueKind.Null, doc.RootElement.GetProperty("rawMaxPoints").ValueKind);
        Assert.Equal(JsonValueKind.Null, doc.RootElement.GetProperty("isWeighted").ValueKind);
    }

    // TC-S1-05
    [Fact]
    public async Task SyncSubmissions_IncludesRawScoringFields()
    {
        // Arrange
        var setup = await SeedDataAsync("accumulation", weight: 0, pointsWeight: 10);
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };
        await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Act
        var response = await setup.Client.GetAsync($"/api/sync/submissions?storeId={setup.StoreId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        var item = doc.RootElement.GetProperty("items").EnumerateArray().FirstOrDefault(x => x.GetProperty("id").GetGuid() == setup.SubmissionId);
        
        Assert.Equal(10m, item.GetProperty("rawEarnedPoints").GetDecimal());
        Assert.Equal(10m, item.GetProperty("rawMaxPoints").GetDecimal());
        Assert.Equal(JsonValueKind.Null, item.GetProperty("isWeighted").ValueKind);
    }

    // TC-S1-06
    [Fact]
    public async Task GetSubmission_DetailDto_IncludesRawScoringFields()
    {
        // Arrange
        var setup = await SeedDataAsync("accumulation", weight: 0, pointsWeight: 10);
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };
        await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Act
        var response = await setup.Client.GetAsync($"/api/submissions/{setup.SubmissionId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        Assert.Equal(10m, doc.RootElement.GetProperty("rawEarnedPoints").GetDecimal());
    }

    // TC-S1-07
    [Fact]
    public async Task ListSubmissions_SubmissionDto_IncludesRawScoringFields()
    {
        // Arrange
        var setup = await SeedDataAsync("accumulation", weight: 0, pointsWeight: 10);
        var requestPayload = new { ClientScore = 100m, SectionScores = "{}", Answers = new[] { new { CriteriaId = setup.CriteriaId, NumericValue = 0m, Value = "pass" } } };
        await setup.Client.PutAsJsonAsync($"/api/submissions/{setup.SubmissionId}/finalize", requestPayload);

        // Act
        var response = await setup.Client.GetAsync($"/api/submissions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var responseContent = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(responseContent);
        
        var items = doc.RootElement.GetProperty("items").EnumerateArray();
        var item = items.FirstOrDefault(x => x.GetProperty("id").GetGuid() == setup.SubmissionId);
        
        Assert.Equal(10m, item.GetProperty("rawEarnedPoints").GetDecimal());
    }
}
