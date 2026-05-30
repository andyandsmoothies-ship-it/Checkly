using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")]
public class ScoringDesignSlice2Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public ScoringDesignSlice2Tests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task TC_SL2_01_Pipeline_SubmitDownWeighted_CalculatesWeightedPenalty()
    {
        // 1. Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), "weighted-down@test.com", "Aa1234567@", "Weighted Down Test", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template 
        { 
            Id = templateId, 
            Title = "Weighted Down Template", 
            Version = 1, 
            IsActive = true,
            ScoringLogicConfig = "{\"scoreDirection\":\"down\",\"isWeighted\":true}"
        });
        db.Stores.Add(new Store { Id = storeId, Name = "Weighted Down Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", Weight = 10, IsActive = true };
        db.Groups.Add(group);
        
        var criteria1 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        var criteria2 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C2", InputType = "pass_fail", PointsWeight = 5, IsActive = true };
        
        db.Criteria.Add(criteria1);
        db.Criteria.Add(criteria2);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // Submit with C1 failed (1 fault) and C2 passed (0 faults)
        // ClientScore expected: 33.33m
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 33.33m,
            Answers = new[]
            {
                new { CriteriaId = criteria1.Id, NumericValue = 1m, Value = "non_conform" },
                new { CriteriaId = criteria2.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // 2. Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Request failed with status: {response.StatusCode}. Body: {contentString}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal("down", submission.ScoreDirection);
        Assert.True(submission.IsWeighted);
        Assert.Equal(33.33m, submission.TotalScore);
    }

    [Fact]
    public async Task TC_SL2_02_Pipeline_SubmitDownUnweighted_CalculatesUnweightedChecklist()
    {
        // 1. Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), "unweighted-down@test.com", "Aa1234567@", "Unweighted Down Test", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template 
        { 
            Id = templateId, 
            Title = "Unweighted Down Template", 
            Version = 1, 
            IsActive = true,
            ScoringLogicConfig = "{\"scoreDirection\":\"down\",\"isWeighted\":false}"
        });
        db.Stores.Add(new Store { Id = storeId, Name = "Unweighted Down Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", Weight = 10, IsActive = true };
        db.Groups.Add(group);
        
        var criteria1 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        var criteria2 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C2", InputType = "pass_fail", PointsWeight = 5, IsActive = true };
        
        db.Criteria.Add(criteria1);
        db.Criteria.Add(criteria2);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // Submit with C1 failed (1 fault -> 10 deduction) and C2 passed (0 faults -> 0 deduction)
        // ClientScore expected: 90m
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 90m,
            Answers = new[]
            {
                new { CriteriaId = criteria1.Id, NumericValue = 1m, Value = "non_conform" },
                new { CriteriaId = criteria2.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // 2. Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Request failed with status: {response.StatusCode}. Body: {contentString}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal("down", submission.ScoreDirection);
        Assert.False(submission.IsWeighted);
        Assert.Equal(90m, submission.TotalScore);
    }

    [Fact]
    public async Task TC_SL2_03_Pipeline_SubmitUp_CalculatesAccumulation()
    {
        // 1. Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), "accumulation@test.com", "Aa1234567@", "Accumulation Test", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template 
        { 
            Id = templateId, 
            Title = "Accumulation Template", 
            Version = 1, 
            IsActive = true,
            ScoringLogicConfig = "{\"scoreDirection\":\"up\",\"isWeighted\":false}"
        });
        db.Stores.Add(new Store { Id = storeId, Name = "Accumulation Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", Weight = 10, IsActive = true };
        db.Groups.Add(group);
        
        var criteria1 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        var criteria2 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C2", InputType = "pass_fail", PointsWeight = 5, IsActive = true };
        
        db.Criteria.Add(criteria1);
        db.Criteria.Add(criteria2);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // Submit with C1 failed (1 fault -> 0 earned) and C2 passed (0 faults -> 5 earned)
        // ClientScore expected: 33.33m
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = 33.33m,
            Answers = new[]
            {
                new { CriteriaId = criteria1.Id, NumericValue = 1m, Value = "non_conform" },
                new { CriteriaId = criteria2.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // 2. Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Request failed with status: {response.StatusCode}. Body: {contentString}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal("up", submission.ScoreDirection);
        Assert.False(submission.IsWeighted);
        Assert.Equal(33.33m, submission.TotalScore);
    }

    [Fact]
    public async Task TC_SL2_04_Pipeline_SubmitNone_CalculatesSurveyNullScore()
    {
        // 1. Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), "survey@test.com", "Aa1234567@", "Survey Test", "auditor");

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template 
        { 
            Id = templateId, 
            Title = "Survey Template", 
            Version = 1, 
            IsActive = true,
            ScoringLogicConfig = "{\"scoreDirection\":\"none\",\"isWeighted\":false}"
        });
        db.Stores.Add(new Store { Id = storeId, Name = "Survey Store", IsActive = true });

        var group = new Group { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Section 1", Weight = 10, IsActive = true };
        db.Groups.Add(group);
        
        var criteria1 = new Criterion { Id = Guid.NewGuid(), GroupId = group.Id, Label = "C1", InputType = "pass_fail", PointsWeight = 10, IsActive = true };
        
        db.Criteria.Add(criteria1);

        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // ClientScore expected: null for surveys
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "completed",
            ClientScore = (decimal?)null,
            Answers = new[]
            {
                new { CriteriaId = criteria1.Id, NumericValue = 0m, Value = "conform" }
            }
        };

        // 2. Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            var contentString = await response.Content.ReadAsStringAsync();
            Assert.Fail($"Request failed with status: {response.StatusCode}. Body: {contentString}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal("none", submission.ScoreDirection);
        Assert.False(submission.IsWeighted);
        Assert.Null(submission.TotalScore);
    }
}
