using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Analytics V2 Slice B — Universal Distributions.
/// Verifies that GET /api/submissions/survey-results works for ALL template types,
/// not just survey-mode templates.
///
/// SC-B1: Penalty-mode template returns distributions (gate removed).
/// SC-B2: Survey-mode template still returns correct distributions (regression).
/// SC-B3: ?inputTypes= filter returns only matching criteria.
/// SC-B4: Missing templateId returns 400.
/// SC-B5: Auditor cannot access (403).
/// </summary>
public class SurveyResultsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public SurveyResultsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ─── Helpers ───────────────────────────────────────────────────────────

    private async Task<HttpClient> AdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<HttpClient> AuditorClientAsync()
    {
        var client = _factory.CreateClient();
        var (token, _) = await _factory.RegisterUserAsync(
            client, $"srb-aud-{_runId}@test.test", "Test123!Pass", "Aud", "auditor");
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<Guid> CreateStoreAsync(HttpClient admin, string name)
    {
        var r = await admin.PostAsJsonAsync("/api/stores", new { name });
        var j = await r.Content.ReadFromJsonAsync<JsonElement>();
        return Guid.Parse(j.GetProperty("id").GetString()!);
    }

    private async Task<(Guid templateId, Guid criterionId)> CreatePenaltyTemplateWithChoiceCriterionAsync(
        HttpClient admin)
    {
        var tResp = await admin.PostAsJsonAsync("/api/templates", new
        {
            title = $"SCB-Penalty-{_runId}",
            type = "qc"
            // default scoringLogicConfig → penalty mode
        });
        var templateId = Guid.Parse(
            (await tResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var gResp = await admin.PostAsJsonAsync($"/api/templates/{templateId}/groups", new
        {
            title = "Section 1",
            weight = 100.0m,
            maxDeductionPoints = 100.0m,
            minusPerFault = 5.0m,
            orderIndex = 0
        });
        var groupId = Guid.Parse(
            (await gResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var cResp = await admin.PostAsJsonAsync(
            $"/api/templates/{templateId}/groups/{groupId}/criteria", new
            {
                label = "Choice Question",
                inputType = "single_choice",
                pointsWeight = 5.0m,
                orderIndex = 0,
                metadata = "{\"options\":[{\"label\":\"Option A\",\"value\":\"Option A\"},{\"label\":\"Option B\",\"value\":\"Option B\"}]}"
            });
        var criterionId = Guid.Parse(
            (await cResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        return (templateId, criterionId);
    }

    private async Task<Guid> FinalizeWithChoiceAnswerAsync(
        HttpClient auditor, Guid templateId, Guid storeId, Guid criterionId, string choiceValue)
    {
        var createResp = await auditor.PostAsJsonAsync("/api/submissions", new
        {
            status = "draft",
            templateId,
            storeId
        });
        var subId = Guid.Parse(
            (await createResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        await auditor.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
        {
            clientScore = 100.0m, // Single choice → unscored → 0 deductions → 100%
            answers = new[] { new { criteriaId = criterionId, value = choiceValue, numericValue = (decimal?)null } }
        });

        return subId;
    }

    // ─── SC-B1: Penalty-mode template returns distributions ─────────────

    /// <summary>
    /// SC-B1: Removing the ScoringMode gate means penalty-mode templates with
    /// choice-type criteria now return distributions.
    /// Previously: 0 results (blocked by ScoringMode == "survey").
    /// After: distributions for the answered criterion are returned.
    /// </summary>
    [Fact]
    public async Task GetSurveyResults_For_PenaltyTemplate_Returns_Distributions()
    {
        // Arrange
        var admin = await AdminClientAsync();
        var storeId = await CreateStoreAsync(admin, $"SCB1-Store-{_runId}");
        var (templateId, criterionId) = await CreatePenaltyTemplateWithChoiceCriterionAsync(admin);

        var (auditorToken, _) = await _factory.RegisterUserAsync(
            _factory.CreateClient(), $"scb1-aud-{_runId}@t.t", "Test123!Pass", "A1", "auditor");
        var auditor = _factory.CreateAuthenticatedClient(auditorToken);

        await FinalizeWithChoiceAnswerAsync(auditor, templateId, storeId, criterionId, "Option A");
        await FinalizeWithChoiceAnswerAsync(auditor, templateId, storeId, criterionId, "Option A");
        await FinalizeWithChoiceAnswerAsync(auditor, templateId, storeId, criterionId, "Option B");

        // Act
        var response = await admin.GetAsync($"/api/submissions/survey-results?templateId={templateId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var items = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Array, items.ValueKind);
        Assert.True(items.GetArrayLength() > 0, "SC-B1: Penalty template should now return distributions");

        var criterion = items.EnumerateArray()
            .FirstOrDefault(i => i.GetProperty("criterionId").GetGuid() == criterionId);
        Assert.NotEqual(default, criterion.ValueKind);
        Assert.Equal(3, criterion.GetProperty("totalResponses").GetInt32());

        var options = criterion.GetProperty("options").EnumerateArray().ToList();
        var optionA = options.FirstOrDefault(o => o.GetProperty("value").GetString() == "Option A");
        Assert.Equal(2, optionA.GetProperty("count").GetInt32());
        Assert.Equal(66.7, optionA.GetProperty("percentage").GetDouble(), 0.1);
    }

    // ─── SC-B2: Survey-mode template still returns correct distributions ─

    /// <summary>
    /// SC-B2: Regression — existing survey-mode usage must still work correctly.
    /// </summary>
    [Fact]
    public async Task GetSurveyResults_For_SurveyTemplate_Still_Returns_Correct_Distributions()
    {
        // Arrange
        var admin = await AdminClientAsync();
        var storeId = await CreateStoreAsync(admin, $"SCB2-Store-{_runId}");

        var config = JsonSerializer.Serialize(new { scoringMode = "survey" });
        var tResp = await admin.PostAsJsonAsync("/api/templates", new
        {
            title = $"SCB2-Survey-{_runId}",
            type = "qc",
            scoringLogicConfig = config
        });
        var templateId = Guid.Parse(
            (await tResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var gResp = await admin.PostAsJsonAsync($"/api/templates/{templateId}/groups", new
        {
            title = "Section 1", weight = 0m, maxDeductionPoints = 0m, minusPerFault = 0m, orderIndex = 0
        });
        var groupId = Guid.Parse(
            (await gResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var cResp = await admin.PostAsJsonAsync(
            $"/api/templates/{templateId}/groups/{groupId}/criteria", new
            {
                label = "Survey Question",
                inputType = "single_choice",
                pointsWeight = 0m,
                orderIndex = 0,
                metadata = "{\"options\":[{\"label\":\"Yes\",\"value\":\"Yes\"},{\"label\":\"No\",\"value\":\"No\"}]}"
            });
        var criterionId = Guid.Parse(
            (await cResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var (auditorToken, _) = await _factory.RegisterUserAsync(
            _factory.CreateClient(), $"scb2-aud-{_runId}@t.t", "Test123!Pass", "A2", "auditor");
        var auditor = _factory.CreateAuthenticatedClient(auditorToken);

        // Finalize 2 survey submissions (survey mode → clientScore doesn't matter)
        for (int i = 0; i < 2; i++)
        {
            var cr = await auditor.PostAsJsonAsync("/api/submissions", new { status = "draft", templateId, storeId });
            var subId = Guid.Parse((await cr.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);
            await auditor.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
            {
                clientScore = 0m,
                answers = new[] { new { criteriaId = criterionId, value = "Yes", numericValue = (decimal?)null } }
            });
        }

        // Act
        var response = await admin.GetAsync($"/api/submissions/survey-results?templateId={templateId}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var items = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Array, items.ValueKind);

        var criterion = items.EnumerateArray()
            .FirstOrDefault(i => i.GetProperty("criterionId").GetGuid() == criterionId);
        Assert.NotEqual(default, criterion.ValueKind);
        Assert.Equal(2, criterion.GetProperty("totalResponses").GetInt32());
    }

    // ─── SC-B3: ?inputTypes= filter returns only matching criteria ──────

    /// <summary>
    /// SC-B3: When ?inputTypes=single_choice is specified, only single_choice
    /// criteria are returned. A pass_fail criterion in the same template must not appear.
    /// </summary>
    [Fact]
    public async Task GetSurveyResults_With_InputTypes_Filter_Returns_Only_Matching_Criteria()
    {
        // Arrange
        var admin = await AdminClientAsync();
        var storeId = await CreateStoreAsync(admin, $"SCB3-Store-{_runId}");

        var tResp = await admin.PostAsJsonAsync("/api/templates", new { title = $"SCB3-{_runId}", type = "qc" });
        var templateId = Guid.Parse(
            (await tResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var gResp = await admin.PostAsJsonAsync($"/api/templates/{templateId}/groups", new
        {
            title = "G1", weight = 100m, maxDeductionPoints = 100m, minusPerFault = 5m, orderIndex = 0
        });
        var groupId = Guid.Parse(
            (await gResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var choiceResp = await admin.PostAsJsonAsync(
            $"/api/templates/{templateId}/groups/{groupId}/criteria", new
            {
                label = "Choice Criterion",
                inputType = "single_choice",
                pointsWeight = 0m,
                orderIndex = 0,
                metadata = "{\"options\":[{\"label\":\"OptionX\",\"value\":\"OptionX\"}]}"
            });
        var choiceCritId = Guid.Parse(
            (await choiceResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var pfResp = await admin.PostAsJsonAsync(
            $"/api/templates/{templateId}/groups/{groupId}/criteria", new
            {
                label = "Pass Fail Criterion",
                inputType = "pass_fail",
                pointsWeight = 5m,
                orderIndex = 1
            });
        var pfCritId = Guid.Parse(
            (await pfResp.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);

        var (tok, _) = await _factory.RegisterUserAsync(
            _factory.CreateClient(), $"scb3-aud-{_runId}@t.t", "Test123!Pass", "A3", "auditor");
        var auditor = _factory.CreateAuthenticatedClient(tok);

        var cr = await auditor.PostAsJsonAsync("/api/submissions", new { status = "draft", templateId, storeId });
        var subId = Guid.Parse((await cr.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetString()!);
        await auditor.PutAsJsonAsync($"/api/submissions/{subId}/finalize", new
        {
            clientScore = 100.0m,
            answers = new[]
            {
                new { criteriaId = choiceCritId, value = "OptionX", numericValue = (decimal?)null },
                new { criteriaId = pfCritId, value = "conform", numericValue = (decimal?)null }
            }
        });

        // Act — filter to single_choice only
        var response = await admin.GetAsync(
            $"/api/submissions/survey-results?templateId={templateId}&inputTypes=single_choice");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var items = await response.Content.ReadFromJsonAsync<JsonElement>();
        var criterionIds = items.EnumerateArray()
            .Select(i => i.GetProperty("criterionId").GetGuid())
            .ToList();

        Assert.Contains(choiceCritId, criterionIds);
        Assert.DoesNotContain(pfCritId, criterionIds);
    }

    // ─── SC-B4: Missing templateId returns 400 ──────────────────────────

    [Fact]
    public async Task GetSurveyResults_Without_TemplateId_Returns_BadRequest()
    {
        var admin = await AdminClientAsync();
        var response = await admin.GetAsync("/api/submissions/survey-results");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── SC-B5: Auditor cannot access (403) ─────────────────────────────

    [Fact]
    public async Task GetSurveyResults_Auditor_Returns_Forbidden()
    {
        var auditor = await AuditorClientAsync();
        var response = await auditor.GetAsync(
            $"/api/submissions/survey-results?templateId={Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
