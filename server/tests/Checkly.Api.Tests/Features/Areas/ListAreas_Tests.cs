using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Tests.Features.Areas;

public class ListAreas_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ListAreas_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task ListAreas_IncludesManagerName_WhenManagerIsAssigned()
    {
        // Arrange
        var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        // Create a manager
        var managerName = $"Test Manager {Guid.NewGuid()}";
        var managerUser = await _factory.RegisterUserAsync(client, $"am_{Guid.NewGuid()}@test.com", "Pass123!@", managerName, "area_manager", adminToken);

        // Create an area assigned to this manager
        var areaName = $"000_Test Area {Guid.NewGuid()}";
        var createAreaPayload = new { Name = areaName, ManagerId = managerUser.UserId };
        var createResponse = await authClient.PostAsJsonAsync("/api/areas", createAreaPayload);
        createResponse.EnsureSuccessStatusCode();
        var createdAreaDto = await createResponse.Content.ReadFromJsonAsync<AreaResponse>();
        var areaId = createdAreaDto!.Id;

        // Manually assign the area to the manager's profile, simulating what Admin UpdateUser would do
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var profile = await db.Profiles.FindAsync(managerUser.UserId);
            if (profile != null)
            {
                profile.AreaId = areaId;
                await db.SaveChangesAsync();
            }
        }

        // Act
        var response = await authClient.GetAsync("/api/areas");
        response.EnsureSuccessStatusCode();

        var pageResult = await response.Content.ReadFromJsonAsync<PagedResult<AreaResponse>>();
        
        // Assert
        Assert.NotNull(pageResult);
        Assert.NotNull(pageResult.Items);
        var createdArea = pageResult.Items.FirstOrDefault(a => a.Name == areaName);
        Assert.NotNull(createdArea);
        // Note: The previous implementation didn't expose ManagerId on AreaDto, it only exposed ManagerName.
        // Let's assert that ManagerName matches.
        Assert.Equal(managerName, createdArea.ManagerName); // This should pass before AND after refactor
    }

    private class PagedResult<T>
    {
        public List<T> Items { get; set; } = new();
        public int TotalCount { get; set; }
    }

    private class AreaResponse
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? ManagerName { get; set; }
    }
}
