using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

[Collection("Sequential")]
public class CreateSubmissionSchedulingTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public CreateSubmissionSchedulingTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task CreateSubmission_StatusScheduled_WithLocalTime_ConvertsToUtcAndPersists()
    {
        // TC1: ScheduledAt mapping (Happy path, should accept local offset and not 500)
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var token = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "TZ Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "TZ Store", IsActive = true });
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(token);
        
        // Simulating the bug payload: DateTimeOffset with a +07:00 offset
        var localTimeWithOffset = new DateTimeOffset(2026, 4, 30, 10, 0, 0, TimeSpan.FromHours(7));
        
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            ScheduledAt = localTimeWithOffset
        };

        // Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);
        
        // Assert - If backend does not convert, Npgsql throws 500. We expect 201 Created.
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var dbSubmission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(dbSubmission);
        
        // The saved time should be perfectly matching the universal UTC equivalent.
        Assert.Equal(localTimeWithOffset.ToUniversalTime(), dbSubmission.ScheduledAt);
    }

    [Fact]
    public async Task CreateSubmission_StatusScheduled_AssignToAuditorId_CorrectlyDelegates()
    {
        // TC2: AssignToAuditorId Mapping 
        // Arrange
        using var scope = _fixture.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();

        var adminToken = await _fixture.LoginBootstrapAdminAsync(_fixture.CreateClient());
        var (_, adminUserId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "admindg_scheduling@test.com", "Aa1234567@", "Admin Delegate", "admin", adminToken);
        var (_, assigneeUserId) = await _fixture.RegisterUserAsync(_fixture.CreateClient(), "assignee_scheduling@test.com", "Aa1234567@", "Target Auditor", "auditor", adminToken);
        
        var templateId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        db.Templates.Add(new Template { Id = templateId, Title = "Delegate Template", Version = 1, IsActive = true });
        db.Stores.Add(new Store { Id = storeId, Name = "Delegate Store", IsActive = true });
        await db.SaveChangesAsync();

        var client = _fixture.CreateAuthenticatedClient(adminToken);
        
        var requestPayload = new
        {
            TemplateId = templateId,
            StoreId = storeId,
            Status = "scheduled",
            AssignToAuditorId = assigneeUserId, // Currently ignored by the backend
            ScheduledAt = DateTimeOffset.UtcNow.AddDays(1)
        };

        // Act
        var response = await client.PostAsJsonAsync($"/api/submissions", requestPayload);
        
        // Assert
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var submissionId = Guid.Parse(json.GetProperty("id").GetString()!);

        var dbSubmission = await db.Submissions.FirstOrDefaultAsync(s => s.Id == submissionId);
        Assert.NotNull(dbSubmission);
        
        // BUG VERIFICATION: The submission should belong to the assigneeUserId, NOT the admin's own ID.
        Assert.Equal(assigneeUserId, dbSubmission.AuditorId);
        
        // The AuditorName snapshot should also match the assignee.
        Assert.Equal("Target Auditor", dbSubmission.AuditorName);
    }
}
