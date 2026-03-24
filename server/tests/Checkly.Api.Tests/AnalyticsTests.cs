using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests for the Enterprise Analytics & Reporting System.
///
/// Source: analysis_analytics_reporting.md (Slices S1–S4)
///
/// ── GHERKIN SCENARIOS ──
///
/// S1 (Foundation: New Tables + Write Path):
///   AC-S1.1: GIVEN finalization with SectionScores JSON → THEN relational rows created.
///   AC-S1.2: GIVEN survey-mode finalization → THEN zero section rows created.
///   AC-S1.3: GIVEN finalization → THEN store_analytics_snapshot row updated.
///
/// S2 (Refactor GetAnalytics):
///   AC-S2.1: GIVEN admin GET /api/analytics → THEN response shape unchanged.
///   AC-S2.2: GIVEN GET /api/analytics?areaId=X → THEN results scoped to that area.
///
/// S3 (Store Snapshot + AM/SM Dashboards):
///   AC-S3.1: GIVEN AM GET /api/analytics/area-leaderboard → THEN stores listed.
///   AC-S3.2: GIVEN GET /api/stores/{id}/dashboard → THEN snapshot fields present.
///   AC-S3.3: GIVEN auditor GET /api/analytics/area-leaderboard → THEN 403.
///
/// S4 (Auditor My-Stats + Top Failures):
///   AC-S4.1: GIVEN auditor GET /api/analytics/my-stats → THEN personal metrics returned.
///   AC-S4.2: GIVEN admin GET /api/analytics/top-failures → THEN failure list returned.
///   AC-S4.3: GIVEN auditor GET /api/analytics/top-failures → THEN 403.
/// </summary>
public class AnalyticsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public AnalyticsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ═══════════════════════════════════════════════════
    // HELPERS — Match real API surface (flat template + separate group/criteria calls)
    // ═══════════════════════════════════════════════════

    private async Task<HttpClient> CreateAdminClientAsync(string emailPrefix)
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<(HttpClient Client, Guid UserId)> CreateRoleClientAsync(
        string email, string role)
    {
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, $"Test123!@#{role}", $"Test {role}", role, adminToken);
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<Guid> CreateStoreAsync(HttpClient adminClient, string name, Guid? areaId = null)
    {
        var payload = areaId.HasValue
            ? (object)new { name, areaId }
            : new { name };
        var response = await adminClient.PostAsJsonAsync("/api/stores", payload);
        Assert.True(response.IsSuccessStatusCode,
            $"Setup: could not create store '{name}'. {response.StatusCode}: {await response.Content.ReadAsStringAsync()}");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> CreateAreaAsync(HttpClient adminClient, string name)
    {
        var response = await adminClient.PostAsJsonAsync("/api/areas",
            new { name, description = "Test area" });
        Assert.True(response.IsSuccessStatusCode,
            $"Setup: could not create area '{name}'. {response.StatusCode}: {await response.Content.ReadAsStringAsync()}");
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    /// <summary>
    /// Creates a template with 2 sections and 3 criteria using the real API surface.
    /// Returns (templateId, list of criteriaIds).
    /// </summary>
    private async Task<(Guid TemplateId, List<Guid> CriteriaIds)> CreateTemplateWithSectionsAsync(
        HttpClient adminClient, string scoringMode = "penalty")
    {
        var config = JsonSerializer.Serialize(new { scoringMode });

        // Step 1: Create template (flat)
        var createResp = await adminClient.PostAsJsonAsync("/api/templates", new
        {
            title = $"Analytics Test ({scoringMode})",
            type = "qc",
            scoringLogicConfig = config
        });
        Assert.True(createResp.IsSuccessStatusCode,
            $"Setup: template creation failed. {createResp.StatusCode}: {await createResp.Content.ReadAsStringAsync()}");
        var tJson = await createResp.Content.ReadFromJsonAsync<JsonElement>();
        var templateId = Guid.Parse(tJson.GetProperty("id").GetString()!);

        // Step 2: Create groups (sections)
        var groupAId = await CreateGroupAsync(adminClient, templateId, "Section A", 60.0m, 100.0m, 5.0m, 0);
        var groupBId = await CreateGroupAsync(adminClient, templateId, "Section B", 40.0m, 50.0m, 5.0m, 1);

        // Step 3: Create criteria
        var criteriaIds = new List<Guid>();
        criteriaIds.Add(await CreateCriterionAsync(adminClient, templateId, groupAId, "Criteria A1", "pass_fail", 5.0m, 0));
        criteriaIds.Add(await CreateCriterionAsync(adminClient, templateId, groupAId, "Criteria A2", "pass_fail", 5.0m, 1));
        criteriaIds.Add(await CreateCriterionAsync(adminClient, templateId, groupBId, "Criteria B1", "pass_fail", 5.0m, 0));

        return (templateId, criteriaIds);
    }

    private async Task<Guid> CreateGroupAsync(HttpClient client, Guid templateId,
        string title, decimal weight, decimal maxDeduction, decimal minusPerFault, int order)
    {
        var resp = await client.PostAsJsonAsync($"/api/templates/{templateId}/groups", new
        {
            title,
            weight,
            maxDeductionPoints = maxDeduction,
            minusPerFault,
            orderIndex = order
        });
        Assert.True(resp.IsSuccessStatusCode,
            $"Setup: group creation failed. {resp.StatusCode}: {await resp.Content.ReadAsStringAsync()}");
        var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    private async Task<Guid> CreateCriterionAsync(HttpClient client, Guid templateId, Guid groupId,
        string label, string inputType, decimal pointsWeight, int order)
    {
        var resp = await client.PostAsJsonAsync(
            $"/api/templates/{templateId}/groups/{groupId}/criteria", new
            {
                label,
                inputType,
                pointsWeight,
                orderIndex = order
            });
        Assert.True(resp.IsSuccessStatusCode,
            $"Setup: criterion creation failed. {resp.StatusCode}: {await resp.Content.ReadAsStringAsync()}");
        var json = await resp.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(json.GetProperty("id").GetString()!);
    }

    /// <summary>
    /// Creates a draft submission, then finalizes it.
    /// </summary>
    private async Task<Guid> CreateAndFinalizeAsync(
        HttpClient auditorClient, Guid templateId, Guid storeId,
        string? sectionScoresJson, decimal clientScore, List<Guid> criteriaIds,
        string answerValue = "pass")
    {
        // Create draft
        var createResp = await auditorClient.PostAsJsonAsync("/api/submissions", new
        {
            status = "draft",
            templateId,
            storeId
        });
        Assert.True(createResp.IsSuccessStatusCode,
            $"Setup: draft creation failed. {createResp.StatusCode}: {await createResp.Content.ReadAsStringAsync()}");
        var cJson = await createResp.Content.ReadFromJsonAsync<JsonElement>();
        var subId = Guid.Parse(cJson.GetProperty("id").GetString()!);

        // Build answers
        var answers = criteriaIds.Select(id => new
        {
            criteriaId = id,
            value = answerValue,
            numericValue = (decimal?)null,
        }).ToArray();

        // Finalize
        var finalResp = await auditorClient.PutAsJsonAsync(
            $"/api/submissions/{subId}/finalize", new
            {
                clientScore,
                sectionScores = sectionScoresJson,
                answers
            });
        Assert.True(finalResp.IsSuccessStatusCode,
            $"Setup: finalization failed. {finalResp.StatusCode}: {await finalResp.Content.ReadAsStringAsync()}");

        return subId;
    }

    // ═══════════════════════════════════════════════════
    // S1: Foundation — New Tables + Write Path
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC-S1.1: Scored submission finalization creates relational section-score rows.
    /// [Source: analysis §3.1 — "Replaces JSONB ParseSectionBreakdown"]
    /// Expected RED: SubmissionSectionScore entity does not exist yet.
    /// </summary>
    [Fact]
    public async Task Finalize_Scored_Submission_Creates_Section_Score_Rows()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s1a");
        var storeId = await CreateStoreAsync(adminClient, "S1-SectionRows Store");
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient);
        var (auditorClient, _) = await CreateRoleClientAsync("s1-aud1@test.test", "auditor");

        var sectionScores = JsonSerializer.Serialize(new Dictionary<string, object>
        {
            ["Section A"] = new { score = 82.0, maxScore = 100.0 },
            ["Section B"] = new { score = 40.0, maxScore = 50.0 }
        });

        // Act
        var subId = await CreateAndFinalizeAsync(
            auditorClient, templateId, storeId, sectionScores, 100.0m, criteriaIds);

        // Assert — relational rows must exist in submission_section_scores
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // This will fail (RED) because SubmissionSectionScore entity doesn't exist
        // in AppDbContext. The Builder must create it.
        var rows = await db.Set<SubmissionSectionScore>()
            .Where(s => s.SubmissionId == subId)
            .ToListAsync();

        Assert.Equal(2, rows.Count);
        Assert.Contains(rows, r => r.SectionTitle == "Section A" && r.Score == 82.0m);
        Assert.Contains(rows, r => r.SectionTitle == "Section B" && r.Score == 40.0m);
    }

    /// <summary>
    /// AC-S1.2: Survey-mode finalization creates zero section-score rows.
    /// [Source: analysis §2.3 — "Survey-mode submissions have zero rows"]
    /// Expected RED: SubmissionSectionScore entity does not exist yet.
    /// </summary>
    [Fact]
    public async Task Finalize_Survey_Submission_Creates_Zero_Section_Score_Rows()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s1b");
        var storeId = await CreateStoreAsync(adminClient, "S1-Survey Store");
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient, "survey");
        var (auditorClient, _) = await CreateRoleClientAsync("s1-surv@test.test", "auditor");

        // Act — survey finalization: no section scores
        var subId = await CreateAndFinalizeAsync(
            auditorClient, templateId, storeId, null, 0m, criteriaIds, "Good");

        // Assert — zero rows
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var rows = await db.Set<SubmissionSectionScore>()
            .Where(s => s.SubmissionId == subId)
            .ToListAsync();

        Assert.Empty(rows);
    }

    /// <summary>
    /// AC-S1.3: Finalization creates/updates a store_analytics_snapshot row.
    /// [Source: analysis §3.2 — "Pre-computed store-level KPIs"]
    /// Expected RED: StoreAnalyticsSnapshot entity does not exist yet.
    /// </summary>
    [Fact]
    public async Task Finalize_Submission_Updates_Store_Analytics_Snapshot()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s1c");
        var storeId = await CreateStoreAsync(adminClient, "S1-Snapshot Store");
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient);
        var (auditorClient, _) = await CreateRoleClientAsync("s1-snap@test.test", "auditor");

        var sectionScores = JsonSerializer.Serialize(new Dictionary<string, object>
        {
            ["Section A"] = new { score = 100.0, maxScore = 100.0 },
            ["Section B"] = new { score = 50.0, maxScore = 50.0 }
        });

        // Act
        await CreateAndFinalizeAsync(
            auditorClient, templateId, storeId, sectionScores, 100.0m, criteriaIds);

        // Assert — snapshot row must exist
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var snapshot = await db.Set<StoreAnalyticsSnapshot>()
            .FirstOrDefaultAsync(s => s.StoreId == storeId);

        Assert.NotNull(snapshot);
        Assert.True(snapshot.TotalAudits30d >= 1);
        Assert.True(snapshot.AvgScore30d > 0);
    }

    // ═══════════════════════════════════════════════════
    // S2: Refactor GetAnalytics
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC-S2.1: GET /api/analytics response shape must remain backward-compatible.
    /// [Source: analysis §4.1 — "Backward Compatible: Same response shape"]
    /// Expected: GREEN (existing endpoint, shape check only).
    /// </summary>
    [Fact]
    public async Task GetAnalytics_Response_Shape_Unchanged_After_Refactor()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s2a");

        // Act
        var response = await adminClient.GetAsync("/api/analytics");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("kpis", out var kpis), "Must have 'kpis'");
        Assert.True(kpis.TryGetProperty("totalAudits", out _));
        Assert.True(kpis.TryGetProperty("avgScore", out _));
        Assert.True(kpis.TryGetProperty("openAPs", out _));
        Assert.True(json.TryGetProperty("trend", out _), "Must have 'trend'");
        Assert.True(json.TryGetProperty("sectionBreakdown", out _), "Must have 'sectionBreakdown'");
    }

    /// <summary>
    /// AC-S2.2: GET /api/analytics?areaId=X scopes results to that area's stores.
    /// [Source: analysis §7 — "AM scoped to their profile.area_id"]
    /// </summary>
    [Fact]
    public async Task GetAnalytics_With_AreaId_Returns_Scoped_Results()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s2b");
        var areaId = await CreateAreaAsync(adminClient, "S2 Area");
        var inAreaStoreId = await CreateStoreAsync(adminClient, "S2 In-Area", areaId);
        var outAreaStoreId = await CreateStoreAsync(adminClient, "S2 Out-Area");
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient);
        var (auditorClient, _) = await CreateRoleClientAsync("s2-aud@test.test", "auditor");

        var sectionScores = JsonSerializer.Serialize(new Dictionary<string, object>
        {
            ["Section A"] = new { score = 90.0, maxScore = 100.0 },
            ["Section B"] = new { score = 45.0, maxScore = 50.0 }
        });

        // Create submission IN area
        await CreateAndFinalizeAsync(
            auditorClient, templateId, inAreaStoreId, sectionScores, 100.0m, criteriaIds);

        // Create submission OUTSIDE area
        await CreateAndFinalizeAsync(
            auditorClient, templateId, outAreaStoreId, sectionScores, 100.0m, criteriaIds);

        // Act — filter by area
        var response = await adminClient.GetAsync($"/api/analytics?areaId={areaId}");

        // Assert — only the in-area submission should be counted
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var total = json.GetProperty("kpis").GetProperty("totalAudits").GetInt32();
        Assert.Equal(1, total); // Business assertion: only 1 in-area audit
    }

    // ═══════════════════════════════════════════════════
    // S3: AM Leaderboard + Store Dashboard + RBAC
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC-S3.1: AM can access area-leaderboard for their area.
    /// [Source: analysis §4.2 — "AM-scoped store comparison"]
    /// Expected RED: Route /api/analytics/area-leaderboard does not exist.
    /// </summary>
    [Fact]
    public async Task AM_Can_Access_Area_Leaderboard()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s3a");
        var areaId = await CreateAreaAsync(adminClient, "S3 LB Area");

        // Create AM assigned to this area
        var (amClient, amUserId) = await CreateRoleClientAsync("s3-am@test.test", "area_manager");
        await adminClient.PutAsJsonAsync($"/api/admin/users/{amUserId}", new { areaId });

        // Act
        var response = await amClient.GetAsync($"/api/analytics/area-leaderboard?areaId={areaId}");

        // Assert — RED: 404 (route missing), should be 200 when implemented
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("stores", out _), "Must contain 'stores' array");
    }

    /// <summary>
    /// AC-S3.2: Store dashboard must include new snapshot fields.
    /// [Source: analysis §4.1 — "New Fields: avgScore30d, lastAuditScore, overdueActionPlans"]
    /// Expected RED: Current GetStoreDashboard does not return these fields.
    /// </summary>
    [Fact]
    public async Task Store_Dashboard_Returns_Snapshot_Fields()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s3b");
        var storeId = await CreateStoreAsync(adminClient, "S3 Dashboard Store");

        // Act
        var response = await adminClient.GetAsync($"/api/stores/{storeId}/dashboard");

        // Assert — business RED: these fields don't exist in current response
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("avgScore30d", out _),
            "Must include 'avgScore30d' from snapshot table");
        Assert.True(json.TryGetProperty("lastAuditScore", out _),
            "Must include 'lastAuditScore' from snapshot table");
        Assert.True(json.TryGetProperty("overdueActionPlans", out _),
            "Must include 'overdueActionPlans' from snapshot table");
    }

    /// <summary>
    /// AC-S3.3: Auditors cannot access the area-leaderboard (admin/AM only).
    /// [Source: analysis §7 — "admin, area_manager only"]
    /// Expected RED: Route doesn't exist (404), but when implemented should be 403.
    /// </summary>
    [Fact]
    public async Task Auditor_Cannot_Access_Area_Leaderboard()
    {
        // Arrange
        var (auditorClient, _) = await CreateRoleClientAsync("s3-aud-lb@test.test", "auditor");

        // Act
        var response = await auditorClient.GetAsync(
            "/api/analytics/area-leaderboard?areaId=" + Guid.NewGuid());

        // Assert — must be 403 (not 200, not 404)
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ═══════════════════════════════════════════════════
    // S4: Auditor My-Stats + Top Failures
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// AC-S4.1: Auditor can GET their personal stats.
    /// [Source: analysis §4.2 — "Auditor-scoped personal metrics"]
    /// Expected RED: Route /api/analytics/my-stats does not exist.
    /// </summary>
    [Fact]
    public async Task Auditor_Can_Get_My_Stats()
    {
        // Arrange
        var (auditorClient, _) = await CreateRoleClientAsync("s4-ms@test.test", "auditor");

        // Act
        var response = await auditorClient.GetAsync("/api/analytics/my-stats");

        // Assert — RED: 404 (route missing), should be 200 when implemented
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.TryGetProperty("auditsThisMonth", out _));
        Assert.True(json.TryGetProperty("avgScoreGiven", out _));
        Assert.True(json.TryGetProperty("companyAvgScore", out _));
    }

    /// <summary>
    /// AC-S4.2: Admin can GET top-failures for a template.
    /// [Source: analysis §4.2 — "Most frequently failed criteria"]
    /// Expected RED: Route /api/analytics/top-failures does not exist.
    /// </summary>
    [Fact]
    public async Task Admin_Can_Get_Top_Failures()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("s4a");
        var (templateId, _) = await CreateTemplateWithSectionsAsync(adminClient);

        // Act
        var response = await adminClient.GetAsync(
            $"/api/analytics/top-failures?templateId={templateId}");

        // Assert — RED: 404 (route missing), should be 200 with array
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var items = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Array, items.ValueKind);
    }

    /// <summary>
    /// AC-S4.3: Auditor cannot access top-failures (admin-only).
    /// [Source: analysis §7 — "admin only"]
    /// Expected RED: Route doesn't exist (404), but when implemented should be 403.
    /// </summary>
    [Fact]
    public async Task Auditor_Cannot_Access_Top_Failures()
    {
        // Arrange
        var (auditorClient, _) = await CreateRoleClientAsync("s4-aud-tf@test.test", "auditor");

        // Act
        var response = await auditorClient.GetAsync(
            "/api/analytics/top-failures?templateId=" + Guid.NewGuid());

        // Assert — must be 403 (not 200, not 404)
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ═══════════════════════════════════════════════════
    // ATDD Slice A: Semantic Failure Stamping (SC-A5 to SC-A8)
    // ═══════════════════════════════════════════════════

    /// <summary>
    /// SC-A5: IsFailure correctly stamped per-answer at finalize.
    /// Expected RED: Answer entity doesn't have IsFailure property yet.
    /// </summary>
    [Fact]
    public async Task Finalize_Stamps_IsFailure_Correctly_In_Db()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("a5");
        var storeId = await CreateStoreAsync(adminClient, "SC-A5 Store");
        
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient);
        // We know from setup: criteriaIds[0], [1], [2] exist.
        
        var (auditorClient, _) = await CreateRoleClientAsync("s5-aud@test.test", "auditor");

        var sectionScores = JsonSerializer.Serialize(new Dictionary<string, object>
        {
            ["Section A"] = new { score = 50.0, maxScore = 100.0 }, // Failed half
            ["Section B"] = new { score = 50.0, maxScore = 50.0 }   // Perfect
        });

        // Act - Submit with C1=fail, C2=pass, C3=pass
        // create draft
        var createResp = await auditorClient.PostAsJsonAsync("/api/submissions", new { status = "draft", templateId, storeId });
        var subId = Guid.Parse((await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var answers = new[]
        {
            new { criteriaId = criteriaIds[0], value = "non_conform" }, // Should be IsFailure = true
            new { criteriaId = criteriaIds[1], value = "conform" },     // Should be IsFailure = false
            new { criteriaId = criteriaIds[2], value = "conform" }      // Should be IsFailure = false
        };

        var finalResp = await auditorClient.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
        {
            clientScore = 70.0m,  // Server: Section A (1 fail/2 = 0.5 ratio × 60 weight) + Section B (0 fail = 1.0 ratio × 40 weight) = 70%
            sectionScores,
            answers
        });
        Assert.True(finalResp.IsSuccessStatusCode, $"Finalize failed: {await finalResp.Content.ReadAsStringAsync()}");

        // Assert
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // RED: This will fail compilation until Answer.IsFailure is added
        var dbAnswers = await db.Answers.Where(a => a.SubmissionId == subId).ToListAsync();
        
        var c1Answer = dbAnswers.Single(a => a.CriteriaId == criteriaIds[0]);
        var c2Answer = dbAnswers.Single(a => a.CriteriaId == criteriaIds[1]);

        Assert.True(c1Answer.IsFailure, "C1 (non_conform) should have IsFailure = true");
        Assert.False(c2Answer.IsFailure, "C2 (conform) should have IsFailure = false");
    }

    /// <summary>
    /// SC-A6: Survey submissions stamp IsFailure=false on all answers
    /// Expected RED: Answer entity doesn't have IsFailure property yet.
    /// </summary>
    [Fact]
    public async Task Survey_Mode_Stamps_All_Answers_As_Not_Failure()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("a6");
        var storeId = await CreateStoreAsync(adminClient, "SC-A6 Store");
        var (templateId, criteriaIds) = await CreateTemplateWithSectionsAsync(adminClient, "survey");
        var (auditorClient, _) = await CreateRoleClientAsync("s6-aud@test.test", "auditor");

        // Act - Submit anything (even "non_conform")
        var createResp = await auditorClient.PostAsJsonAsync("/api/submissions", new { status = "draft", templateId, storeId });
        var subId = Guid.Parse((await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var answers = new[]
        {
            new { criteriaId = criteriaIds[0], value = "non_conform" }, 
            new { criteriaId = criteriaIds[1], value = "conform" },     
        };

        await auditorClient.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
        {
            clientScore = 0.0m, // Survey mode: no scoring applied
            answers
        });

        // Assert
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var dbAnswers = await db.Answers.Where(a => a.SubmissionId == subId).ToListAsync();
        
        // RED: Compilation fails until Answer.IsFailure exists
        Assert.All(dbAnswers, a => Assert.False(a.IsFailure, "Survey answer should never be marked IsFailure"));
    }

    /// <summary>
    /// SC-A7: GetTopFailures logic must only count semantic failures, not string matching.
    /// Expected RED: Route exists but uses value != 'pass', so it will incorrectly return C2.
    /// </summary>
    [Fact]
    public async Task GetTopFailures_Uses_Semantic_IsFailure_Instead_Of_String_Matching()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync("a7");
        var storeId = await CreateStoreAsync(adminClient, "SC-A7 Store");
        
        // Custom template: C1 is pass_fail, C2 is numeric.
        var tResp = await adminClient.PostAsJsonAsync("/api/templates", new { title = "A7", type = "qc" });
        var templateId = Guid.Parse((await tResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);
        var gId = await CreateGroupAsync(adminClient, templateId, "G1", 100m, 10m, 5m, 0);
        
        var c1Id = await CreateCriterionAsync(adminClient, templateId, gId, "True Failure", "pass_fail", 5m, 0);
        var c2Id = await CreateCriterionAsync(adminClient, templateId, gId, "Not A Failure", "numeric", 5m, 1);

        var (auditorClient, _) = await CreateRoleClientAsync("s7-aud@test.test", "auditor");

        // Act: Submission where C1 fails (non_conform) and C2 has value=0 but string is null (or whatever default is)
        // Wait, numeric inputs have value=null and numericValue=0 for pass. 
        // If numericValue=0, it's not a fault. But old string logic `value != 'pass' && value != 'n/a'` 
        // will catch it if value is null because null != 'pass'! Wait, `a.Value != null` is in the old query.
        // Let's make C2 `numericValue=0` and `value="0"` (the app often echo strings).
        var createResp = await auditorClient.PostAsJsonAsync("/api/submissions", new { status = "draft", templateId, storeId });
        var subId = Guid.Parse((await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var answers = new[]
        {
            // True semantic failure
            new { criteriaId = c1Id, value = "non_conform", numericValue = (decimal?)null }, 
            // NOT a semantic failure, but string is not "pass"
            new { criteriaId = c2Id, value = "0", numericValue = (decimal?)0 } 
        };

        var sectionScores = JsonSerializer.Serialize(new Dictionary<string, object> { ["G1"] = new { score = 50.0, maxScore = 100.0 } });
        await auditorClient.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
        {
            // Server: 1 section, weight=100. C1=non_conform (5pts deduction from 10 total) → ratio 0.5 → 50%
            clientScore = 50.0m,
            sectionScores,
            answers
        });

        // Query analytics
        var response = await adminClient.GetAsync($"/api/analytics/top-failures?templateId={templateId}");
        
        // Assert
        response.EnsureSuccessStatusCode();
        var items = await response.Content.ReadFromJsonAsync<JsonElement>();
        var failLabels = items.EnumerateArray().Select(i => i.GetProperty("criterionLabel").GetString()).ToList();

        // RED: This will currently fail because "Not A Failure" (C2) will be in the list 
        // because its value "0" != "pass" && !="na" && !=null.
        Assert.Contains("True Failure", failLabels);
        Assert.DoesNotContain("Not A Failure", failLabels);
    }

    /// <summary>
    /// SC-A8: GetTopFailures missing templateId returns 400.
    /// Expected GREEN: Existing validation logic works.
    /// </summary>
    [Fact]
    public async Task GetTopFailures_Without_TemplateId_Returns_BadRequest()
    {
        var adminClient = await CreateAdminClientAsync("a8");
        var response = await adminClient.GetAsync("/api/analytics/top-failures");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}


