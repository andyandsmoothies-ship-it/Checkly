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
