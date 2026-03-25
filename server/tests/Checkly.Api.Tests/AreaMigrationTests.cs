using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Areas Entity — Slice 2 (Data Migration).
/// Tests verify that Store and Profile entities have AreaId FK,
/// the FK relationship works, and null handling is correct.
/// Updated for Slice 5: area_code columns have been dropped.
/// </summary>
public class AreaMigrationTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public AreaMigrationTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    // ─── AC1: Store entity has AreaId FK ───
    // Citation: analysis_areas_entity.md:199

    [Fact]
    public async Task Store_Has_AreaId_FK_Pointing_To_Area()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create an area
        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"Test Region {_runId}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        // Create a store linked to this area
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"Store AC1 {_runId}",
            AreaId = area.Id,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        // Verify FK relationship via Include
        var loaded = await db.Stores
            .Include(s => s.Area)
            .FirstOrDefaultAsync(s => s.Id == store.Id);

        Assert.NotNull(loaded);
        Assert.Equal(area.Id, loaded!.AreaId);
        Assert.NotNull(loaded.Area);
        Assert.Equal(area.Name, loaded.Area!.Name);
    }

    // ─── AC2: Profile entity has AreaId FK ───
    // Citation: analysis_areas_entity.md:199

    [Fact]
    public async Task Profile_Has_AreaId_FK_Pointing_To_Area()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create an area
        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"Profile Region {_runId}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        // Create a profile with AreaId
        var profileId = Guid.NewGuid();
        var profile = new Profile
        {
            Id = profileId,
            FullName = $"Test User {_runId}",
            Email = $"profile-ac2-{_runId}@test.test",
            AreaId = area.Id,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Profiles.Add(profile);
        await db.SaveChangesAsync();

        // Verify FK
        var loaded = await db.Profiles
            .Include(p => p.Area)
            .FirstOrDefaultAsync(p => p.Id == profileId);

        Assert.NotNull(loaded);
        Assert.Equal(area.Id, loaded!.AreaId);
        Assert.NotNull(loaded.Area);
        Assert.Equal(area.Name, loaded.Area!.Name);
    }

    // ─── AC3: Null AreaId handled correctly ───
    // Citation: analysis_areas_entity.md:205

    [Fact]
    public async Task Store_With_No_Area_Has_Null_AreaId()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"No-Area Store {_runId}",
            // AreaId intentionally not set → should be null
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        var loaded = await db.Stores.FindAsync(store.Id);
        Assert.NotNull(loaded);
        Assert.Null(loaded!.AreaId);
    }

    // ─── AC4: area_code columns have been dropped (Slice 5) ───
    // Original: tested area_code columns still exist
    // Updated: area_code columns dropped in DropAreaCodeColumns migration

    [Fact]
    public async Task AreaId_FK_Works_Without_AreaCode_Column()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"Compat Region {_runId}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"Compat Store {_runId}",
            AreaId = area.Id,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        var loaded = await db.Stores
            .Include(s => s.Area)
            .FirstOrDefaultAsync(s => s.Id == store.Id);
        Assert.Equal(area.Id, loaded!.AreaId);
        Assert.Equal(area.Name, loaded.Area!.Name);
    }

    // ─── AC5: Multiple stores can point to same area ───
    // Citation: analysis_areas_entity.md:207

    [Fact]
    public async Task Multiple_Stores_Can_Point_To_Same_Area()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create single area
        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"North {_runId}",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        // Create two stores both pointing to the same area
        var store1 = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"North Store 1 {_runId}",
            AreaId = area.Id,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        var store2 = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"North Store 2 {_runId}",
            AreaId = area.Id,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.AddRange(store1, store2);
        await db.SaveChangesAsync();

        // Both stores should point to the same area
        var loaded1 = await db.Stores.FindAsync(store1.Id);
        var loaded2 = await db.Stores.FindAsync(store2.Id);

        Assert.Equal(area.Id, loaded1!.AreaId);
        Assert.Equal(area.Id, loaded2!.AreaId);
        Assert.Equal(loaded1.AreaId, loaded2.AreaId);
    }
}
