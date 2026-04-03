using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

/// <summary>
/// P0.4 Red Team: DTO Mass Assignment Guard Tests
/// 
/// Test Plan:
///   - T1/T2: FinalizeSubmission — server recalculates score, uses its own snapshot, ignores injected fields
///   - T3:    UpdateSubmission — hostile admin fields (ReviewStatus, TotalScore, VoidReason) are dropped
///   - T4:    CreateSubmission — server-derived answer fields (IsFailure, RepeatedFaults) ignored from client
///   - F1:    Cross-tenant IDOR — non-owner cannot finalize another user's draft
///   - F3:    Idempotency collision — second request with same key returns original unchanged
///   - F4:    Double-finalize stale state — already-completed submission returns 409 Conflict
/// </summary>
[Collection("Sequential")]
public class SubmissionMassAssignmentRedTeamTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public SubmissionMassAssignmentRedTeamTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    // ─── Shared helpers ─────────────────────────────────────────────────────

    private async Task<(Guid TemplateId, Guid StoreId, Guid GroupId, Guid CriterionId)> SeedTemplateSeedAsync(
        Common.Persistence.AppDbContext db, string suffix)
    {
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();
        db.Templates.Add(new Template
        {
            Id = templateId,
            Title = $"P0.4 Template {suffix}",
            Version = 1,
            IsActive = true
        });
        db.Stores.Add(new Store { Id = storeId, Name = $"P0.4 Store {suffix}", IsActive = true });
        var group = new Group
        {
            Id = Guid.NewGuid(),
            TemplateId = templateId,
            Title = "Section A",
            IsActive = true
        };
        db.Groups.Add(group);
        var criterion = new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = group.Id,
            Label = "Pass/Fail Criterion",
            InputType = "pass_fail",
            PointsWeight = 10,
            IsActive = true
        };
        db.Criteria.Add(criterion);
        await db.SaveChangesAsync();
        return (templateId, storeId, group.Id, criterion.Id);
    }

    private async Task<Guid> CreateDraftSubmissionAsync(
        Common.Persistence.AppDbContext db, Guid templateId, Guid storeId, Guid auditorId)
    {
        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorId,
            Status = "draft",
            ScoringMode = "penalty",
            TemplateTitle = "P0.4 Template",
            StoreName = "P0.4 Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return submissionId;
    }

    // ─── T1: Finalize Score Override ─────────────────────────────────────────

    [Fact]
    public async Task FinalizeSubmission_WithHostileFieldInjection_IgnoresPrivilegedFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"t1-{Guid.NewGuid():N}@redteam.test";
        var (token, userId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "T1 Attacker", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "T1");
        var submissionId = await CreateDraftSubmissionAsync(db, templateId, storeId, userId);
        var client = _fixture.CreateAuthenticatedClient(token);

        // Hostile payload: inject totalScore=9999, scoringMode=survey, status=approved
        // Only fields in FinalizeRequest are: ClientScore, SectionScores, Notes, GpsLat, GpsLng, Answers
        // Extra keys are silently dropped by ASP.NET Core model binding
        var hostile = new Dictionary<string, object?>
        {
            { "clientScore", 100m },
            { "sectionScores", null },
            { "notes", null },
            { "answers", new[] { new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } } },
            // --- HOSTILE ---
            { "totalScore", 9999m },
            { "scoringMode", "survey" },
            { "status", "approved" },
            { "approvedBy", Guid.NewGuid() },
        };

        // Act
        var response = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", hostile);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var saved = await db.Submissions.AsNoTracking().FirstAsync(s => s.Id == submissionId);

        // Server must set Status=completed (not "approved")
        Assert.Equal("completed", saved.Status);

        // Server must not store 9999 — it recalculates from scoring logic (penalty = 100 for pass answer)
        Assert.NotEqual(9999m, saved.TotalScore);

        // Server must set ScoringMode from template config (penalty), not from payload
        Assert.Equal("penalty", saved.ScoringMode);

        // Server-derived ApprovedBy must remain null
        Assert.Null(saved.ApprovedBy);
    }

    // ─── T2: Finalize Snapshot Poisoning ─────────────────────────────────────

    [Fact]
    public async Task FinalizeSubmission_WithSnapshotPoisoning_UsesServerSnapshot()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"t2-{Guid.NewGuid():N}@redteam.test";
        var (token, userId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "T2 Attacker", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "T2");
        var submissionId = await CreateDraftSubmissionAsync(db, templateId, storeId, userId);

        // Capture the original TemplateSnapshot from the DB before calling finalize
        var originalSubmission = await db.Submissions.AsNoTracking().FirstAsync(s => s.Id == submissionId);
        // Note: draft submissions may not have snapshot, but finalize falls back to live DB template
        var client = _fixture.CreateAuthenticatedClient(token);

        var hostile = new Dictionary<string, object?>
        {
            { "clientScore", 100m },
            { "answers", new[] { new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } } },
            // --- HOSTILE snapshot injection ---
            { "templateSnapshot", "{\"malicious\":true}" },
            { "templateVersion", 999 },
        };

        // Act
        var response = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", hostile);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var saved = await db.Submissions.AsNoTracking().FirstAsync(s => s.Id == submissionId);

        // Server MUST NOT write 999 as the template version (it's server-derived from creation)
        Assert.NotEqual(999, saved.TemplateVersion);

        // TemplateSnapshot must not contain "{\"malicious\":true}" — it was set at submission creation
        Assert.DoesNotContain("malicious", saved.TemplateSnapshot ?? string.Empty);
    }

    // ─── T3: UpdateSubmission — Admin Field Injection ────────────────────────

    [Fact]
    public async Task UpdateSubmission_WithAdminFieldInjection_DropsUnmappedFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"t3-{Guid.NewGuid():N}@redteam.test";
        var (token, userId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "T3 Attacker", "auditor");

        var (templateId, storeId, _, _) = await SeedTemplateSeedAsync(db, "T3");

        // Create a scheduled submission so scheduled→draft is a valid transition
        var submissionId = Guid.NewGuid();
        var scheduledAt = DateTimeOffset.UtcNow; // today, not overdue
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = userId,
            Status = "scheduled",
            ScoringMode = "penalty",
            TemplateTitle = "P0.4 Template T3",
            StoreName = "P0.4 Store T3",
            ScheduledAt = scheduledAt,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);

        // UpdateSubmission.Request only has: Status, AuditorName, AuditorEmail
        // Extra fields are silently dropped
        var hostile = new Dictionary<string, object?>
        {
            { "status", "draft" },
            // --- HOSTILE unmapped fields ---
            { "reviewStatus", "approved" },
            { "totalScore", 100m },
            { "voidReason", "attacker-voided" },
            { "approvedBy", Guid.NewGuid() },
        };

        // Act
        var response = await client.PutAsJsonAsync($"/api/submissions/{submissionId}", hostile);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var saved = await db.Submissions.AsNoTracking().FirstAsync(s => s.Id == submissionId);

        // Status should have transitioned legitimately
        Assert.Equal("draft", saved.Status);

        // Hostile injections must be ignored
        Assert.Null(saved.ReviewStatus);
        Assert.Null(saved.TotalScore);
        Assert.Null(saved.VoidReason);
        Assert.Null(saved.ApprovedBy);
    }

    // ─── T4: CreateSubmission — Answer IsFailure/RepeatedFaults Injection ────

    [Fact]
    public async Task CreateSubmission_WithAnswerFieldInjection_IgnoresServerDerivedFields()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"t4-{Guid.NewGuid():N}@redteam.test";
        var (token, userId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "T4 Attacker", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "T4");
        var client = _fixture.CreateAuthenticatedClient(token);

        // AnswerInput does not include IsFailure or RepeatedFaults — extra JSON keys dropped
        var hostile = new Dictionary<string, object?>
        {
            { "templateId", templateId },
            { "storeId", storeId },
            { "clientScore", 100m },
            { "answers", new[]
                {
                    new
                    {
                        criteriaId = criterionId,
                        value = "conform",
                        numericValue = (decimal?)null,
                        note = (string?)null,
                        photoUrl = (string?)null,
                        isRepeatedError = false,
                        // --- HOSTILE: server-derived fields ---
                        isFailure = true,
                        repeatedFaults = 99,
                    }
                }
            },
        };

        // Act
        var response = await client.PostAsJsonAsync("/api/submissions", hostile);

        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var savedAnswer = await db.Answers.AsNoTracking().FirstOrDefaultAsync(a => a.SubmissionId == submissionId);
        Assert.NotNull(savedAnswer);

        // IsFailure is server-derived from scoring (conform → not a failure)
        Assert.False(savedAnswer!.IsFailure);

        // RepeatedFaults is not an AnswerInput property — server always starts at 0
        // (field doesn't exist on Answer entity in this manner, but IsFailure must be false)
        // Primary assertion: server correctly derives IsFailure=false for a "conform" pass_fail answer
    }

    // ─── F1: Cross-Tenant IDOR — Non-Owner Cannot Finalize ───────────────────

    [Fact]
    public async Task FinalizeSubmission_ByNonOwner_ReturnsForbidden()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        // Register Owner (User A)
        var ownerEmail = $"f1-owner-{Guid.NewGuid():N}@redteam.test";
        var (_, ownerId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), ownerEmail, "Aa1234567@", "Owner A", "auditor");

        // Register Attacker (User B)
        var attackerEmail = $"f1-attacker-{Guid.NewGuid():N}@redteam.test";
        var (attackerToken, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), attackerEmail, "Aa1234567@", "Attacker B", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "F1");

        // Seed a draft owned by Owner A
        var submissionId = await CreateDraftSubmissionAsync(db, templateId, storeId, ownerId);

        var attackerClient = _fixture.CreateAuthenticatedClient(attackerToken);
        var payload = new
        {
            clientScore = 100m,
            answers = new[] { new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } }
        };

        // Act — Attacker B tries to finalize Owner A's draft
        var response = await attackerClient.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── F3: Idempotency Hijack ───────────────────────────────────────────────

    [Fact]
    public async Task CreateSubmission_WithDuplicateIdempotencyKey_ReturnsOriginalUnchanged()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"f3-{Guid.NewGuid():N}@redteam.test";
        var (token, _) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "F3 Attacker", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "F3");
        var client = _fixture.CreateAuthenticatedClient(token);
        var idempotencyKey = $"key-{Guid.NewGuid():N}";

        // First request — legitimate
        var firstPayload = new
        {
            templateId,
            storeId,
            clientScore = 100m,
            idempotencyKey,
            answers = new[] { new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } }
        };
        var firstResponse = await client.PostAsJsonAsync("/api/submissions", firstPayload);
        Assert.Equal(HttpStatusCode.Created, firstResponse.StatusCode);
        var firstJson = await firstResponse.Content.ReadFromJsonAsync<JsonElement>();
        var originalId = Guid.Parse(firstJson.GetProperty("id").GetString()!);
        var originalScore = firstJson.GetProperty("totalScore").GetDecimal();

        // Second request — same key, hostile payload with totalScore=0
        var hostilePayload = new Dictionary<string, object?>
        {
            { "templateId", templateId },
            { "storeId", storeId },
            { "clientScore", 0m },
            { "idempotencyKey", idempotencyKey },
            { "totalScore", 0m },
            { "answers", new[] { new { criteriaId = criterionId, value = "non_conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } } }
        };

        // Act
        var secondResponse = await client.PostAsJsonAsync("/api/submissions", hostilePayload);

        // Assert — server returns original, not a newly computed result
        Assert.True(secondResponse.IsSuccessStatusCode);
        var secondJson = await secondResponse.Content.ReadFromJsonAsync<JsonElement>();
        var returnedId = Guid.Parse(secondJson.GetProperty("id").GetString()!);

        // Same submission returned
        Assert.Equal(originalId, returnedId);

        // Score is unchanged (original server-computed score, not 0)
        var returnedScore = secondJson.GetProperty("totalScore").GetDecimal();
        Assert.Equal(originalScore, returnedScore);
    }

    // ─── F4: Double-Finalize Stale State ─────────────────────────────────────

    [Fact]
    public async Task FinalizeSubmission_OnAlreadyCompleted_ReturnsConflict()
    {
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var uniqueEmail = $"f4-{Guid.NewGuid():N}@redteam.test";
        var (token, userId) = await _fixture.RegisterUserAsync(
            _fixture.CreateClient(), uniqueEmail, "Aa1234567@", "F4 Attacker", "auditor");

        var (templateId, storeId, _, criterionId) = await SeedTemplateSeedAsync(db, "F4");
        var submissionId = await CreateDraftSubmissionAsync(db, templateId, storeId, userId);
        var client = _fixture.CreateAuthenticatedClient(token);

        var validPayload = new
        {
            clientScore = 100m,
            answers = new[] { new { criteriaId = criterionId, value = "conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } }
        };

        // First finalize — must succeed
        var firstResponse = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", validPayload);
        Assert.Equal(HttpStatusCode.OK, firstResponse.StatusCode);

        // Hostile second finalize with score override attempt
        var hostilePayload = new Dictionary<string, object?>
        {
            { "clientScore", 0m },
            { "answers", new[] { new { criteriaId = criterionId, value = "non_conform", numericValue = (decimal?)null, note = (string?)null, photoUrl = (string?)null, isRepeatedError = false } } },
            { "totalScore", 0m },
        };

        // Act
        var secondResponse = await client.PutAsJsonAsync($"/api/submissions/{submissionId}/finalize", hostilePayload);

        // Assert — cannot finalize a completed submission
        Assert.Equal(HttpStatusCode.Conflict, secondResponse.StatusCode);

        // Verify the original score is untouched
        var saved = await db.Submissions.AsNoTracking().FirstAsync(s => s.Id == submissionId);
        Assert.Equal("completed", saved.Status);
        Assert.NotEqual(0m, saved.TotalScore);
    }
}
