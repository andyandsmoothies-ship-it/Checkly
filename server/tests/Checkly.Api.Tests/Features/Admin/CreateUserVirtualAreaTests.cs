using System;
using System.Net;
using System.Net.Http.Json;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Features.Admin;

[Trait("Category", "Admin")]
public class CreateUserVirtualAreaTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public CreateUserVirtualAreaTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public async Task TC_3_7_CreateUser_AM_NoLongerFailsS10_WhenAreaOccupied()
    {
        // TC-3.7: (Parity) CreateUser for AM no longer fails S10 when area occupied
        using var client = _factory.CreateClient();
        var adminToken = await _factory.LoginBootstrapAdminAsync(client);
        var authClient = _factory.CreateAuthenticatedClient(adminToken);

        var areaId = Guid.NewGuid();
        using (var scope = _factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = $"Occupied_{areaId}" });
            await db.SaveChangesAsync();
        }

        // Occupy the area with another user (legacy style AreaId assignment)
        var (_, occupantId) = await _factory.RegisterUserAsync(client, $"occupant_create_{Guid.NewGuid()}@test.com", "Pass123!", "Occupant", "area_manager", adminToken);
        var occupantRequest = new { role = "area_manager", areaId = areaId };
        await authClient.PutAsJsonAsync($"/api/admin/users/{occupantId}", occupantRequest);

        // Act: try to create a new AM user in the same area
        var request = new
        {
            email = $"newcomer_create_{Guid.NewGuid()}@test.com",
            fullName = "Newcomer AM",
            role = "area_manager",
            password = "Password123!",
            areaId = areaId // the legacy field
        };

        var response = await authClient.PostAsJsonAsync("/api/admin/users", request);

        // Assert
        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
