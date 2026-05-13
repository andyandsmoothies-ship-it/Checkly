using System.Net.Http.Json;
using Xunit;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Features.Stores;

namespace Checkly.Api.Tests;

public class TestStoreFetch : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    public TestStoreFetch(TestWebApplicationFactory factory) => _factory = factory;

    [Fact]
    public async Task Can_Fetch_SM7_Stores()
    {
        var client = _factory.CreateClient();
        
        var (token, smId) = await _factory.RegisterUserAsync(client, "teststorefetch@checkly.test", "Password123!", "Test SM", "store_manager");
        
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
        
        // Wait, Checkly Go Vap doesn't exist in the test DB. Let's create a test store and assign it.
        var testStoreId = Guid.NewGuid();
        db.Stores.Add(new Common.Persistence.Entities.Store { Id = testStoreId, Name = "Test Store", IsActive = true, CreatedAt = DateTimeOffset.UtcNow });
        var userProfile = db.Profiles.Find(smId);
        userProfile!.StoreId = testStoreId; 
        db.SaveChanges();

        var smClient = _factory.CreateAuthenticatedClient(token);
        
        var response = await smClient.GetAsync("/api/stores");
        var content = await response.Content.ReadAsStringAsync();
        
        Console.WriteLine($"STATUS: {response.StatusCode}");
        Console.WriteLine($"CONTENT: {content}");
        
        Assert.True(response.IsSuccessStatusCode);
    }
}
