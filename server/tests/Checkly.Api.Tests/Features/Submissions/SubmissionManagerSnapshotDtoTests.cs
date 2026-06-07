using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Submissions;

[Collection("Sequential")]
public class SubmissionManagerSnapshotDtoTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SubmissionManagerSnapshotDtoTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetSubmission_ReturnsSnapshottedManagerInfo_InSubmissionDetailDto()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (token, auditorId) = await _factory.RegisterUserAsync(
            client, $"sdet-auditor_{Guid.NewGuid()}@test.test", "Sdet123!@", "SDET Auditor", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(token);

        var submissionId = Guid.NewGuid();
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        var amId = Guid.NewGuid();
        var smId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var template = new Template { Id = templateId, Title = "AP Template", Version = 1, IsActive = true };
            db.Templates.Add(template);

            var store = new Store { Id = storeId, Name = "Test Store" };
            db.Stores.Add(store);

            var submission = new Submission
            {
                Id = submissionId,
                TemplateId = templateId,
                StoreId = storeId,
                AuditorId = auditorId,
                AuditorName = "SDET Auditor",
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow,
                CompletedAt = DateTimeOffset.UtcNow,
                AreaManagerId = amId,
                AreaManagerName = "Test Area Manager",
                StoreManagerId = smId,
                StoreManagerName = "Test Store Manager"
            };

            db.Submissions.Add(submission);
            await db.SaveChangesAsync();
        }

        // Act
        var response = await authClient.GetAsync($"/api/submissions/{submissionId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.True(json.TryGetProperty("areaManagerId", out var amIdProp), "The 'areaManagerId' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(amId.ToString(), amIdProp.GetString(), ignoreCase: true);

        Assert.True(json.TryGetProperty("areaManagerName", out var amNameProp), "The 'areaManagerName' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal("Test Area Manager", amNameProp.GetString());

        Assert.True(json.TryGetProperty("storeManagerId", out var smIdProp), "The 'storeManagerId' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(smId.ToString(), smIdProp.GetString(), ignoreCase: true);

        Assert.True(json.TryGetProperty("storeManagerName", out var smNameProp), "The 'storeManagerName' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal("Test Store Manager", smNameProp.GetString());
    }

    [Fact]
    public async Task ListSubmissions_ReturnsSnapshottedManagerInfo_InSubmissionDto()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (token, auditorId) = await _factory.RegisterUserAsync(
            client, $"sdet-auditor_{Guid.NewGuid()}@test.test", "Sdet123!@", "SDET Auditor", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(token);

        var submissionId = Guid.NewGuid();
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        var amId = Guid.NewGuid();
        var smId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var template = new Template { Id = templateId, Title = "AP Template", Version = 1, IsActive = true };
            db.Templates.Add(template);

            var store = new Store { Id = storeId, Name = "Test Store" };
            db.Stores.Add(store);

            var submission = new Submission
            {
                Id = submissionId,
                TemplateId = templateId,
                StoreId = storeId,
                AuditorId = auditorId,
                AuditorName = "SDET Auditor",
                Status = "completed",
                CreatedAt = DateTimeOffset.UtcNow,
                CompletedAt = DateTimeOffset.UtcNow,
                AreaManagerId = amId,
                AreaManagerName = "Test Area Manager",
                StoreManagerId = smId,
                StoreManagerName = "Test Store Manager"
            };

            db.Submissions.Add(submission);
            await db.SaveChangesAsync();
        }

        // Act
        var response = await authClient.GetAsync("/api/submissions");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var pagedResult = await response.Content.ReadFromJsonAsync<PagedResult<JsonElement>>();
        Assert.NotNull(pagedResult);

        var item = pagedResult.Items.FirstOrDefault(i => i.GetProperty("id").GetGuid() == submissionId);
        Assert.NotEqual(default, item);

        Assert.True(item.TryGetProperty("areaManagerId", out var amIdProp), "The 'areaManagerId' field is missing from SubmissionDto JSON response.");
        Assert.Equal(amId.ToString(), amIdProp.GetString(), ignoreCase: true);

        Assert.True(item.TryGetProperty("areaManagerName", out var amNameProp), "The 'areaManagerName' field is missing from SubmissionDto JSON response.");
        Assert.Equal("Test Area Manager", amNameProp.GetString());

        Assert.True(item.TryGetProperty("storeManagerId", out var smIdProp), "The 'storeManagerId' field is missing from SubmissionDto JSON response.");
        Assert.Equal(smId.ToString(), smIdProp.GetString(), ignoreCase: true);

        Assert.True(item.TryGetProperty("storeManagerName", out var smNameProp), "The 'storeManagerName' field is missing from SubmissionDto JSON response.");
        Assert.Equal("Test Store Manager", smNameProp.GetString());
    }

    [Fact]
    public async Task GetSubmission_WithNullManagerSnapshots_ReturnsNullsInSubmissionDetailDto()
    {
        // Arrange
        var client = _factory.CreateClient();
        var (token, auditorId) = await _factory.RegisterUserAsync(
            client, $"sdet-auditor_{Guid.NewGuid()}@test.test", "Sdet123!@", "SDET Auditor", "auditor");
        var authClient = _factory.CreateAuthenticatedClient(token);

        var submissionId = Guid.NewGuid();
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            var template = new Template { Id = templateId, Title = "AP Template", Version = 1, IsActive = true };
            db.Templates.Add(template);

            var store = new Store { Id = storeId, Name = "Test Store" };
            db.Stores.Add(store);

            var submission = new Submission
            {
                Id = submissionId,
                TemplateId = templateId,
                StoreId = storeId,
                AuditorId = auditorId,
                AuditorName = "SDET Auditor",
                Status = "draft",
                CreatedAt = DateTimeOffset.UtcNow,
                AreaManagerId = null,
                AreaManagerName = null,
                StoreManagerId = null,
                StoreManagerName = null
            };

            db.Submissions.Add(submission);
            await db.SaveChangesAsync();
        }

        // Act
        var response = await authClient.GetAsync($"/api/submissions/{submissionId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();

        Assert.True(json.TryGetProperty("areaManagerId", out var amIdProp), "The 'areaManagerId' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(JsonValueKind.Null, amIdProp.ValueKind);

        Assert.True(json.TryGetProperty("areaManagerName", out var amNameProp), "The 'areaManagerName' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(JsonValueKind.Null, amNameProp.ValueKind);

        Assert.True(json.TryGetProperty("storeManagerId", out var smIdProp), "The 'storeManagerId' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(JsonValueKind.Null, smIdProp.ValueKind);

        Assert.True(json.TryGetProperty("storeManagerName", out var smNameProp), "The 'storeManagerName' field is missing from SubmissionDetailDto JSON response.");
        Assert.Equal(JsonValueKind.Null, smNameProp.ValueKind);
    }
}
