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
        // Arrange
        var user = MakeUser("admin");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.True(result);
    }

    // ─── DB-Dependent Tests (Area Manager) ────────────────────────────────────

    [Fact]
    public async Task CanDelegate_AreaManager_ReturnsTrue_IfInJunction()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();


            db.Stores.Add(new Store { Id = storeId, Name = "Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            // Profile has different AreaId to prove junction wins
            db.Profiles.Add(new Profile { Id = userId, FullName = "Area Mgr Diff", Email = "am_diff@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

            // Add junction row
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = userId, StoreId = storeId });
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

        // Assert — Expect True because junction exists. Fails until code updated.
        Assert.True(result);
    }

    [Fact]
    public async Task CanDelegate_AreaManager_ReturnsFalse_IfNotInJunction()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            db.Stores.Add(new Store { Id = storeId, Name = "Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Profiles.Add(new Profile { Id = userId, FullName = "Area Mgr Diff", Email = "am_diff2@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

            // NO junction row inserted
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

        // Assert — Expect False because NO junction exists.
        // Fails right now because current code allows access since AreaIds match.
        Assert.False(result);
    }

    // ─── Negative Gate ────────────────────────────────────────────────────────

    [Fact]
    public void CanDelegate_Auditor_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser("auditor");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    [Fact]
    public void CanDelegate_StoreManager_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser("store_manager");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    // ─── Boundary / Empty State ───────────────────────────────────────────────

    [Fact]
    public void CanDelegate_NoRoleClaim_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser(null);

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    [Theory]
    [InlineData("")]
    [InlineData("superadmin")]
    [InlineData("ADMIN")]
    [InlineData("Area_Manager")]
    public void CanDelegate_UnrecognizedRole_ReturnsFalse(string role)
    {
        // Arrange
        var user = MakeUser(role);

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    // ─── Resource Scope Tests (CanAccessAsync) ────────────────────────────────

    [Fact]
    public async Task CanAccessAsync_Admin_ReturnsTrue_RegardlessOfScope()
    {
        // Arrange
        var user = MakeUser("admin");
        var scope = new ResourceScope(OwnerId: Guid.NewGuid());

        // Act
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);

        // Assert
        Assert.True(result);
    }

    [Fact]
    public async Task CanAccessAsync_AuditorIsOwner_ReturnsTrue()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var user = MakeUser("auditor", userId);
        var scope = new ResourceScope(OwnerId: userId);

        // Act
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);

        // Assert
        Assert.True(result);
    }

    [Fact]
    public async Task CanAccessAsync_AuditorIsNotOwner_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser("auditor", Guid.NewGuid());
        var scope = new ResourceScope(OwnerId: Guid.NewGuid());

        // Act
        var result = await AccessGuard.CanAccessAsync(user, scope, null!, default);

        // Assert
        Assert.False(result);
    }

    [Fact]
    public async Task CanAccessAsync_AreaManager_ReturnsTrue_IfInJunction()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            db.Stores.Add(new Store { Id = storeId, Name = "Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Profiles.Add(new Profile { Id = userId, FullName = "Area Mgr Unit", Email = "am_unit@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

            // Add junction row
            db.ProfileStoreAssignments.Add(new ProfileStoreAssignment { ProfileId = userId, StoreId = storeId });
            await db.SaveChangesAsync();
        }

        var user = MakeUser("area_manager", userId);

        // Act
        bool result;
        using (var actScope = _fixture.Services.CreateScope())
        {
            var db = actScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            result = await AccessGuard.CanAccessAsync(user, new ResourceScope(StoreId: storeId), db, default);
        }

        // Assert
        Assert.True(result);
    }

    [Fact]
    public async Task CanAccessAsync_AreaManager_ReturnsFalse_IfNotInJunction()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using (var scope = _fixture.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            db.Stores.Add(new Store { Id = storeId, Name = "Store A", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
            db.Profiles.Add(new Profile { Id = userId, FullName = "Area Mgr Unit2", Email = "am_unit2@test.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

            // NO junction row inserted
            await db.SaveChangesAsync();
        }

        var user = MakeUser("area_manager", userId);

        // Act
        bool result;
        using (var actScope = _fixture.Services.CreateScope())
        {
            var db = actScope.ServiceProvider.GetRequiredService<Common.Persistence.AppDbContext>();
            result = await AccessGuard.CanAccessAsync(user, new ResourceScope(StoreId: storeId), db, default);
        }

        // Assert — Expect False because NO junction exists.
        // Fails right now because current code allows access since AreaIds match.
        Assert.False(result);
    }
}
