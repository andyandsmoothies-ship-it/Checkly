using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.GlobalRisks;

[Collection("Sequential")]
public class SubmissionRiskApiTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SubmissionRiskApiTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<(HttpClient Client, Guid AuditorId)> SetupAuditorAsync()
    {
        var email = $"auditor_{Guid.NewGuid()}@test.com";
        var (token, userId) = await _factory.RegisterUserAsync(_factory.CreateClient(), email, "Aa1234567@", "Test Auditor", "auditor");
        return (_factory.CreateAuthenticatedClient(token), userId);
    }

    private async Task<Guid> SetupGlobalRiskAsync(bool isActive = true)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var riskId = Guid.NewGuid();
        db.GlobalRisks.Add(new GlobalRisk
        {
            Id = riskId,
            Label = $"Risk {Guid.NewGuid()}",
            IsActive = isActive,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return riskId;
    }

    private async Task<Guid> SetupSubmissionAsync(Guid auditorId, string status = "draft")
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var subId = Guid.NewGuid();
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        if (await db.Templates.FindAsync(templateId) == null)
            db.Templates.Add(new Template { Id = templateId, Title = "T1", Version = 1, IsActive = true });
        if (await db.Stores.FindAsync(storeId) == null)
            db.Stores.Add(new Store { Id = storeId, Name = "S1", IsActive = true });

        db.Submissions.Add(new Submission
        {
            Id = subId,
            TemplateId = templateId,
            StoreId = storeId,
            AuditorId = auditorId,
            Status = status,
            TemplateTitle = "T1",
            StoreName = "S1",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        });
        await db.SaveChangesAsync();
        return subId;
    }

    [Fact]
    public async Task Auditor_TriggersRisk_OnOwnDraftSubmission_ReturnsCreated()
    {
        // T1: Auditor triggers risk on own draft submission
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "draft");

        var response = await client.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }

    [Fact]
    public async Task TriggerSameRisk_Twice_ReturnsConflict()
    {
        // T2: Trigger same risk twice on same submission returns 409 Conflict
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "draft");

        await client.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });
        var response2 = await client.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });

        Assert.Equal(HttpStatusCode.Conflict, response2.StatusCode);
    }

    [Fact]
    public async Task TriggerRisk_OnFinalizedSubmission_ReturnsConflict()
    {
        // T3: Trigger risk on finalized (completed) submission returns 409 Conflict
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "completed");

        var response = await client.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_ListsRisks_OnOwnSubmission()
    {
        // T4: Auditor lists risks on own submission
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "draft");

        // trigger it first (using DB directly to avoid dependency on POST)
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.SubmissionRisks.Add(new SubmissionRisk
            {
                Id = Guid.NewGuid(),
                SubmissionId = submissionId,
                GlobalRiskId = riskId,
                TriggeredById = auditorId,
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        var response = await client.GetAsync($"/api/submissions/{submissionId}/risks");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, json.GetArrayLength());
    }

    [Fact]
    public async Task Auditor_RemovesRisk_FromDraftSubmission()
    {
        // T5: Auditor removes risk from draft submission
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "draft");

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.SubmissionRisks.Add(new SubmissionRisk
            {
                Id = Guid.NewGuid(),
                SubmissionId = submissionId,
                GlobalRiskId = riskId,
                TriggeredById = auditorId,
                CreatedAt = DateTimeOffset.UtcNow
            });
            await db.SaveChangesAsync();
        }

        var response = await client.DeleteAsync($"/api/submissions/{submissionId}/risks/{riskId}");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task RemoveRisk_FromFinalizedSubmission_ReturnsConflict()
    {
        // T6: Remove risk from finalized submission returns 409 Conflict
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        var submissionId = await SetupSubmissionAsync(auditorId, "completed");

        var response = await client.DeleteAsync($"/api/submissions/{submissionId}/risks/{riskId}");

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Auditor_TriggersRisk_OnAnotherAuditorsSubmission_ReturnsForbidden()
    {
        // Gap 1: IDOR
        var (client1, auditor1Id) = await SetupAuditorAsync();
        var (_, auditor2Id) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync();
        
        // Submission belongs to auditor 2
        var submissionId = await SetupSubmissionAsync(auditor2Id, "draft");

        // Auditor 1 tries to trigger risk on Auditor 2's submission
        var response = await client1.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Triggering_InactiveRisk_ReturnsNotFound()
    {
        // Gap 3: Inactive global risk
        var (client, auditorId) = await SetupAuditorAsync();
        var riskId = await SetupGlobalRiskAsync(isActive: false);
        var submissionId = await SetupSubmissionAsync(auditorId, "draft");

        var response = await client.PostAsJsonAsync($"/api/submissions/{submissionId}/risks", new { GlobalRiskId = riskId });

        // Ensure it fails now (404 from routing won't have this message)
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("not found", body.ToLower());
    }
}
