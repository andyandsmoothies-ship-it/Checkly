using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Programs;

/// <summary>
/// ATDD coverage for ArchiveProgram and UpdateProgram.
/// Phase 4 item: raised as stubs per the global audit (audit_code_report_core_execution_20260520).
/// </summary>
public class ProgramMutations_ATDD_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ProgramMutations_ATDD_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private async Task<HttpClient> CreateAdminClientAsync()
    {
        var client = _factory.CreateClient();
        var token = await _factory.LoginBootstrapAdminAsync(client);
        return _factory.CreateAuthenticatedClient(token);
    }

    /// <summary>Creates a minimal program and returns its ID.</summary>
    private async Task<Guid> CreateProgramAsync(HttpClient adminClient)
    {
        var tplResp = await adminClient.PostAsJsonAsync("/api/templates",
            new { title = $"Tpl-{Guid.NewGuid()}", type = "checklist" });
        tplResp.EnsureSuccessStatusCode();
        var templateId = (await tplResp.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetGuid();

        var storeResp = await adminClient.PostAsJsonAsync("/api/stores",
            new { name = $"Store-{Guid.NewGuid()}" });
        storeResp.EnsureSuccessStatusCode();
        var storeId = (await storeResp.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("id").GetGuid();

        var createResp = await adminClient.PostAsJsonAsync("/api/programs", new
        {
            templateId,
            storeIds = new[] { storeId },
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "MutationTest",
            title = $"Program-{Guid.NewGuid()}"
        });
        createResp.EnsureSuccessStatusCode();

        return (await createResp.Content.ReadFromJsonAsync<JsonElement>())
            .GetProperty("programId").GetGuid();
    }

    // ── UpdateProgram ────────────────────────────────────────────

    [Fact]
    public async Task UpdateProgram_Admin_ValidPayload_Returns200WithUpdatedTitle()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient);
        var newTitle = $"Updated Program {Guid.NewGuid()}";

        // Act
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", new
        {
            title = newTitle,
            deadline = DateTimeOffset.UtcNow.AddDays(14),
            category = "Updated"
        });

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
            Assert.Fail($"Route /api/programs/{{id}} not registered. Body: {body}");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {body}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = JsonDocument.Parse(body);
        Assert.Equal(newTitle, json.RootElement.GetProperty("title").GetString());
    }

    [Fact]
    public async Task UpdateProgram_NonExistentId_Returns404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{Guid.NewGuid()}", new
        {
            title = "Ghost Update",
            deadline = DateTimeOffset.UtcNow.AddDays(7),
            category = "Ghost"
        });

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task UpdateProgram_PastDeadline_ReturnsBadRequest()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient);

        // Act
        var response = await adminClient.PutAsJsonAsync($"/api/programs/{programId}", new
        {
            title = "Past Deadline Update",
            deadline = DateTimeOffset.UtcNow.AddDays(-1), // Past date
            category = "BadDate"
        });

        // Assert
        // Business rule: deadline cannot be set to the past
        var body = await response.Content.ReadAsStringAsync();
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Contains("deadline", body, StringComparison.OrdinalIgnoreCase);
    }

    // ── ArchiveProgram ───────────────────────────────────────────

    [Fact]
    public async Task ArchiveProgram_Admin_ActiveProgram_Returns200WithArchivedStatus()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient);

        // Act
        var response = await adminClient.PostAsync($"/api/programs/{programId}/archive", null);

        // Assert
        var body = await response.Content.ReadAsStringAsync();
        if (response.StatusCode == HttpStatusCode.NotFound)
            Assert.Fail($"Route /api/programs/{{id}}/archive not registered. Body: {body}");

        if (!response.IsSuccessStatusCode)
            Assert.Fail($"Status: {response.StatusCode}. Body: {body}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = JsonDocument.Parse(body);
        Assert.True(
            json.RootElement.TryGetProperty("status", out var status) &&
            status.GetString() == "archived",
            "Response must contain status = 'archived'.");
    }

    [Fact]
    public async Task ArchiveProgram_NonExistentId_Returns404()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();

        // Act
        var response = await adminClient.PostAsync($"/api/programs/{Guid.NewGuid()}/archive", null);

        // Assert
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task ArchiveProgram_AlreadyArchived_Returns409Conflict()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient);

        // First archive
        var firstArchive = await adminClient.PostAsync($"/api/programs/{programId}/archive", null);
        if (!firstArchive.IsSuccessStatusCode)
            Assert.Fail($"First archive failed. Status: {firstArchive.StatusCode}. Body: {await firstArchive.Content.ReadAsStringAsync()}");

        // Act — archive again
        var response = await adminClient.PostAsync($"/api/programs/{programId}/archive", null);

        // Assert
        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task ArchiveProgram_StoreManager_Returns403()
    {
        // Arrange
        var adminClient = await CreateAdminClientAsync();
        var programId = await CreateProgramAsync(adminClient);

        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var (smToken, _) = await _factory.RegisterUserAsync(
            client, $"sm-arch-{Guid.NewGuid()}@test.test", "Aa1234567@", "SM", "store_manager", adminToken);
        var smClient = _factory.CreateAuthenticatedClient(smToken);

        // Act
        var response = await smClient.PostAsync($"/api/programs/{programId}/archive", null);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
}
