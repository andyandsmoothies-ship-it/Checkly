using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

[Collection("Sequential")]
public class SmartAuditSafeguards_Slice2_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public SmartAuditSafeguards_Slice2_Tests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateSubmission_WithGeofenceTelemetry_PersistsAndReturnsFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "safeguards2_1@test.com", "Aa1234567@", "Safe Test 1", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Telemetry Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Telemetry Store", IsActive = true });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Telemetry Group", IsActive = true };
        db.Groups.Add(group);
        var criterion = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criterion);
        
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 100m,
            GpsLat = 21.028511m,
            GpsLng = 105.804817m,
            IsGeofenceBypassed = true,
            DistanceMetersOff = 80,
            SectionScores = "{\"Telemetry Group\":{\"score\":10,\"maxScore\":10}}",
            Answers = new[]
            {
                new { CriteriaId = criterion.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", requestPayload);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
        }
        
        response.EnsureSuccessStatusCode();
        var returnedDto = await response.Content.ReadFromJsonAsync<SubmissionDto>();
        Assert.NotNull(returnedDto);
        Assert.True(returnedDto.IsGeofenceBypassed);
        Assert.Equal(80, returnedDto.DistanceMetersOff);

        // Verify direct database persistence
        using var verifyScope = _fixture.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        var dbEntity = await verifyDb.Submissions.FirstOrDefaultAsync(s => s.Id == returnedDto.Id);
        Assert.NotNull(dbEntity);
        Assert.True(dbEntity.IsGeofenceBypassed);
        Assert.Equal(80, dbEntity.DistanceMetersOff);
    }

    [Fact]
    public async Task GetSubmission_WithGeofenceTelemetry_ReturnsCorrectFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "safeguards2_2@test.com", "Aa1234567@", "Safe Test 2", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        var submissionId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Get Telemetry Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Get Telemetry Store", IsActive = true });
        
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId,
            Status = "completed",
            IsGeofenceBypassed = true,
            DistanceMetersOff = 120,
            CreatedAt = DateTimeOffset.UtcNow,
            Answers = new List<Answer>()
        });
        
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // Act
        var response = await client.GetAsync($"/api/submissions/{submissionId}");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
        }

        response.EnsureSuccessStatusCode();
        var detailDto = await response.Content.ReadFromJsonAsync<SubmissionDetailDto>();
        Assert.NotNull(detailDto);
        Assert.True(detailDto.IsGeofenceBypassed);
        Assert.Equal(120, detailDto.DistanceMetersOff);
    }

    [Fact]
    public async Task CreateSubmission_OmitGeofenceTelemetry_SavesNullsSuccessfully()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, userId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "safeguards2_3@test.com", "Aa1234567@", "Safe Test 3", "auditor");
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Omit Telemetry Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Omit Telemetry Store", IsActive = true });
        
        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Omit Group", IsActive = true };
        db.Groups.Add(group);
        var criterion = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        db.Criteria.Add(criterion);
        
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 100m,
            SectionScores = "{\"Omit Group\":{\"score\":10,\"maxScore\":10}}",
            Answers = new[]
            {
                new { CriteriaId = criterion.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", requestPayload);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Status: {response.StatusCode}. Body: {errorBody}");
        }
        
        response.EnsureSuccessStatusCode();
        var returnedDto = await response.Content.ReadFromJsonAsync<SubmissionDto>();
        Assert.NotNull(returnedDto);
        Assert.Null(returnedDto.IsGeofenceBypassed);
        Assert.Null(returnedDto.DistanceMetersOff);

        // Verify direct database persistence
        using var verifyScope = _fixture.Services.CreateScope();
        var verifyDb = verifyScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        var dbEntity = await verifyDb.Submissions.FirstOrDefaultAsync(s => s.Id == returnedDto.Id);
        Assert.NotNull(dbEntity);
        Assert.Null(dbEntity.IsGeofenceBypassed);
        Assert.Null(dbEntity.DistanceMetersOff);
    }
}
