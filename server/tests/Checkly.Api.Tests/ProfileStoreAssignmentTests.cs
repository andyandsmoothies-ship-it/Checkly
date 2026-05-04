using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD: Slice 1 DB Foundation & Migration for ProfileStoreAssignment.
/// Tests will FAIL (RED - Compiler Error or DbException) until the foundation is implemented.
/// </summary>
public class ProfileStoreAssignmentTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private static readonly string _runId = Guid.NewGuid().ToString("N")[..8];

    public ProfileStoreAssignmentTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    private static string UniqueEmail(string prefix) => $"{prefix}-{_runId}@slice1.test";

    // ─── TC-01: Table Has Composite PK ───
    [Fact]
    public void Table_Has_Composite_PK()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // This will fail to compile if ProfileStoreAssignment is not defined
        var entityType = db.Model.FindEntityType(typeof(ProfileStoreAssignment));

        Assert.NotNull(entityType);

        var pk = entityType.FindPrimaryKey();
        Assert.NotNull(pk);
        Assert.Equal(2, pk.Properties.Count);

        var propertyNames = pk.Properties.Select(p => p.Name).ToList();
        Assert.Contains("ProfileId", propertyNames);
        Assert.Contains("StoreId", propertyNames);
    }

    // ─── TC-02: Cannot Insert Duplicate ProfileStore Pair ───
    [Fact]
    public async Task Cannot_Insert_Duplicate_ProfileStore_Pair()
    {
        var profileId = Guid.NewGuid();
        var storeId = Guid.NewGuid();

        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Create dummy profile and store just for FKs
        db.Profiles.Add(new Profile { Id = profileId, FullName = "A", Email = "a@a.com", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = storeId, Name = "S", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        // First insert should succeed
        var assignment1 = new ProfileStoreAssignment
        {
            ProfileId = profileId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Set<ProfileStoreAssignment>().Add(assignment1);
        await db.SaveChangesAsync();

        db.ChangeTracker.Clear(); // Test the DB constraint, not EF memory tracker

        // Second insert of same pair should fail
        var assignment2 = new ProfileStoreAssignment
        {
            ProfileId = profileId,
            StoreId = storeId,
            CreatedAt = DateTimeOffset.UtcNow
        };
        db.Set<ProfileStoreAssignment>().Add(assignment2);

        await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
    }

    // ─── TC-03, TC-04, TC-05, TC-08: Seed SQL Behavior ───
    // We execute the explicit SQL string defined in the plan since migrations run prior to our test data setup.
    [Fact]
    public async Task Seed_Converts_Existing_AM_AreaId_Links()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var area1Id = Guid.NewGuid();
        var storeAlphaId = Guid.NewGuid();
        var storeBetaId = Guid.NewGuid();
        var am1Id = Guid.NewGuid();
        var amNullId = Guid.NewGuid();
        var notAmId = Guid.NewGuid(); // Gap 1

        db.Areas.Add(new Area { Id = area1Id, Name = $"A1-{_runId}", Code = $"A1-{_runId}", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });

        db.Stores.AddRange(
            new Store { Id = storeAlphaId, AreaId = area1Id, Name = $"S1-{_runId}", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Store { Id = storeBetaId, AreaId = area1Id, Name = $"S2-{_runId}", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.Users.AddRange(
            new AppUser { Id = am1Id, UserName = UniqueEmail("am1"), Email = UniqueEmail("am1") },
            new AppUser { Id = amNullId, UserName = UniqueEmail("amNull"), Email = UniqueEmail("amNull") },
            new AppUser { Id = notAmId, UserName = UniqueEmail("notAm"), Email = UniqueEmail("notAm") }
        );

        db.Profiles.AddRange(
            new Profile { Id = am1Id, AreaId = area1Id, FullName = "AM1", Email = UniqueEmail("am1"), CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Profile { Id = amNullId, AreaId = null, FullName = "AM Null", Email = UniqueEmail("amNull"), CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
            new Profile { Id = notAmId, AreaId = area1Id, FullName = "Not AM", Email = UniqueEmail("notAm"), CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow }
        );

        db.AppUserRoles.AddRange(
            new UserRole { Id = Guid.NewGuid(), UserId = am1Id, Role = "area_manager", CreatedAt = DateTimeOffset.UtcNow },
            new UserRole { Id = Guid.NewGuid(), UserId = amNullId, Role = "area_manager", CreatedAt = DateTimeOffset.UtcNow },
            new UserRole { Id = Guid.NewGuid(), UserId = notAmId, Role = "auditor", CreatedAt = DateTimeOffset.UtcNow }
        );

        await db.SaveChangesAsync();

        // The expected SQL Seed from the implementation plan
        var sql = @"
            INSERT INTO profile_store_assignments (profile_id, store_id, created_at)
            SELECT p.id, s.id, now()
            FROM profiles p
            JOIN user_roles ur ON p.id = ur.user_id AND ur.role = 'area_manager'
            JOIN stores s ON p.area_id = s.area_id
            WHERE p.area_id IS NOT NULL
            ON CONFLICT DO NOTHING;
        ";

        await db.Database.ExecuteSqlRawAsync(sql);

        var assignments = await db.Set<ProfileStoreAssignment>()
            .Where(x => x.ProfileId == am1Id || x.ProfileId == amNullId || x.ProfileId == notAmId)
            .ToListAsync();

        // TC-03: AM1 should get StoreAlpha and StoreBeta
        Assert.Contains(assignments, a => a.ProfileId == am1Id && a.StoreId == storeAlphaId);
        Assert.Contains(assignments, a => a.ProfileId == am1Id && a.StoreId == storeBetaId);

        // TC-04: AM Null gets no rows
        Assert.DoesNotContain(assignments, a => a.ProfileId == amNullId);

        // TC-08: Not AM gets no rows despite having AreaId
        Assert.DoesNotContain(assignments, a => a.ProfileId == notAmId);

        // TC-05: Seed is Idempotent
        // Running it again shouldn't throw error
        await db.Database.ExecuteSqlRawAsync(sql);

        var assignmentsAfter = await db.Set<ProfileStoreAssignment>()
            .Where(x => x.ProfileId == am1Id)
            .ToListAsync();

        Assert.Equal(2, assignmentsAfter.Count);
    }

    // ─── TC-06: FK Cascade Profile Delete ───
    [Fact]
    public async Task FK_Cascade_Profile_Delete()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var pId = Guid.NewGuid();
        var sId = Guid.NewGuid();

        db.Profiles.Add(new Profile { Id = pId, FullName = "Del P", Email = UniqueEmail("delp"), CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = sId, Name = "Del S", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        db.Set<ProfileStoreAssignment>().Add(new ProfileStoreAssignment { ProfileId = pId, StoreId = sId, CreatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        // Clear tracker so EF Core doesn't throw InvalidOperationException
        db.ChangeTracker.Clear();

        // Delete profile
        var profile = new Profile { Id = pId };
        db.Profiles.Remove(profile);
        await db.SaveChangesAsync();

        var assignment = await db.Set<ProfileStoreAssignment>().FindAsync(pId, sId);
        Assert.Null(assignment); // Should be cascade deleted
    }

    // ─── TC-07: FK Restrict Store Delete ───
    [Fact]
    public async Task FK_Restrict_Store_Delete()
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var pId = Guid.NewGuid();
        var sId = Guid.NewGuid();

        db.Profiles.Add(new Profile { Id = pId, FullName = "Restrict P", Email = UniqueEmail("resp"), CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        db.Stores.Add(new Store { Id = sId, Name = "Restrict S", IsActive = true, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        db.Set<ProfileStoreAssignment>().Add(new ProfileStoreAssignment { ProfileId = pId, StoreId = sId, CreatedAt = DateTimeOffset.UtcNow });
        await db.SaveChangesAsync();

        // Clear the change tracker so EF Core doesn't throw InvalidOperationException locally
        db.ChangeTracker.Clear();

        // Attempting to delete the store should throw because of the RESTRICT FK
        var store = new Store { Id = sId };
        db.Stores.Remove(store);

        await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
    }
}
