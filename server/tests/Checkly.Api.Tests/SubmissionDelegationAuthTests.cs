using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD specs for Tactical Gate IDOR Fix (Submission Delegation Authorization).
/// Source: implementation_plan_tactical_gate_idor.md.resolved
///
/// Test Plan:
///   AC-01: Admin can delegate   → 201 Created
///   AC-02: AreaManager can delegate → 201 Created (gap AC — wrong role string bug)
///   AC-03: Auditor cannot delegate → 403 Forbidden (negative gate — currently missing)
///   AC-04: Self-assignment bypasses gate → 201 Created (boundary edge case)
/// </summary>
[Collection("Sequential")]
public class SubmissionDelegationAuthTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public SubmissionDelegationAuthTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    // ─── Shared Arrange Helpers ───────────────────────────────────────────────

    private async Task<(Guid templateId, Guid storeId)> SeedTemplateAndStoreAsync()
    {
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template
        {
            Id = templateId,
            Title = $"DelegationTest_{Guid.NewGuid():N}",
            Version = 1,
            IsActive = true
        });
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = $"DelegationStore_{Guid.NewGuid():N}",
            IsActive = true
        });
        await db.SaveChangesAsync();
        return (templateId, storeId);
    }

    // ─── AC-01: Admin_CanDelegateToOtherUser ─────────────────────────────────

    [Fact]
    public async Task Admin_CanDelegateToOtherUser_Returns201()
    {
        // Arrange
        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (targetToken, targetId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"target_ac01_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Target Auditor AC01", "auditor", adminToken);

        var (templateId, storeId) = await SeedTemplateAndStoreAsync();
        var client = _fixture.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = targetId,
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal(targetId, submission.AuditorId);
    }

    // ─── AC-02: AreaManager_CanDelegateToOtherUser ───────────────────────────
    // GAP AC: current hotfix uses "manager" (dead role) — area_manager is incorrectly blocked.

    [Fact]
    public async Task AreaManager_CanDelegateToOtherUser_Returns201()
    {
        // Arrange
        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (areaManagerToken, areaManagerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"area_mgr_ac02_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Area Manager AC02", "area_manager", adminToken);
        var (_, targetId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"target_ac02_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Target Auditor AC02", "auditor", adminToken);

        var (templateId, storeId) = await SeedTemplateAndStoreAsync();

        // Assign the area manager to the store's area
        using (var localScope = _fixture.Services.CreateScope())
        {
            var localDb = localScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();







            localDb.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = areaManagerId, StoreId = storeId });
            await localDb.SaveChangesAsync();
        }

        var client = _fixture.CreateAuthenticatedClient(areaManagerToken);

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = targetId,
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });

        // Assert — RED: current gate uses "manager" so area_manager gets 403. Must be 201 after fix.
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal(targetId, submission.AuditorId);
    }

    // ─── GAP: AreaManager_CannotDelegate_OutsideArea ──────────────────────────
    // This is the core IDOR test. Currently RED (returns 201 instead of 403).

    [Fact]
    public async Task AreaManager_CannotDelegate_OutsideArea_Returns403()
    {
        // Arrange
        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (areaManagerToken, areaManagerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"area_mgr_gap_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Area Manager GAP", "area_manager", adminToken);
        var (_, targetId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"target_gap_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Target Auditor GAP", "auditor", adminToken);

        var (templateId, storeId) = await SeedTemplateAndStoreAsync();

        // Assign the area manager to a DIFFERENT area than the store
        using (var localScope = _fixture.Services.CreateScope())
        {
            var localDb = localScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

            var differentStoreId = Guid.NewGuid();
            localDb.Stores.Add(new Store { Id = differentStoreId, Name = "Different Store", IsActive = true });
            localDb.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = areaManagerId, StoreId = differentStoreId });
            await localDb.SaveChangesAsync();
        }

        var client = _fixture.CreateAuthenticatedClient(areaManagerToken);

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = targetId,
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });

        // Assert — RED: Currently vulnerable to IDOR, so it returns 201.
        // If it returns 201, the assert will fail, proving the vulnerability exists.
        if (response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── AC-03: Auditor_CannotDelegateToOtherUser ────────────────────────────
    // NEGATIVE GATE: entirely absent from prior test suite.

    [Fact]
    public async Task Auditor_CannotDelegateToOtherUser_Returns403()
    {
        // Arrange
        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (auditorToken, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"auditor_ac03_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Auditor AC03", "auditor", adminToken);
        var (_, victimId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"victim_ac03_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Victim AC03", "auditor", adminToken);

        var (templateId, storeId) = await SeedTemplateAndStoreAsync();
        var client = _fixture.CreateAuthenticatedClient(auditorToken);

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = victimId,
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });

        // Assert — must be 403 Forbidden, no submission created
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── AC-04: SelfAssignment_BypassesGate ──────────────────────────────────
    // GAP AC: auditor assigns to themselves — gate must be silently skipped.

    [Fact]
    public async Task Auditor_SelfAssignment_BypassesGate_Returns201()
    {
        // Arrange
        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (auditorToken, auditorId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(),
            $"self_ac04_{Guid.NewGuid():N}@test.com",
            "Aa1234567@", "Self Auditor AC04", "auditor", adminToken);

        var (templateId, storeId) = await SeedTemplateAndStoreAsync();
        var client = _fixture.CreateAuthenticatedClient(auditorToken);

        // Act — pass their own ID as AssignToAuditorId
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = auditorId,  // self
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        });

        // Assert — gate bypassed, 201 Created
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        var submission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(submission);
        Assert.Equal(auditorId, submission.AuditorId);
    }
}
