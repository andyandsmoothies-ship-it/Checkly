using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringRedesignSlice5Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ScoringRedesignSlice5Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    [Fact]
    public async Task TC_SL5_01_CategoryTagFiltersCorrectlyAndReturnsScopedAudits()
    {
        // 1. Arrange
        var adminClient = await CreateAdminClientAsync();
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create isolated store to prevent analytical pollution
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = "SL5 Tag Filter Store",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Stores.Add(store);

        // Seed submissions with different category tags and scored states
        var sub1 = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Fresh Food",
            TotalScore = 90.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var sub2 = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Safety",
            TotalScore = 80.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Submissions.AddRange(sub1, sub2);
        await db.SaveChangesAsync();

        // 2. Act - call GET /api/analytics with categoryTag=Fresh Food filter and store scope
        var response = await adminClient.GetAsync($"/api/analytics?storeId={store.Id}&categoryTag=Fresh%20Food");

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = json.GetProperty("kpis");
        
        // Should only count the submission matching "Fresh Food"
        Assert.Equal(1, kpis.GetProperty("totalAudits").GetInt32());
        Assert.Equal(90.0, kpis.GetProperty("avgScore").GetDouble());
    }

    [Fact]
    public async Task TC_SL5_02_ResponsePayloadReturnsDynamicSortedUniqueCategoryTagNames()
    {
        // 1. Arrange
        var adminClient = await CreateAdminClientAsync();
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create isolated store
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = "SL5 Dynamic Tags Store",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Stores.Add(store);

        // Seed submissions with various category tags
        var sub1 = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Zebra",
            TotalScore = 90.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var sub2 = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Apple",
            TotalScore = 85.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var sub3 = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Zebra", // Duplicate tag
            TotalScore = 95.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Submissions.AddRange(sub1, sub2, sub3);
        await db.SaveChangesAsync();

        // 2. Act - call GET /api/analytics scoped to store
        var response = await adminClient.GetAsync($"/api/analytics?storeId={store.Id}");

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("categoryTagNames", out var tagsJson), "Response must contain 'categoryTagNames'");

        var tags = JsonSerializer.Deserialize<List<string>>(tagsJson.GetRawText());
        Assert.NotNull(tags);
        
        // Must contain unique elements and be sorted alphabetically (Apple, Zebra)
        Assert.Equal(2, tags.Count);
        Assert.Equal("Apple", tags[0]);
        Assert.Equal("Zebra", tags[1]);
    }

    [Fact]
    public async Task TC_SL5_03_SurveySubmissionsExcludedFromAvgScoreUsingScoreDirection()
    {
        // 1. Arrange
        var adminClient = await CreateAdminClientAsync();
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create isolated store
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = "SL5 Survey Exclude Store",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.Stores.Add(store);

        // Seed 1 scored submission and 1 survey submission
        var scoredSub = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "down",
            CategoryTag = "Fresh Food",
            TotalScore = 90.0m,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var surveySub = new Submission
        {
            Id = Guid.NewGuid(),
            StoreId = store.Id,
            Status = "completed",
            ScoreDirection = "none", // Survey mode
            CategoryTag = "Fresh Food",
            TotalScore = null,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Submissions.AddRange(scoredSub, surveySub);
        await db.SaveChangesAsync();

        // 2. Act - call GET /api/analytics
        var response = await adminClient.GetAsync($"/api/analytics?storeId={store.Id}");

        // 3. Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var kpis = json.GetProperty("kpis");
        
        // Survey submissions must be excluded from scored count & average, but included in total surveys count
        Assert.Equal(2, kpis.GetProperty("totalAudits").GetInt32());
        Assert.Equal(1, kpis.GetProperty("scoredCount").GetInt32());
        Assert.Equal(1, kpis.GetProperty("totalSurveys").GetInt32());
        Assert.Equal(90.0, kpis.GetProperty("avgScore").GetDouble());
    }
}
