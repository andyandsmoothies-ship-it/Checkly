using System.Net;
using System.Net.Http.Headers;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Security;

[Collection("Sequential")]
public class MagicByteTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public MagicByteTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    private async Task<Guid> SeedSubmissionAsync(Common.Persistence.AppDbContext db, Guid auditorId, string suffix)
    {
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = $"MB {suffix}", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = $"MB {suffix}", IsActive = true });

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorId,
            Status = "draft",
            ScoringMode = "penalty",
            TemplateTitle = $"MB {suffix}",
            StoreName = $"MB {suffix}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        return submissionId;
    }

    private async Task<(HttpClient Client, Guid SubmissionId)> SetupAttackerSessionAsync(string suffix)
    {
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var attackerEmail = $"mb-attacker-{Guid.NewGuid():N}@redteam.test";
        var (token, attackerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "MB Attacker", "auditor");

        var submissionId = await SeedSubmissionAsync(db, attackerId, suffix);
        var client = _fixture.CreateAuthenticatedClient(token);

        return (client, submissionId);
    }

    private async Task<HttpResponseMessage> UploadFileAsync(HttpClient client, Guid submissionId, string fileName, string contentType, byte[] fileBytes)
    {
        using var content = new MultipartFormDataContent();
        var bytesContent = new ByteArrayContent(fileBytes);
        bytesContent.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType);
        content.Add(bytesContent, "file", fileName);

        return await client.PostAsync($"/api/photos/upload/{submissionId}", content);
    }

    // T1
    [Fact]
    public async Task UploadPhoto_WithExeRenamedAsJpg_ReturnsUnsupportedMediaType()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T1");
        var pEHeader = new byte[] { 77, 90, 144, 0, 3, 0, 0, 0, 4, 0, 0, 0, 255, 255 };

        // Act
        var response = await UploadFileAsync(client, submissionId, "bad.jpg", "image/jpeg", pEHeader);

        // Assert
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    // T2
    [Fact]
    public async Task UploadPhoto_WithPhpWebshellRenamedAsJpg_ReturnsUnsupportedMediaType()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T2");
        var phpShell = System.Text.Encoding.ASCII.GetBytes("<" + "?php system(); ?" + ">");

        // Act
        var response = await UploadFileAsync(client, submissionId, "shell.jpg", "image/jpeg", phpShell);

        // Assert
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    // T3
    [Fact]
    public async Task UploadPhoto_WithExeContentTypeSpoofedAsJpeg_ReturnsUnsupportedMediaType()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T3");
        var pEHeader = new byte[] { 77, 90, 144, 0 };

        // Act
        var response = await UploadFileAsync(client, submissionId, "bad.exe", "image/jpeg", pEHeader);

        // Assert
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    // T4
    [Fact]
    public async Task UploadPhoto_WithValidJpegMagicBytes_ReturnsCreated()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T4");
        var validJpeg = new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01 };

        // Act
        var response = await UploadFileAsync(client, submissionId, "photo.jpg", "image/jpeg", validJpeg);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    // T5
    [Fact]
    public async Task UploadPhoto_WithValidPngMagicBytes_ReturnsCreated()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T5");
        var validPng = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D };

        // Act
        var response = await UploadFileAsync(client, submissionId, "photo.png", "image/png", validPng);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    // T6
    [Fact]
    public async Task UploadPhoto_WithValidWebPMagicBytes_ReturnsCreated()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T6");
        var validWebp = new byte[] { 0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50 };

        // Act
        var response = await UploadFileAsync(client, submissionId, "photo.webp", "image/webp", validWebp);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    // T7
    [Fact]
    public async Task UploadPhoto_WithEmptyFile_ReturnsBadRequest()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T7");

        // Act
        var response = await UploadFileAsync(client, submissionId, "empty.jpg", "image/jpeg", Array.Empty<byte>());

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // T8
    [Fact]
    public async Task UploadPhoto_WithTruncatedFile_ReturnsUnsupportedMediaType()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T8");
        var truncated = new byte[] { 0xFF, 0xD8 };

        // Act
        var response = await UploadFileAsync(client, submissionId, "trunc.jpg", "image/jpeg", truncated);

        // Assert
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    // T9
    [Fact]
    public async Task UploadPhoto_WithNullBytesHeader_ReturnsUnsupportedMediaType()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T9");
        var nullBytes = new byte[12];

        // Act
        var response = await UploadFileAsync(client, submissionId, "zeros.jpg", "image/jpeg", nullBytes);

        // Assert
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, response.StatusCode);
    }

    // T10
    [Fact]
    public async Task UploadPhoto_WithPolyglotJpegPayload_ReturnsCreated()
    {
        // Arrange
        var (client, submissionId) = await SetupAttackerSessionAsync("T10");
        var polyglot = new byte[] {
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            77, 90, 144, 0, 3, 0, 0, 0
        };

        // Act
        var response = await UploadFileAsync(client, submissionId, "polyglot.jpg", "image/jpeg", polyglot);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
