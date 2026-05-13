using System.Net.Http.Json;
using Xunit;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Features.Programs;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Tests;

public class TestAssignmentFetch : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    public TestAssignmentFetch(TestWebApplicationFactory factory) => _factory = factory;

    [Fact]
    public async Task SM_Can_Fetch_Sync_Submissions()
    {
        var storeId = Guid.NewGuid();
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Stores.Add(new Checkly.Api.Common.Persistence.Entities.Store { Id = storeId, Name = "Test Store", IsActive = true });
        await db.SaveChangesAsync();

        var client = _factory.CreateClient();
        var (token, userId) = await _factory.RegisterUserAsync(client, "smsync2@checkly.test", "Password123!", "Test SM", "store_manager");

        var profile = await db.Profiles.FindAsync(userId);
        profile!.StoreId = storeId;
        await db.SaveChangesAsync();

        var smClient = _factory.CreateAuthenticatedClient(token);
        
        var response = await smClient.GetAsync("/api/sync/submissions");
        var content = await response.Content.ReadAsStringAsync();
        
        Console.WriteLine($"STATUS: {response.StatusCode}");
        Console.WriteLine($"CONTENT: {content}");
        
        Assert.True(response.IsSuccessStatusCode);
    }
}
