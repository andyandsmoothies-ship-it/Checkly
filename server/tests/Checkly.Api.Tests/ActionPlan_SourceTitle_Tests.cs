using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// TDD RED Phase: Action Plan Source Label (AP01)
/// Workflow: /tdd | Track: B1
///
/// Input Lineage:
///   C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260515_211200_AP01_source.md
///
/// Why these tests fail first:
///   1. ActionPlan entity lacks the SourceTitle property.
///   2. CreateActionPlan.HandleAsync does not compute SourceTitle from ProgramAssignment or TemplateTitle.
///   3. ActionPlanDto record does not include a SourceTitle field.
/// </summary>
public class ActionPlan_SourceTitle_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ActionPlan_SourceTitle_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // =====================================================================
    // SEED HELPERS
    // =====================================================================

    /// <summary>
    /// Seeds the minimum data needed: a store, a registered store_manager, and a
    /// submission. Returns all seeded IDs and the SM's authenticated client.
    /// </summary>
    private async Task<(HttpClient Client, Guid SubmissionId, Guid StoreId)> SeedBaseAsync(
        Guid? programAssignmentId = null,
        string? templateTitle = null)
    {
        // Register a store_manager via the API
        var anonClient = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(anonClient);
        var (smToken, smUserId) = await _factory.RegisterUserAsync(
            anonClient,
            "sm@sourcetitle.test",
            "Sm12345!@",
            "SM SourceTitle",
            "store_manager",
            adminToken);

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var storeId = Guid.NewGuid();
        db.Stores.Add(new Store
        {
            Id = storeId,
            Name = "SourceTitle Store",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        // Assign store to the SM profile
        var profile = await db.Profiles.FindAsync(smUserId);
        if (profile != null)
        {
            profile.StoreId = storeId;
        }

        var submissionId = Guid.NewGuid();
        db.Submissions.Add(new Submission
        {
            Id = submissionId,
            AuditorId = smUserId,
            StoreId = storeId,
            Status = "completed",
            ScoringMode = "penalty",
            ProgramAssignmentId = programAssignmentId,
            TemplateTitle = templateTitle,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();

        var smClient = _factory.CreateAuthenticatedClient(smToken);
        return (smClient, submissionId, storeId);
    }

    /// <summary>
    /// Seeds a ChecklyProgram + ProgramAssignment so the submission can reference it.
    /// Returns the ProgramAssignmentId and the program's Title.
    /// </summary>
    private async Task<(Guid ProgramAssignmentId, string ProgramTitle)> SeedProgramAsync(Guid storeId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // We need a template for the program
        var templateId = Guid.NewGuid();
        db.Templates.Add(new Template
        {
            Id = templateId,
            Title = "Campaign Template",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var programId = Guid.NewGuid();
        var programTitle = "Summer Safety Campaign";
        db.Programs.Add(new ChecklyProgram
        {
            Id = programId,
            Title = programTitle,
            Category = "Safety",
            TemplateId = templateId,
            Deadline = DateTimeOffset.UtcNow.AddDays(30),
            Status = "active",
            CreatedBy = Guid.NewGuid(),
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        var assignmentId = Guid.NewGuid();
        db.ProgramAssignments.Add(new ProgramAssignment
        {
            Id = assignmentId,
            ProgramId = programId,
            StoreId = storeId,
            AssignedById = Guid.NewGuid(),
            Status = "pending",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync();
        return (assignmentId, programTitle);
    }

    /// <summary>
    /// Builds the minimal valid CreateActionPlanRequest body.
    /// </summary>
    private static object BuildCreateRequest(Guid submissionId) => new
    {
        submissionId,
        answerId = (Guid?)null,
        criteriaLabel = "Check for cleanliness",
        groupTitle = "Hygiene",
        planDescription = "Fix it",
        rootCause = "Negligence",
        correctionPlan = "Retrain staff",
        deadline = DateTimeOffset.UtcNow.AddDays(7)
    };

    // =====================================================================
    // TC_AP_SRC_01 — Campaign Source
    // =====================================================================

    [Fact]
    public async Task CreateActionPlan_WithCampaign_SetsCampaignSource()
    {
        // Arrange
        var storeId = Guid.NewGuid();
        var programTitle = "Summer Safety Campaign";

        // Seed a program + assignment before the submission references it
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Stores.Add(new Store
            {
                Id = storeId,
                Name = "Campaign Store",
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        var (assignmentId, _) = await SeedProgramAsync(storeId);
        var (client, submissionId, _) = await SeedBaseAsync(
            programAssignmentId: assignmentId,
            templateTitle: "Daily Cleanliness Audit");

        // Act
        var response = await client.PostAsJsonAsync("/api/action-plans", BuildCreateRequest(submissionId));

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 201 Created but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var sourceTitle = body.GetProperty("sourceTitle").GetString();

        Assert.NotNull(sourceTitle);
        Assert.StartsWith("Campaign:", sourceTitle);
        Assert.Contains(programTitle, sourceTitle);
    }

    // =====================================================================
    // TC_AP_SRC_02 — Audit (Standalone) Source
    // =====================================================================

    [Fact]
    public async Task CreateActionPlan_WithAudit_SetsAuditSource()
    {
        // Arrange — no ProgramAssignmentId; only a TemplateTitle on the submission
        var auditTemplateTitle = "Daily Cleanliness Audit";
        var (client, submissionId, _) = await SeedBaseAsync(
            programAssignmentId: null,
            templateTitle: auditTemplateTitle);

        // Act
        var response = await client.PostAsJsonAsync("/api/action-plans", BuildCreateRequest(submissionId));

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 201 Created but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var sourceTitle = body.GetProperty("sourceTitle").GetString();

        Assert.NotNull(sourceTitle);
        Assert.StartsWith("Audit:", sourceTitle);
        Assert.Contains(auditTemplateTitle, sourceTitle);
    }

    // =====================================================================
    // TC_AP_SRC_03 — Null SourceTitle (Legacy Data) — GET endpoint
    // =====================================================================

    [Fact]
    public async Task GetActionPlan_WithNullSourceTitle_ReturnsNullField()
    {
        // Arrange — seed an action plan directly without SourceTitle (legacy record)
        var storeId = Guid.NewGuid();
        var planId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Stores.Add(new Store
            {
                Id = storeId,
                Name = "Legacy Store",
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
            db.ActionPlans.Add(new ActionPlan
            {
                Id = planId,
                StoreId = storeId,
                StoreName = "Legacy Store",
                CriteriaLabel = "Old Criteria",
                GroupTitle = "Legacy",
                Status = "open",
                // SourceTitle is intentionally omitted (null) — simulates legacy data
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        // Register an admin to call the GET endpoint
        var anonClient = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(anonClient);
        var adminClient = _factory.CreateAuthenticatedClient(adminToken);

        // Act
        var response = await adminClient.GetAsync($"/api/action-plans/{planId}");

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Expected 200 OK but got {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();

        // The DTO must include the field (even if null) — no KeyNotFoundException
        Assert.True(body.TryGetProperty("sourceTitle", out var sourceTitleElement),
            "ActionPlanDto must include a 'sourceTitle' property even for legacy records.");

        Assert.Equal(JsonValueKind.Null, sourceTitleElement.ValueKind);
    }
}
