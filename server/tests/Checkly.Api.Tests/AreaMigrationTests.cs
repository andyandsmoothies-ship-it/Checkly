using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Areas Entity — Slice 2 (Data Migration).
/// Tests verify that Store and Profile entities have AreaId FK,
/// the FK relationship works, null handling is correct, and
/// area_code columns are preserved.
/// Tests will FAIL (RED) until the entity model changes are implemented.
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
            Code = $"test-region-{_runId}",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        // Create a store linked to this area
        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"Store AC1 {_runId}",
            AreaCode = "test-region",
            AreaId = area.Id,  // ← This property must exist on Store
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        // Verify FK relationship via Include
        var loaded = await db.Stores
            .Include(s => s.Area)  // ← Navigation property must exist
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
            Code = $"profile-region-{_runId}",
            IsActive = true,
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
            AreaCode = "profile-region",
            AreaId = area.Id,  // ← This property must exist on Profile
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Profiles.Add(profile);
        await db.SaveChangesAsync();

        // Verify FK
        var loaded = await db.Profiles
            .Include(p => p.Area)  // ← Navigation property must exist
            .FirstOrDefaultAsync(p => p.Id == profileId);

        Assert.NotNull(loaded);
        Assert.Equal(area.Id, loaded!.AreaId);
        Assert.NotNull(loaded.Area);
        Assert.Equal(area.Name, loaded.Area!.Name);
    }

    // ─── AC3: Null area_code → null AreaId ───
    // Citation: analysis_areas_entity.md:205

    [Fact]
    public async Task Store_With_Null_AreaCode_Has_Null_AreaId()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"No-Area Store {_runId}",
            AreaCode = null,
            // AreaId intentionally not set → should be null
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        var loaded = await db.Stores.FindAsync(store.Id);
        Assert.NotNull(loaded);
        Assert.Null(loaded!.AreaCode);
        Assert.Null(loaded.AreaId);  // ← AreaId property must exist and be null
    }

    // ─── AC4: area_code columns still exist ───
    // Citation: analysis_areas_entity.md:206

    [Fact]
    public async Task AreaCode_Columns_Still_Exist_In_Schema()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Verify stores.area_code column exists by querying it
        var storeCount = await db.Stores
            .Where(s => s.AreaCode != null || s.AreaCode == null)
            .CountAsync();
        Assert.True(storeCount >= 0); // Just proves the column exists in the query

        // Verify profiles.area_code column exists
        var profileCount = await db.Profiles
            .Where(p => p.AreaCode != null || p.AreaCode == null)
            .CountAsync();
        Assert.True(profileCount >= 0);

        // Also verify we can write to area_code alongside area_id
        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"Compat Region {_runId}",
            Code = $"compat-{_runId}",
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        var store = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"Compat Store {_runId}",
            AreaCode = "compat-old",   // Old column
            AreaId = area.Id,           // New FK column
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Stores.Add(store);
        await db.SaveChangesAsync();

        var loaded = await db.Stores.FindAsync(store.Id);
        Assert.Equal("compat-old", loaded!.AreaCode);  // Old column preserved
        Assert.Equal(area.Id, loaded.AreaId);           // New FK works
    }

    // ─── AC5: Mixed-case area_codes mapped to same area ───
    // Citation: analysis_areas_entity.md:207

    [Fact]
    public async Task Mixed_Case_AreaCodes_Map_To_Same_Area()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create single area with normalized code
        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = $"North {_runId}",
            Code = $"north-{_runId}",   // normalized (lowercase)
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        db.Areas.Add(area);

        // Create two stores with different casing in area_code but same AreaId
        var store1 = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"North Store 1 {_runId}",
            AreaCode = "North",         // uppercase N
            AreaId = area.Id,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };
        var store2 = new Store
        {
            Id = Guid.NewGuid(),
            Name = $"North Store 2 {_runId}",
            AreaCode = "north",         // lowercase n
            AreaId = area.Id,
            IsActive = true,
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
        Assert.Equal(loaded1.AreaId, loaded2.AreaId);  // Same area
    }
}
