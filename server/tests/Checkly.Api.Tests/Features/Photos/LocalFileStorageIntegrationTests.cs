using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Storage;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Photos;

/// <summary>
/// TDD Integration tests for the IFileStorage abstraction (Slice 1).
/// Verifies that photo endpoints correctly use the storage layer for persistence.
/// </summary>
public class LocalFileStorageIntegrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public LocalFileStorageIntegrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public void Service_IsRegisteredInDI()
    {
        // ARRANGE
        using var scope = _factory.Services.CreateScope();

        // ACT
        var storage = scope.ServiceProvider.GetService<IFileStorage>();

        // ASSERT
        Assert.NotNull(storage);
        Assert.IsType<LocalFileStorage>(storage);
    }

    private async Task<(Guid submissionId, string token)> SetupSubmissionAsync()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Photo Test Store", Province = "Hà Nội" });
        var storeId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var templateResponse = await adminClient.PostAsJsonAsync("/api/templates", new { Title = "Photo Test Template", Type = "audit" });
        var templateId = (await templateResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var (token, userId) = await _factory.RegisterUserAsync(client, $"photographer_{Guid.NewGuid()}@test.test", "Pass123!@", "Photographer", "auditor");

        var submissionId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Submissions.Add(new Submission
            {
                Id = submissionId,
                TemplateId = templateId,
                AuditorId = userId,
                StoreId = storeId,
                Status = "draft",
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        return (submissionId, token);
    }

    [Fact]
    public async Task UploadPhoto_ValidJpeg_Returns201AndUrl()
    {
        // ARRANGE
        var (submissionId, token) = await SetupSubmissionAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "photo.jpg");

        // ACT
        var response = await client.PostAsync($"/api/photos/upload/{submissionId}", content);

        // ASSERT
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var url = json.GetProperty("url").GetString();
        Assert.Contains(submissionId.ToString(), url);
    }

    [Fact]
    public async Task GetPhoto_ExistingPhoto_Returns200WithImageStream()
    {
        // ARRANGE
        var (submissionId, token) = await SetupSubmissionAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "downloadable.jpg");

        var uploadResponse = await client.PostAsync($"/api/photos/upload/{submissionId}", content);
        uploadResponse.EnsureSuccessStatusCode();

        var json = await uploadResponse.Content.ReadFromJsonAsync<JsonElement>();
        var url = json.GetProperty("url").GetString();

        // ACT
        var response = await client.GetAsync(url);

        // ASSERT
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("image/jpeg", response.Content.Headers.ContentType?.MediaType);

        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.Equal(3, bytes.Length);
    }

    [Fact]
    public async Task GetPhoto_NonExistentFile_Returns404()
    {
        // ARRANGE
        var (submissionId, token) = await SetupSubmissionAsync();
        var client = _factory.CreateAuthenticatedClient(token);
        var fakeFile = "ghost.jpg";

        // ACT
        var response = await client.GetAsync($"/api/photos/{submissionId}/{fakeFile}");

        // ASSERT
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UploadPhoto_PathTraversalFileName_Returns400()
    {
        // ARRANGE
        var (submissionId, token) = await SetupSubmissionAsync();
        var client = _factory.CreateAuthenticatedClient(token);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF]);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");

        content.Add(fileContent, "file", "../../evil.exe");

        // ACT
        var response = await client.PostAsync($"/api/photos/upload/{submissionId}", content);

        // ASSERT
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
