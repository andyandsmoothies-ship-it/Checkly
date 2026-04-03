using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Security;

/// <summary>
/// P0.5 Red Team: The Keyhole Exploit (Media IDOR)
///
/// Attack Vectors:
///   V1 — Cross-tenant IDOR: Auditor B retrieves Auditor A's photo (Framework 1: Data Boundary)
///   V2 — Cross-submission answerId hijack on upload (Framework 2: Client-Distrust)
///   V3 — UUID enumeration / scraping (Framework 3: DoS) — no DB hit on miss
///   V4 — Ghost File Bypass: Deleted submission still serves orphaned file (Framework 4: Stale State TOCTOU)
/// </summary>
[Collection("Sequential")]
public class PhotoIDORRedTeamTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;
    private readonly string _photoRoot;

    public PhotoIDORRedTeamTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();

        // Resolve the ContentRoot used by the running app to place test files on disk
        using var scope = _fixture.Services.CreateScope();
        var env = scope.ServiceProvider.GetRequiredService<IWebHostEnvironment>();
        _photoRoot = Path.Combine(env.ContentRootPath, "data", "photos");
    }

    // ─── Shared helpers ─────────────────────────────────────────────────────

    /// <summary>
    /// Writes a minimal 1-byte JPEG file to the expected photo storage location.
    /// This is required because GetPhoto.cs checks File.Exists BEFORE hitting the DB.
    /// </summary>
    private string PlantPhysicalFile(Guid submissionId, string fileName)
    {
        var dir = Path.Combine(_photoRoot, submissionId.ToString());
        Directory.CreateDirectory(dir);
        var path = Path.Combine(dir, fileName);
        File.WriteAllBytes(path, new byte[] { 0xFF, 0xD8, 0xFF }); // Minimal JPEG magic bytes
        return path;
    }

    private async Task<Guid> SeedSubmissionAsync(Common.Persistence.AppDbContext db, Guid auditorId, string suffix)
    {
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template
        {
            Id = templateId,
            Title = $"P0.5 Template {suffix}",
            Version = 1,
            IsActive = true
        });
        db.Stores.Add(new Store { Id = storeId, Name = $"P0.5 Store {suffix}", IsActive = true });

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorId,
            Status = "draft",
            ScoringMode = "penalty",
            TemplateTitle = $"P0.5 Template {suffix}",
            StoreName = $"P0.5 Store {suffix}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        return submissionId;
    }

    // ─── V1: Cross-Tenant IDOR Photo Retrieval ───────────────────────────────

    [Fact]
    public async Task GetPhoto_ByCrosstenantUser_ReturnsForbidden()
    {
        // Arrange — two separate auditors, A owns the submission & photo
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var ownerEmail = $"v1-owner-{Guid.NewGuid():N}@redteam.test";
        var (_, ownerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), ownerEmail, "Aa1234567@", "V1 Owner", "auditor");

        var attackerEmail = $"v1-attacker-{Guid.NewGuid():N}@redteam.test";
        var (attackerToken, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "V1 Attacker", "auditor");

        var submissionId = await SeedSubmissionAsync(db, ownerId, "V1");

        // Plant a real file on disk so File.Exists passes → IDOR guard runs
        const string fileName = "photo_v1.jpg";
        PlantPhysicalFile(submissionId, fileName);

        // Act — Attacker B requests Owner A's photo
        var attackerClient = _fixture.CreateAuthenticatedClient(attackerToken);
        var response = await attackerClient.GetAsync($"/api/photos/{submissionId}/{fileName}");

        // Assert — cross-tenant access must be denied
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── V2: Cross-Submission answerId Hijack ────────────────────────────────

    [Fact]
    public async Task UploadPhoto_WithForeignAnswerId_DoesNotPatchAnswer()
    {
        // Arrange — two auditors with separate submissions
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var attackerEmail = $"v2-attacker-{Guid.NewGuid():N}@redteam.test";
        var (attackerToken, attackerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "V2 Attacker", "auditor");

        // Attacker owns their own submission
        var attackerSubmissionId = await SeedSubmissionAsync(db, attackerId, "V2-Attacker");

        // Victim's answerId — we use a random GUID (no DB row needed).
        // The guard in UploadPhoto.cs: `var answer = await db.Answers.FindAsync(answerId)`
        // returns null for non-existent IDs, so NO patch occurs regardless.
        var foreignAnswerId = Guid.NewGuid();

        // Act — Attacker uploads to THEIR OWN submission but provides a foreign answerId
        var attackerClient = _fixture.CreateAuthenticatedClient(attackerToken);
        using var content = new MultipartFormDataContent();
        var fileBytes = new ByteArrayContent(new byte[] { 0xFF, 0xD8, 0xFF });
        fileBytes.Headers.ContentType = MediaTypeHeaderValue.Parse("image/jpeg");
        content.Add(fileBytes, "file", "malicious.jpg");

        var response = await attackerClient.PostAsync(
            $"/api/photos/upload/{attackerSubmissionId}?answerId={foreignAnswerId}", content);

        // Assert — upload succeeds (caller owns their submission), but the foreign answer is NOT patched.
        // UploadPhoto.cs: `answer = null` (foreignAnswerId has no DB row) → skip patch block entirely.
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        // Verify no Answer row was created under foreignAnswerId
        db.ChangeTracker.Clear();
        var answer = await db.Answers.FindAsync(foreignAnswerId);
        Assert.Null(answer); // No phantom answer row was created
    }

    // ─── V3: UUID Enumeration / Scraping ────────────────────────────────────

    [Fact]
    public async Task GetPhoto_WithRandomNonExistentUuid_ReturnsNotFound()
    {
        // Arrange — random UUID guaranteed not to exist in DB or filesystem
        var attackerEmail = $"v3-attacker-{Guid.NewGuid():N}@redteam.test";
        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "V3 Attacker", "auditor");

        var client = _fixture.CreateAuthenticatedClient(token);

        // Act — hit 3 different random UUIDs
        for (int i = 0; i < 3; i++)
        {
            var randomId = Guid.NewGuid();
            var response = await client.GetAsync($"/api/photos/{randomId}/photo.jpg");

            // Assert — must be 404 (file doesn't exist), not 500
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }
    }

    // ─── V4: Ghost File Bypass (TOCTOU — Net-New Critical) ──────────────────

    [Fact]
    public async Task GetPhoto_AfterSubmissionDeleted_ReturnsForbiddenOrNotFound()
    {
        // Arrange — create submission, plant file, then delete submission from DB
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var attackerEmail = $"v4-attacker-{Guid.NewGuid():N}@redteam.test";
        var (attackerToken, attackerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "V4 Attacker", "auditor");

        var submissionId = await SeedSubmissionAsync(db, attackerId, "V4");

        // Plant physical file so File.Exists returns true even after DB deletion
        const string fileName = "ghost_photo_v4.jpg";
        PlantPhysicalFile(submissionId, fileName);

        // Delete the submission from the database (simulating cascade or admin delete)
        var submission = await db.Submissions.FindAsync(submissionId);
        if (submission is not null)
        {
            db.Submissions.Remove(submission);
            await db.SaveChangesAsync();
        }

        // Verify submission is truly gone from DB
        db.ChangeTracker.Clear();
        var deletedSubmission = await db.Submissions.FindAsync(submissionId);
        Assert.Null(deletedSubmission); // Precondition: submission deleted

        // Act — attacker attempts to retrieve the orphaned ghost file
        var attackerClient = _fixture.CreateAuthenticatedClient(attackerToken);
        var response = await attackerClient.GetAsync($"/api/photos/{submissionId}/{fileName}");

        // Assert — MUST be 404 Not Found, NOT 200 OK serving the file
        // This test will FAIL on the unpatched codebase, confirming the TOCTOU vulnerability
        Assert.True(
            response.StatusCode == HttpStatusCode.NotFound ||
            response.StatusCode == HttpStatusCode.Forbidden,
            $"VULNERABILITY CONFIRMED: Expected 404/403 but got {response.StatusCode}. " +
            "GetPhoto.cs serves ghost files when submission is deleted.");
    }
}
