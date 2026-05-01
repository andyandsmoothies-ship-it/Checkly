using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Photos;

public class ProgramPhotoIntegrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ProgramPhotoIntegrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<(Guid storeId, Guid assignmentId, string photoLocalKey, string smToken)> SetupAssignmentAsync()
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Program Photo Store " + Guid.NewGuid() });
        var storeId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var (smToken, smUserId) = await _factory.RegisterUserAsync(client, $"sm_photo_{Guid.NewGuid()}@test.test", "Pass123!@", "SM", "store_manager");

        var assignmentId = Guid.NewGuid();
        var photoLocalKey = $"local_photo_{Guid.NewGuid()}";

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            
            var profile = await db.Profiles.FindAsync(smUserId);
            if (profile != null)
            {
                profile.StoreId = storeId;
            }

            var templateId = Guid.NewGuid();
            db.Templates.Add(new Template
            {
                Id = templateId,
                Title = "Photo Test Template",
                Type = "audit",
                Version = 1,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });

            var progId = Guid.NewGuid();
            db.Programs.Add(new ChecklyProgram 
            { 
                Id = progId, 
                TemplateId = templateId,
                Title = "Test Prog", 
                Status = "published", 
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });

            db.ProgramAssignments.Add(new ProgramAssignment 
            { 
                Id = assignmentId, 
                ProgramId = progId, 
                StoreId = storeId, 
                Status = "assigned", 
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });

            db.ProgramEvidence.Add(new ProgramEvidence 
            { 
                Id = Guid.NewGuid(), 
                AssignmentId = assignmentId, 
                Value = "evidence val", 
                PhotoLocalKey = photoLocalKey, 
                CreatedAt = DateTimeOffset.UtcNow 
            });

            await db.SaveChangesAsync();
        }

        return (storeId, assignmentId, photoLocalKey, smToken);
    }

    [Fact]
    public async Task UploadProgramPhoto_ValidatesMagicBytes_RejectsExecutable()
    {
        // ARRANGE
        var (_, _, photoLocalKey, smToken) = await SetupAssignmentAsync();
        var client = _factory.CreateAuthenticatedClient(smToken);

        var content = new MultipartFormDataContent();
        // MZ header indicating Windows Executable, despite image/jpeg content type
        var fileContent = new ByteArrayContent([0x4D, 0x5A, 0x90, 0x00]);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "evil.jpg");

        // ACT
        var response = await client.PostAsync($"/api/photos/programs/evidence/{photoLocalKey}", content);

        // ASSERT
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    [Fact]
    public async Task UploadProgramPhoto_PatchesEvidence_WithCdnUrl()
    {
        // ARRANGE
        var (_, _, photoLocalKey, smToken) = await SetupAssignmentAsync();
        var client = _factory.CreateAuthenticatedClient(smToken);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([0xFF, 0xD8, 0xFF]); // valid JPEG magic bytes
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "photo.jpg");

        // ACT
        var response = await client.PostAsync($"/api/photos/programs/evidence/{photoLocalKey}", content);

        // ASSERT
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var url = json.GetProperty("url").GetString();
        Assert.NotNull(url);
        Assert.Contains(photoLocalKey, url);
    }

    [Fact]
    public async Task GetProgramPhoto_ValidatesIDOR_RejectsCrossStore()
    {
        // ARRANGE
        var (_, assignmentId, _, _) = await SetupAssignmentAsync(); // Store A assignment
        
        // Setup another user in a different store
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);
        var storeResponse = await adminClient.PostAsJsonAsync("/api/stores", new { Name = "Other Store" });
        var storeBId = (await storeResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();
        var (evilSmToken, evilSmId) = await _factory.RegisterUserAsync(client, $"evil_sm_{Guid.NewGuid()}@test.test", "Pass123!@", "Evil SM", "store_manager");

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(evilSmId);
            if (profile != null)
            {
                profile.StoreId = storeBId;
                await db.SaveChangesAsync();
            }
        }

        var evilClient = _factory.CreateAuthenticatedClient(evilSmToken);

        // ACT
        var response = await evilClient.GetAsync($"/api/photos/programs/evidence/{assignmentId}/photo.jpg");

        // ASSERT
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task UploadProgramPhoto_EmptyFile_ReturnsBadRequest()
    {
        // ARRANGE
        var (_, _, photoLocalKey, smToken) = await SetupAssignmentAsync();
        var client = _factory.CreateAuthenticatedClient(smToken);

        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent([]); // Empty byte array
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "empty.jpg");

        // ACT
        var response = await client.PostAsync($"/api/photos/programs/evidence/{photoLocalKey}", content);

        // ASSERT
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
