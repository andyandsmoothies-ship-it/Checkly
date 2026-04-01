using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

// Test Plan — ATDD Acceptance Tests for POST /api/submissions/{id}/void
// Coverage:
//   A1. Admin voids a completed submission → 204 + DB state verified
//   A2. Void is idempotent → second POST returns 204 without double-writing VoidedAt
//   A3. ActionPlan cascade → all open plans become status=closed, root_cause=SYSTEM_VOID
//   A4. AuditLogger writes a system_log entry with action=submission_voided
//   E1. Voiding a draft submission → 400
//   E2. Auditor calling void → 403
//   E3. Non-existent submission → 404
//   E4. Empty VoidReason payload → 400

public class VoidSubmissionEndpointTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public VoidSubmissionEndpointTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private async Task<(Guid SubmissionId, Guid StoreId)> SeedCompletedSubmissionAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = $"Test Store {storeId}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            Status = "completed",
            StoreId = storeId,
            StoreName = "Test Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        return (submissionId, storeId);
    }

    private async Task SeedOpenActionPlanAsync(Guid submissionId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        db.ActionPlans.Add(new ActionPlan
        {
            Id = Guid.NewGuid(),
            SubmissionId = submissionId,
            Status = "open",
            CriteriaLabel = "Test Criterion",
            GroupTitle = "Test Group",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
    }

    private async Task<string> GetAdminTokenAsync(HttpClient client, string suffix)
    {
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        return adminToken;
    }

    private async Task<string> GetAuditorTokenAsync(HttpClient client, string suffix)
    {
        var (token, _) = await _factory.RegisterUserAsync(
            client, $"auditor-void-{suffix}@test.test", "Aud123!@", $"Auditor{suffix}", "auditor");
        return token;
    }

    // ── Happy Path ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task VoidSubmission_AsAdmin_WithCompleted_Returns204()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "hp1");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "Quality audit failed re-inspection" });

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var submission = await db.Submissions.FindAsync(submissionId);
        Assert.NotNull(submission);
        Assert.Equal("voided", submission!.Status);
        Assert.Equal("Quality audit failed re-inspection", submission.VoidReason);
        Assert.NotNull(submission.VoidedAt);
    }

    [Fact]
    public async Task VoidSubmission_Idempotent_ReturnsOkWithoutDoubleWrite()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "idm1");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        var authClient = _factory.CreateAuthenticatedClient(adminToken);
        var payload = new { voidReason = "Test idempotency" };

        // Act — call twice
        var first = await authClient.PostAsJsonAsync($"/api/submissions/{submissionId}/void", payload);
        var second = await authClient.PostAsJsonAsync($"/api/submissions/{submissionId}/void", payload);

        // Assert — both return 204
        Assert.Equal(HttpStatusCode.NoContent, first.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, second.StatusCode);

        // VoidedAt must be frozen from first call — DB should show only ONE void timestamp
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var submission = await db.Submissions.FindAsync(submissionId);
        Assert.NotNull(submission);
        Assert.Equal("voided", submission!.Status);
        Assert.NotNull(submission.VoidedAt);
        // SystemLog count for this submission should still be exactly 1
        var logCount = await db.SystemLogs
            .CountAsync(l => l.EntityId == submissionId && l.Action == "submission_voided");
        Assert.Equal(1, logCount);
    }

    [Fact]
    public async Task VoidSubmission_CascadesActionPlansToClosed()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "cascade1");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        await SeedOpenActionPlanAsync(submissionId);
        await SeedOpenActionPlanAsync(submissionId);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "Cascade test" });

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var openPlans = await db.ActionPlans
            .Where(ap => ap.SubmissionId == submissionId && ap.Status != "closed")
            .CountAsync();
        Assert.Equal(0, openPlans);

        var closedWithSystemVoid = await db.ActionPlans
            .Where(ap => ap.SubmissionId == submissionId
                      && ap.Status == "closed"
                      && ap.RootCause == "SYSTEM_VOID")
            .CountAsync();
        Assert.Equal(2, closedWithSystemVoid);
    }

    [Fact]
    public async Task VoidSubmission_WritesSystemLog()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "log1");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "Audit log verification" });

        // Assert
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var logEntry = await db.SystemLogs
            .FirstOrDefaultAsync(l => l.EntityId == submissionId && l.Action == "submission_voided");
        Assert.NotNull(logEntry);
        Assert.Equal("audit", logEntry!.Category);
        Assert.Equal("Submission", logEntry.EntityType);
    }

    // ── Error Paths ────────────────────────────────────────────────────────────

    [Fact]
    public async Task VoidSubmission_WithDraftStatus_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "draft1");

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            Status = "draft",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "Should not void a draft" });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task VoidSubmission_AsAuditor_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();
        var auditorToken = await GetAuditorTokenAsync(client, "403a");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        var authClient = _factory.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "Auditor attempting admin op" });

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task VoidSubmission_NotFound_Returns404()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "404a");
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{Guid.NewGuid()}/void",
            new { voidReason = "Will not find this" });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task VoidSubmission_MissingVoidReason_Returns400()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await GetAdminTokenAsync(client, "val1");
        var (submissionId, _) = await SeedCompletedSubmissionAsync();
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act — send empty string
        var response = await authClient.PostAsJsonAsync(
            $"/api/submissions/{submissionId}/void",
            new { voidReason = "" });

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
