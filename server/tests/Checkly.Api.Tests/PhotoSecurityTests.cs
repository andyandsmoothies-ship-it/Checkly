using System.Net;
using System.Net.Http.Headers;

namespace Checkly.Api.Tests;

/// <summary>
/// TDD Security Contracts for Photos matching the Sentinel Infra Audit.
/// </summary>
public class PhotoSecurityTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public PhotoSecurityTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task GetPhoto_WithNonGuidSubmissionId_ReturnsBadRequest()
    {
        // TC-SEC-01: Path Traversal IDOR bypass via non-GUID binding
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sec1@test.com", "Sec123!@", "Sec1", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        
        // Act: Use traversal payload that breaks Guid.TryParse
        var response = await authClient.GetAsync("/api/photos/..%2f..%2fappsettings.json/some-file.jpg");

        // Assert: The route MUST enforce Guid, throwing 400 Bad Request instantly.
        // Currently, it accepts string, which drops to 404 or worse during IDOR skip.
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetPhoto_WithTraversalFileName_ReturnsBadRequest()
    {
        // TC-SEC-02: FileName traversal blocking
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sec2@test.com", "Sec123!@", "Sec2", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var subId = Guid.NewGuid();
        
        // Act: Attempt traversal in filename
        var response = await authClient.GetAsync($"/api/photos/{subId}/..%2f..%2f..%2fetc%2fpasswd");

        // Assert: System must intercept traversal sequences and HTTP 400.
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UploadPhoto_Exceeds15MB_ReturnsBadRequest()
    {
        // TC-SEC-03: DoS via unlimited upload payload
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sec3@test.com", "Sec123!@", "Sec3", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var subId = Guid.NewGuid();

        using var content = new MultipartFormDataContent();
        // Create dummy 16MB file stream
        var fileContent = new ByteArrayContent(new byte[16 * 1024 * 1024]);
        fileContent.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileContent, "file", "huge.jpg");

        // Act
        var response = await authClient.PostAsync($"/api/photos/upload/{subId}", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UploadPhoto_WithExecutableExtension_ReturnsBadRequest()
    {
        // TC-SEC-04: Extension spoofing / untrusted MIME execution
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, "sec4@test.com", "Sec123!@", "Sec4", "auditor");

        var authClient = _factory.CreateAuthenticatedClient(token);
        var subId = Guid.NewGuid();

        using var content = new MultipartFormDataContent();
        // Simulating 100kb payload but named with .exe
        var fileContent = new ByteArrayContent(new byte[1024 * 100]);
        content.Add(fileContent, "file", "malware.exe");

        // Act
        var response = await authClient.PostAsync($"/api/photos/upload/{subId}", content);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
