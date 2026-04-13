using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD RED tests for:
///   S1 — Auto-create action plans on submission (1 AP per non_conform answer)
///   S2 — Generate notifications on AP status change
///
/// These tests are expected to FAIL (RED) because the production code does not
/// yet implement auto-AP creation or notification generation.
/// </summary>
public class SubmissionActionPlanTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SubmissionActionPlanTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ================================================================
    // Helpers
    // ================================================================

    /// <summary>
    /// Seeds a template with N criteria across 1 group, plus a store with a
    /// Profile in role 'store_manager' linked via Profile.StoreId.
    /// Returns (templateId, storeId, criteriaIds[], smProfileId).
    /// </summary>
    private async Task<(Guid TemplateId, Guid StoreId, List<Guid> CriteriaIds, Guid SmProfileId)>
        SeedTestDataAsync(int criteriaCount = 3)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create store
        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = "Test Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Create SM profile linked to store
        var smProfileId = Guid.NewGuid();
        db.Profiles.Add(new Profile
        {
            Id = smProfileId,
            FullName = "SM User",
            Email = $"sm-{smProfileId:N}@test.com",
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Create template
        var templateId = Guid.NewGuid();
        db.Templates.Add(new Template
        {
            Id = templateId,
            Title = "Test Template",
            Type = "QC",
            Version = 1,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Create group
        var groupId = Guid.NewGuid();
        db.Groups.Add(new Group
        {
            Id = groupId,
            TemplateId = templateId,
            Title = "HOSPITALITY",
            IsActive = true,
            OrderIndex = 0,
            MaxDeductionPoints = 100,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Create criteria
        var criteriaIds = new List<Guid>();
        for (var i = 0; i < criteriaCount; i++)
        {
            var cId = Guid.NewGuid();
            criteriaIds.Add(cId);
            db.Criteria.Add(new Criterion
            {
                Id = cId,
                GroupId = groupId,
                Label = $"H{i + 1}",
                InputType = "pass_fail",
                IsActive = true,
                OrderIndex = i,
                PointsWeight = 5,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        await db.SaveChangesAsync();
        return (templateId, storeId, criteriaIds, smProfileId);
    }

    /// <summary>
    /// Registers an auditor and returns an authenticated client + userId.
    /// </summary>
    private async Task<(HttpClient Client, Guid UserId)> CreateAuditorClientAsync()
    {
        var client = _factory.CreateClient();
        var email = $"auditor-{Guid.NewGuid():N}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, "Audit123!@", "Test Auditor", "auditor");
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    /// <summary>
    /// Registers a store_manager and returns an authenticated client + userId.
    /// store_managers hold the 'action_plans:write' capability (evidence submission).
    /// </summary>
    private async Task<(HttpClient Client, Guid UserId)> CreateStoreManagerClientAsync()
    {
        var client = _factory.CreateClient();
        var email = $"sm-{Guid.NewGuid():N}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(
            client, email, "SM123!@", "Test SM", "store_manager");
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    // ================================================================
    // S1: Auto-Create Action Plans on Submission
    // ================================================================

    /// <summary>
    /// S1-1: One AP created per non_conform answer.
    /// Source: CORE_WORKFLOWS.md L142: "one action plan per failed answer"
    /// </summary>
    [Fact]
    public async Task S1_1_Creates_One_AP_Per_NonConform_Answer()
    {
        var (templateId, storeId, criteriaIds, _) = await SeedTestDataAsync(5);
        var (client, _) = await CreateAuditorClientAsync();

        var answers = criteriaIds.Select((cId, i) => new
        {
            criteriaId = cId,
            value = i < 2 ? "non_conform" : "conform",
            numericValue = i < 2 ? 0m : 5m,
            note = (string?)null,
            photoUrl = (string?)null,
            isRepeatedError = false
        }).ToList();

        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 60m,
            answers, idempotencyKey = Guid.NewGuid().ToString()
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var actionPlans = await db.ActionPlans
            .Where(ap => ap.SubmissionId == submissionId)
            .ToListAsync();

        Assert.Equal(2, actionPlans.Count); // RED: currently 0
        Assert.All(actionPlans, ap => Assert.Equal("open", ap.Status));
        Assert.All(actionPlans, ap => Assert.NotNull(ap.AnswerId));
    }

    /// <summary>
    /// S1-2: AP deadline = NOW + 7 days (default).
    /// Source: CORE_WORKFLOWS.md L146
    /// </summary>
    [Fact]
    public async Task S1_2_AP_Deadline_Is_Seven_Days_From_Now()
    {
        var (templateId, storeId, criteriaIds, _) = await SeedTestDataAsync(1);
        var (client, _) = await CreateAuditorClientAsync();

        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 0m,
            answers = new[] { new { criteriaId = criteriaIds[0], value = "non_conform", numericValue = 0m, isRepeatedError = false } },
            idempotencyKey = Guid.NewGuid().ToString()
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var ap = await db.ActionPlans.FirstOrDefaultAsync(a => a.SubmissionId == submissionId);

        Assert.NotNull(ap); // RED
        Assert.NotNull(ap!.Deadline);
        var expected = DateTimeOffset.UtcNow.AddDays(7);
        Assert.InRange(ap.Deadline!.Value, expected.AddMinutes(-5), expected.AddMinutes(5));
    }

    /// <summary>
    /// S1-3: AP snapshots store and criteria info.
    /// Source: CORE_WORKFLOWS.md L147
    /// </summary>
    [Fact]
    public async Task S1_3_AP_Snapshots_Store_And_Criteria_Info()
    {
        var (templateId, storeId, criteriaIds, _) = await SeedTestDataAsync(1);
        var (client, _) = await CreateAuditorClientAsync();

        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 0m,
            answers = new[] { new { criteriaId = criteriaIds[0], value = "non_conform", numericValue = 0m, isRepeatedError = false } },
            idempotencyKey = Guid.NewGuid().ToString()
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var ap = await db.ActionPlans.FirstOrDefaultAsync(a => a.SubmissionId == submissionId);

        Assert.NotNull(ap); // RED
        Assert.Equal("Test Store", ap!.StoreName);
        Assert.Equal("SM User", ap.StoreManagerName);
        Assert.Equal("H1", ap.CriteriaLabel);
        Assert.Equal("HOSPITALITY", ap.GroupTitle);
    }

    /// <summary>
    /// S1-4: No APs for conform or na answers.
    /// Source: CORE_WORKFLOWS.md L144: "only 'non_conform' triggers"
    /// </summary>
    [Fact]
    public async Task S1_4_No_APs_For_Conform_Or_NA_Answers()
    {
        var (templateId, storeId, criteriaIds, _) = await SeedTestDataAsync(3);
        var (client, _) = await CreateAuditorClientAsync();

        var answers = criteriaIds.Select((cId, i) => new
        {
            criteriaId = cId,
            value = i == 2 ? "na" : "conform",
            numericValue = i == 2 ? (decimal?)null : 5m,
            isRepeatedError = false
        }).ToList();

        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 100m, answers,
            idempotencyKey = Guid.NewGuid().ToString()
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await db.ActionPlans.CountAsync(a => a.SubmissionId == submissionId);

        Assert.Equal(0, count); // Should PASS even now (vacuously true)
    }

    /// <summary>
    /// S1-5: Idempotent — no duplicate APs on retry.
    /// Source: CORE_WORKFLOWS.md L145
    /// </summary>
    [Fact]
    public async Task S1_5_Idempotent_No_Duplicate_APs_On_Retry()
    {
        var (templateId, storeId, criteriaIds, _) = await SeedTestDataAsync(1);
        var (client, _) = await CreateAuditorClientAsync();
        var key = Guid.NewGuid().ToString();

        var payload = new
        {
            templateId, storeId, clientScore = 0m,
            answers = new[] { new { criteriaId = criteriaIds[0], value = "non_conform", numericValue = 0m, isRepeatedError = false } },
            idempotencyKey = key
        };

        var r1 = await client.PostAsJsonAsync("/api/submissions", payload);
        var r2 = await client.PostAsJsonAsync("/api/submissions", payload);

        Assert.Equal(HttpStatusCode.Created, r1.StatusCode);
        Assert.Equal(HttpStatusCode.OK, r2.StatusCode);

        var body = await r1.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var count = await db.ActionPlans.CountAsync(a => a.SubmissionId == submissionId);

        Assert.Equal(1, count); // RED: currently 0
    }

    // ================================================================
    // S2: Notifications on AP Status Change
    // ================================================================

    /// <summary>
    /// S2-1: Evidence submitted → notification 'action_plan_evidence_submitted'.
    /// Source: CORE_WORKFLOWS.md L98
    /// </summary>
    [Fact]
    public async Task S2_1_Evidence_Submitted_Creates_Notification()
    {
        using var seedScope = _factory.Services.CreateScope();
        var seedDb = seedScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        seedDb.Stores.Add(new Store
        {
            Id = storeId, Name = "S2-1 Store",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var smId = Guid.NewGuid();
        seedDb.Profiles.Add(new Profile
        {
            Id = smId, FullName = "SM", Email = "sm@s2-1.test",
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        // Register a real auditor via the API so PBAC cache recognises their role.
        // Auditors have 'action_plans:write' per PBAC migration; IDOR passes when
        // Submission.AuditorId == JWT userId.
        var (auditorClient, auditorUserId) = await CreateAuditorClientAsync();

        var submissionId = Guid.NewGuid();
        seedDb.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = null, TemplateTitle = "S2-1 Template",
            StoreId = storeId, StoreName = "S2-1 Store",
            AuditorId = auditorUserId, AuditorName = "Test Auditor",
            ScoringMode = "penalty",
            Status = "draft",
            TotalScore = 0m,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var apId = Guid.NewGuid();
        seedDb.ActionPlans.Add(new ActionPlan
        {
            Id = apId, StoreId = storeId, StoreManagerId = smId,
            SubmissionId = submissionId,
            CriteriaLabel = "H1", GroupTitle = "HOSPITALITY",
            Status = "open",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });
        await seedDb.SaveChangesAsync();

        // Auditor submits evidence (pending_verify transition).
        // PBAC: auditor has 'action_plans:write'. IDOR: Submission.AuditorId == auditorUserId → passes.
        var response = await auditorClient.PutAsJsonAsync($"/api/action-plans/{apId}", new
        {
            status = "pending_verify",
            evidenceNote = "Fixed the issue"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notif = await db.Notifications
            .FirstOrDefaultAsync(n => n.Type == "action_plan_evidence_submitted");

        Assert.NotNull(notif); // RED
    }

    /// <summary>
    /// S2-2: Plan closed → notification 'action_plan_closed' targeting SM.
    /// Source: CORE_WORKFLOWS.md L99
    /// </summary>
    [Fact]
    public async Task S2_2_Plan_Closed_Notifies_SM()
    {
        using var seedScope = _factory.Services.CreateScope();
        var seedDb = seedScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        seedDb.Stores.Add(new Store
        {
            Id = storeId, Name = "S2-2 Store",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var smId = Guid.NewGuid();
        seedDb.Profiles.Add(new Profile
        {
            Id = smId, FullName = "SM Close", Email = "sm@s2-2.test",
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        // Seed a Submission with the auditor as AuditorId
        // so SubmissionAccessGuard resolves linkedAuditorId correctly.
        var (auditorClient, auditorUserId) = await CreateAuditorClientAsync();

        var submissionId = Guid.NewGuid();
        seedDb.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = null, TemplateTitle = "S2-2 Template",
            StoreId = storeId, StoreName = "S2-2 Store",
            AuditorId = auditorUserId, AuditorName = "Test Auditor",
            ScoringMode = "penalty",
            Status = "draft",
            TotalScore = 0m,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var apId = Guid.NewGuid();
        seedDb.ActionPlans.Add(new ActionPlan
        {
            Id = apId, StoreId = storeId, StoreManagerId = smId,
            SubmissionId = submissionId,
            CriteriaLabel = "H2", GroupTitle = "HYGIENE",
            Status = "pending_verify",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });
        await seedDb.SaveChangesAsync();

        await auditorClient.PutAsJsonAsync($"/api/action-plans/{apId}", new { status = "closed" });

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notif = await db.Notifications
            .FirstOrDefaultAsync(n => n.Type == "action_plan_closed" && n.UserId == smId);

        Assert.NotNull(notif); // RED
        Assert.Equal(smId, notif!.UserId);
    }

    /// <summary>
    /// S2-3: Evidence rejected → notification 'action_plan_rejected' to SM.
    /// Source: CORE_WORKFLOWS.md L100
    /// </summary>
    [Fact]
    public async Task S2_3_Evidence_Rejected_Notifies_SM()
    {
        using var seedScope = _factory.Services.CreateScope();
        var seedDb = seedScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        seedDb.Stores.Add(new Store
        {
            Id = storeId, Name = "S2-3 Store",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var smId = Guid.NewGuid();
        seedDb.Profiles.Add(new Profile
        {
            Id = smId, FullName = "SM Reject", Email = "sm@s2-3.test",
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        // Seed a Submission with the auditor as AuditorId
        // so SubmissionAccessGuard resolves linkedAuditorId correctly.
        var (auditorClient, auditorUserId) = await CreateAuditorClientAsync();

        var submissionId = Guid.NewGuid();
        seedDb.Submissions.Add(new Submission
        {
            Id = submissionId,
            TemplateId = null, TemplateTitle = "S2-3 Template",
            StoreId = storeId, StoreName = "S2-3 Store",
            AuditorId = auditorUserId, AuditorName = "Test Auditor",
            ScoringMode = "penalty",
            Status = "draft",
            TotalScore = 0m,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var apId = Guid.NewGuid();
        seedDb.ActionPlans.Add(new ActionPlan
        {
            Id = apId, StoreId = storeId, StoreManagerId = smId,
            SubmissionId = submissionId,
            CriteriaLabel = "H3", GroupTitle = "HEALTH",
            Status = "pending_verify",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });
        await seedDb.SaveChangesAsync();

        await auditorClient.PutAsJsonAsync($"/api/action-plans/{apId}", new { status = "open" });

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var notif = await db.Notifications
            .FirstOrDefaultAsync(n => n.Type == "action_plan_rejected" && n.UserId == smId);

        Assert.NotNull(notif); // RED
    }

    /// <summary>
    /// S2-4: No notification for non-status updates.
    /// Source: Defensive — prevents notification spam on field-only patches
    /// </summary>
    [Fact]
    public async Task S2_4_No_Notification_For_NonStatus_Updates()
    {
        using var seedScope = _factory.Services.CreateScope();
        var seedDb = seedScope.ServiceProvider.GetRequiredService<AppDbContext>();

        var apId = Guid.NewGuid();
        seedDb.ActionPlans.Add(new ActionPlan
        {
            Id = apId, CriteriaLabel = "H4", GroupTitle = "GENERAL",
            Status = "open",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });
        await seedDb.SaveChangesAsync();

        var countBefore = await seedDb.Notifications.CountAsync();

        var (client, _) = await CreateAuditorClientAsync();
        await client.PutAsJsonAsync($"/api/action-plans/{apId}", new
        {
            correctionPlan = "Updated plan text"
        });

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var countAfter = await db.Notifications.CountAsync();

        Assert.Equal(countBefore, countAfter); // Should PASS even now
    }

    // ================================================================
    // F1/F2: Action Plan Hardening Tests
    // ================================================================

    /// <summary>
    /// Seeds a template with ScoringLogicConfig (for F1/F2 tests).
    /// Returns (templateId, storeId, criteriaIds[], smProfileId).
    /// </summary>
    private async Task<(Guid TemplateId, Guid StoreId, List<Guid> CriteriaIds, Guid SmProfileId)>
        SeedTestDataWithConfigAsync(string? scoringLogicConfig, int criteriaCount = 1)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId, Name = "Config Test Store",
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var smProfileId = Guid.NewGuid();
        db.Profiles.Add(new Profile
        {
            Id = smProfileId, FullName = "Config SM",
            Email = $"sm-{smProfileId:N}@test.com", StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var templateId = Guid.NewGuid();
        db.Templates.Add(new Template
        {
            Id = templateId, Title = "Config Test Template", Type = "QC",
            Version = 1, IsActive = true,
            ScoringLogicConfig = scoringLogicConfig,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var groupId = Guid.NewGuid();
        db.Groups.Add(new Group
        {
            Id = groupId, TemplateId = templateId, Title = "TEST SECTION",
            IsActive = true, OrderIndex = 0, MaxDeductionPoints = 100,
            CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
        });

        var criteriaIds = new List<Guid>();
        for (var i = 0; i < criteriaCount; i++)
        {
            var cId = Guid.NewGuid();
            criteriaIds.Add(cId);
            db.Criteria.Add(new Criterion
            {
                Id = cId, GroupId = groupId, Label = $"C{i + 1}",
                InputType = "pass_fail", IsActive = true, OrderIndex = i,
                PointsWeight = 5,
                CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow
            });
        }

        await db.SaveChangesAsync();
        return (templateId, storeId, criteriaIds, smProfileId);
    }

    /// <summary>
    /// F1: Template with action_plan_deadline_days=14 → AP deadline = NOW + 14 days.
    /// Source: implementation_plan.md E2
    /// </summary>
    [Fact]
    public async Task F1_AP_Uses_Template_Configured_Deadline()
    {
        var config = JsonSerializer.Serialize(new
        {
            scoringMode = "penalty",
            features = new { action_plan_deadline_days = 14 }
        });

        var (templateId, storeId, criteriaIds, _) = await SeedTestDataWithConfigAsync(config);
        var (client, _) = await CreateAuditorClientAsync();

        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 0m,
            answers = new[] { new { criteriaId = criteriaIds[0], value = "non_conform", numericValue = 0m, isRepeatedError = false } },
            idempotencyKey = Guid.NewGuid().ToString()
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var ap = await db.ActionPlans.FirstOrDefaultAsync(a => a.SubmissionId == submissionId);

        Assert.NotNull(ap);
        Assert.NotNull(ap!.Deadline);
        var expected = DateTimeOffset.UtcNow.AddDays(14);
        Assert.InRange(ap.Deadline!.Value, expected.AddMinutes(-5), expected.AddMinutes(5));
    }

    /// <summary>
    /// F2: Survey-mode template + non_conform answers → 0 APs created.
    /// Source: implementation_plan.md E1
    /// </summary>
    [Fact]
    public async Task F2_Survey_Mode_Skips_AP_Creation()
    {
        var config = JsonSerializer.Serialize(new
        {
            scoringMode = "survey"
        });

        var (templateId, storeId, criteriaIds, _) = await SeedTestDataWithConfigAsync(config, criteriaCount: 3);
        var (client, _) = await CreateAuditorClientAsync();

        var answers = criteriaIds.Select(cId => new
        {
            criteriaId = cId,
            value = "non_conform",
            numericValue = 0m,
            isRepeatedError = false
        }).ToList();

        // Survey mode: clientScore must be provided (validation is mode-agnostic), use 0
        var response = await client.PostAsJsonAsync("/api/submissions", new
        {
            templateId, storeId, clientScore = 0m,
            answers, idempotencyKey = Guid.NewGuid().ToString()
        });

        // Survey submissions should succeed
        Assert.True(response.IsSuccessStatusCode, $"Expected success but got {response.StatusCode}");
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = body.GetProperty("id").GetGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var apCount = await db.ActionPlans.CountAsync(a => a.SubmissionId == submissionId);

        Assert.Equal(0, apCount); // Survey mode = no APs
    }
}
