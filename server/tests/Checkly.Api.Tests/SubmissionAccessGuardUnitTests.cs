using System.Security.Claims;
using AccessGuard = Checkly.Api.Common.ResourceAccessGuard;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests.Guards;

/// <summary>
/// Integration tests for SubmissionAccessGuard.CanDelegate.
/// Converted to use TestWebApplicationFactory to provide AppDbContext for AreaManager checks.
/// </summary>
public class SubmissionAccessGuardUnitTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _fixture;

    public SubmissionAccessGuardUnitTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
        _fixture.EnsureDatabaseCreated();
    }

    private static ClaimsPrincipal MakeUser(string? role, Guid? id = null)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, (id ?? Guid.NewGuid()).ToString())
        };
        if (role is not null)
            claims.Add(new Claim(ClaimTypes.Role, role));

        return new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
    }

    // ─── Happy Path ───────────────────────────────────────────────────────────

    [Fact]
    public void CanDelegate_Admin_ReturnsTrue()
    {
        var user = MakeUser("admin");
        var result = AccessGuard.CanDelegate(user);
        Assert.True(result);
    }

    // ─── DB-Dependent Tests (Area Manager) ────────────────────────────────────

    [Fact]
    public async Task CanDelegate_AreaManager_ReturnsTrue_IfInArea()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var areaId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            db.Areas.Add(new Area { Id = areaId, Name = "Same Area", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Stores.Add(new Store { Id = storeId, AreaId = areaId, Name = "Same Area Store", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Profiles.Add(new Profile { Id = userId, AreaId = areaId, FullName = "Area Mgr", Email = "am@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        var user = MakeUser("area_manager", userId);

        // Act
        bool result;
        using (var actScope = _fixture.Services.CreateScope())
        {
            var db = actScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            result = await AccessGuard.CanDelegateAsync(user, new ResourceScope(StoreId: storeId), db, default);
        }

        // Assert
        Assert.True(result);
    }

    [Fact]
    public async Task CanDelegate_AreaManager_ReturnsFalse_IfOutsideArea()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            var areaA = Guid.NewGuid();
            var areaB = Guid.NewGuid();
            db.Areas.Add(new Area { Id = areaA, Name = "Diff Area A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Areas.Add(new Area { Id = areaB, Name = "Diff Area B", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            
            db.Stores.Add(new Store { Id = storeId, AreaId = areaA, Name = "Diff Area Store", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Profiles.Add(new Profile { Id = userId, AreaId = areaB, FullName = "Area Mgr Diff", Email = "am_diff@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            await db.SaveChangesAsync();
        }

        var user = MakeUser("area_manager", userId);

        // Act
        bool result;
        using (var actScope = _fixture.Services.CreateScope())
        {
            var db = actScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            result = await AccessGuard.CanDelegateAsync(user, new ResourceScope(StoreId: storeId), db, default);
        }

        // Assert — GREEN: CanDelegateAsync checks DB, area mismatch → false.
        Assert.False(result);
    }

    // ─── Negative Gate ────────────────────────────────────────────────────────

    [Fact]
    public void CanDelegate_Auditor_ReturnsFalse()
    {
        var user = MakeUser("auditor");
        var result = AccessGuard.CanDelegate(user);
        Assert.False(result);
    }

    [Fact]
    public void CanDelegate_StoreManager_ReturnsFalse()
    {
        var user = MakeUser("store_manager");
        var result = AccessGuard.CanDelegate(user);
        Assert.False(result);
    }

    // ─── Boundary / Empty State ───────────────────────────────────────────────

    [Fact]
    public void CanDelegate_NoRoleClaim_ReturnsFalse()
    {
        var user = MakeUser(null);
        var result = AccessGuard.CanDelegate(user);
        Assert.False(result);
    }

    [Theory]
    [InlineData("")]
    [InlineData("superadmin")]
    [InlineData("ADMIN")]
    [InlineData("Area_Manager")]
    public void CanDelegate_UnrecognizedRole_ReturnsFalse(string role)
    {
        var user = MakeUser(role);
        var result = AccessGuard.CanDelegate(user);
        Assert.False(result);
    }

    // ─── Resource Scope Tests (CanAccessAsync) ────────────────────────────────

    [Fact]
    public async Task CanAccessAsync_Admin_ReturnsTrue_RegardlessOfScope()
    {
        var user = MakeUser("admin");
        var scope = new ResourceScope(OwnerId: Guid.NewGuid());
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);
        Assert.True(result);
    }

    [Fact]
    public async Task CanAccessAsync_AuditorIsOwner_ReturnsTrue()
    {
        var userId = Guid.NewGuid();
        var user = MakeUser("auditor", userId);
        var scope = new ResourceScope(OwnerId: userId);
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);
        Assert.True(result);
    }

    [Fact]
    public async Task CanAccessAsync_AuditorIsNotOwner_ReturnsFalse()
    {
        var user = MakeUser("auditor", Guid.NewGuid());
        var scope = new ResourceScope(OwnerId: Guid.NewGuid());
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);
        Assert.False(result);
    }
}
