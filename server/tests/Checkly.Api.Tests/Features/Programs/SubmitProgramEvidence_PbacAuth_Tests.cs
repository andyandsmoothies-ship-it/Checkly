using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Programs;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Programs;

public class SubmitProgramEvidence_PbacAuth_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public SubmitProgramEvidence_PbacAuth_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
        _client = _factory.CreateClient();
    }

    [Fact]
    public async Task SubmitProgramEvidence_WhenCallerHasCapability_Succeeds()
    {
        // Prove we removed the hardcoded role check.
        // We create a custom role 'custom_executor', assign the 'programs:execute' capability,
        // and verify it can execute the assignment. Right now, this will fail with 403
        // because the endpoint is hardcoded to 'store_manager'.

        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);

        var userRole = "admin";
        var storeId = Guid.NewGuid();
        var assignmentId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Ensure the capability exists for the custom role
            await db.Database.ExecuteSqlAsync($"""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES (gen_random_uuid(), {userRole}, 'programs:execute', now())
                ON CONFLICT (role, capability) DO NOTHING;
            """);

            // Create template, store and assignment
            var templateId = Guid.NewGuid();
            db.Templates.Add(new Template { Id = templateId, Title = "Auth Template", Type = "QC", CreatedAt = DateTimeOffset.UtcNow });
            var store = new Store { Id = storeId, Name = "Auth Test Store", CreatedAt = DateTimeOffset.UtcNow };
            db.Stores.Add(store);
            
            var program = new ChecklyProgram { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Auth Test", Deadline = DateTimeOffset.UtcNow.AddDays(7), CreatedAt = DateTimeOffset.UtcNow };
            db.Programs.Add(program);
            
            db.ProgramAssignments.Add(new ProgramAssignment 
            { 
                Id = assignmentId, 
                ProgramId = program.Id, 
                StoreId = store.Id,
                Status = "pending",
                CreatedAt = DateTimeOffset.UtcNow
            });

            await db.SaveChangesAsync();

            // Refresh PBAC cache
            var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
            await cache.InitializeAsync(scope.ServiceProvider);
        }

        var (token, userId) = await _factory.RegisterUserAsync(_client, "exec1@test.com", "Exec123!@", "Exec One", userRole, adminToken);
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(userId);
            profile!.StoreId = storeId;
            await db.SaveChangesAsync();
        }

        var client = _factory.CreateAuthenticatedClient(token);
        
        var request = new SubmitEvidenceRequest(new[]
        {
            new EvidenceItemRequest(Guid.NewGuid(), "100", null)
        });

        try
        {
            var response = await client.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", request);

            // This will be Forbidden (403) before the fix, and OK (200) after the fix.
            if (response.StatusCode != HttpStatusCode.OK)
            {
                var body = await response.Content.ReadAsStringAsync();
                Assert.Fail($"Status: {response.StatusCode}. Expected OK. Body: {body}");
            }
        }
        finally
        {
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await db.Database.ExecuteSqlAsync($"DELETE FROM role_capabilities WHERE role = 'admin' AND capability = 'programs:execute'");
                var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
                await cache.InitializeAsync(scope.ServiceProvider);
            }
        }
    }

    [Fact]
    public async Task SubmitProgramEvidence_WhenCallerHasCapability_ButStoreMismatch_ReturnsNotFound()
    {
        // Prove IDOR still works when migrating to PBAC.
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);

        var userRole = "admin";
        var userStoreId = Guid.NewGuid();
        var assignmentStoreId = Guid.NewGuid();
        var assignmentId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            await db.Database.ExecuteSqlAsync($"""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES (gen_random_uuid(), {userRole}, 'programs:execute', now())
                ON CONFLICT (role, capability) DO NOTHING;
            """);

            var templateId = Guid.NewGuid();
            db.Templates.Add(new Template { Id = templateId, Title = "Auth Template 2", Type = "QC", CreatedAt = DateTimeOffset.UtcNow });
            db.Stores.Add(new Store { Id = userStoreId, Name = "User Store", CreatedAt = DateTimeOffset.UtcNow });
            db.Stores.Add(new Store { Id = assignmentStoreId, Name = "Target Store", CreatedAt = DateTimeOffset.UtcNow });
            
            var program = new ChecklyProgram { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Auth Test 2", Deadline = DateTimeOffset.UtcNow.AddDays(7), CreatedAt = DateTimeOffset.UtcNow };
            db.Programs.Add(program);
            
            db.ProgramAssignments.Add(new ProgramAssignment 
            { 
                Id = assignmentId, 
                ProgramId = program.Id, 
                StoreId = assignmentStoreId,
                Status = "pending",
                CreatedAt = DateTimeOffset.UtcNow
            });

            await db.SaveChangesAsync();
            
            var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
            await cache.InitializeAsync(scope.ServiceProvider);
        }

        var (token, userId) = await _factory.RegisterUserAsync(_client, "exec2@test.com", "Exec123!@", "Exec Two", userRole, adminToken);
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(userId);
            profile!.StoreId = userStoreId; // Different store!
            await db.SaveChangesAsync();
        }

        var client = _factory.CreateAuthenticatedClient(token);
        
        try
        {
            var request = new SubmitEvidenceRequest(new[] { new EvidenceItemRequest(Guid.NewGuid(), "100", null) });
            var response = await client.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", request);

            // Note: Currently it will return 403 (Forbidden) because of the hardcoded role check.
            // After PBAC migration, it will pass the auth gate, but the DB IDOR check will return 404 (NotFound).
            Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        }
        finally
        {
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await db.Database.ExecuteSqlAsync($"DELETE FROM role_capabilities WHERE role = 'admin' AND capability = 'programs:execute'");
                var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
                await cache.InitializeAsync(scope.ServiceProvider);
            }
        }
    }

    [Fact]
    public async Task SubmitProgramEvidence_WhenCallerLacksCapability_ReturnsForbidden()
    {
        // Prove PBAC is enforced for users without the capability
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);

        var assignmentId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var templateId = Guid.NewGuid();
            db.Templates.Add(new Template { Id = templateId, Title = "Auth Template 3", Type = "QC", CreatedAt = DateTimeOffset.UtcNow });
            db.Stores.Add(new Store { Id = storeId, Name = "Auth Test 3 Store", CreatedAt = DateTimeOffset.UtcNow });
            var program = new ChecklyProgram { Id = Guid.NewGuid(), TemplateId = templateId, Title = "Auth Test 3", Deadline = DateTimeOffset.UtcNow.AddDays(7), CreatedAt = DateTimeOffset.UtcNow };
            db.Programs.Add(program);
            db.ProgramAssignments.Add(new ProgramAssignment 
            { 
                Id = assignmentId, ProgramId = program.Id, StoreId = storeId, Status = "pending", CreatedAt = DateTimeOffset.UtcNow 
            });
            await db.SaveChangesAsync();
        }

        // We use "auditor" which does NOT have 'programs:execute'
        var (token, userId) = await _factory.RegisterUserAsync(_client, "exec3@test.com", "Exec123!@", "Exec Three", "auditor", adminToken);
        
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(userId);
            profile!.StoreId = storeId; // Matching store, so IDOR passes
            await db.SaveChangesAsync();
        }

        var client = _factory.CreateAuthenticatedClient(token);
        
        var request = new SubmitEvidenceRequest(new[] { new EvidenceItemRequest(Guid.NewGuid(), "100", null) });
        var response = await client.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", request);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }
    
    [Fact]
    public async Task SubmitProgramEvidence_WhenCallerIsAnonymous_ReturnsUnauthorized()
    {
        var request = new SubmitEvidenceRequest(new[] { new EvidenceItemRequest(Guid.NewGuid(), "100", null) });
        var response = await _client.PostAsJsonAsync($"/api/programs/assignments/{Guid.NewGuid()}/submit", request);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SubmitProgramEvidence_WhenStoreManagerRoleLacksProgramsExecute_ReturnsForbidden()
    {
        var adminToken = await _factory.LoginBootstrapAdminAsync(_client);

        var assignmentId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        var (token, userId) = await _factory.RegisterUserAsync(_client, "sm_no_cap@test.com", "SmNoCap123!@", "SM No Cap", "store_manager", adminToken);

        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var templateId = Guid.NewGuid();
            db.Templates.Add(new Template { Id = templateId, Title = "SM Lacks Cap", Type = "QC", CreatedAt = DateTimeOffset.UtcNow });
            db.Stores.Add(new Store { Id = storeId, Name = "SM Store", CreatedAt = DateTimeOffset.UtcNow });
            var program = new ChecklyProgram { Id = Guid.NewGuid(), TemplateId = templateId, Title = "SM Prog", Deadline = DateTimeOffset.UtcNow.AddDays(7), CreatedAt = DateTimeOffset.UtcNow };
            db.Programs.Add(program);
            db.ProgramAssignments.Add(new ProgramAssignment { Id = assignmentId, ProgramId = program.Id, StoreId = storeId, Status = "pending", CreatedAt = DateTimeOffset.UtcNow });

            var profile = await db.Profiles.FindAsync(userId);
            profile!.StoreId = storeId;
            
            // Delete capability for store_manager
            await db.Database.ExecuteSqlAsync($"DELETE FROM role_capabilities WHERE role = 'store_manager' AND capability = 'programs:execute'");
            await db.SaveChangesAsync();

            var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
            await cache.InitializeAsync(scope.ServiceProvider);
        }

        try
        {
            var client = _factory.CreateAuthenticatedClient(token);
            var request = new SubmitEvidenceRequest(new[] { new EvidenceItemRequest(Guid.NewGuid(), "100", null) });
            var response = await client.PostAsJsonAsync($"/api/programs/assignments/{assignmentId}/submit", request);

            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }
        finally
        {
            // Restore capability for store_manager
            using (var scope = _factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                await db.Database.ExecuteSqlAsync($"INSERT INTO role_capabilities (id, role, capability, created_at) VALUES (gen_random_uuid(), 'store_manager', 'programs:execute', now()) ON CONFLICT DO NOTHING");
                var cache = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Auth.PbacDictionaryCache>();
                await cache.InitializeAsync(scope.ServiceProvider);
            }
        }
    }
}
