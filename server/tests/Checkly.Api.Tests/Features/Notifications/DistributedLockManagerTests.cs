using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using System.Threading;
using System.Threading.Tasks;
using System;
using Npgsql;

namespace Checkly.Api.Tests.Features.Notifications;

/// <summary>
/// ATDD acceptance suite for DistributedLockManager — Slice 1 (Thundering Herd Fix).
///
/// L1: First caller acquires lock → returns non-null IDistributedLock
/// L2: Second caller (same scope, same transaction open) → returns null
/// L3: Different scope strings → both callers can acquire simultaneously
/// L4: FNV-1a hash is stable (same input → same output across calls)
/// L5: FNV-1a hash differentiates common namespaces (no obvious collision)
/// L6: After dispose (commit), the lock is released — a new caller can acquire it
/// Gap1: TryAcquire_WithNullOrEmptyScope_ThrowsArgumentException
/// Gap2: TryAcquire_CancellationRequested_ThrowsOperationCanceledException
/// </summary>
[Trait("Category", "DistributedLock")]
[Collection("ApiCollection")]
public class DistributedLockManagerTests : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private readonly TestWebApplicationFactory _fixture;
    private IServiceProvider _sp = null!;
    // Using reflection since the type might not exist yet during ATDD red phase.
    // Wait, since I'm writing the ATDD tests, the type DOES NOT exist. 
    // It is up to the Builder to create DistributedLockManager.
    // However, I need to write the tests AS IF it exists, so it will fail to compile.
    // A compilation error is an "Infra" error according to ATDD gates, but wait!
    // If it doesn't compile, it's an infrastructure failure. 
    // Actually, "Business" failure in ATDD for missing classes is a compilation failure if I just write it.
    // If I can't even compile the test project, `dotnet test` fails with a build error, which is considered an Infra failure?
    // Wait, the ATDD quality gate says:
    // "✅ Business: The test fails at a domain assertion because the feature doesn't exist yet... "
    // "❌ Infra: The test fails at setup, auth, routing, serialization, or DB schema... build failure before tests even run."
    // Gate 1: "Are all NuGet/npm packages referenced in the test project's .csproj... Build failure before tests even run."
    // Ah. So if there's a build failure because the class is missing... wait, the ATDD workflow says: 
    // "For existing dependencies that are missing, IF discrepancy THEN Flag to user → STOP. Exception: If the plan explicitly defines a NET-NEW API route/feature to be built, do NOT flag its absence as an error. Your job is to write the failing test for it (Red Phase)."

    public DistributedLockManagerTests(TestWebApplicationFactory fixture)
    {
        _fixture = fixture;
    }

    public Task InitializeAsync()
    {
        _sp = _fixture.Services;
        _fixture.EnsureDatabaseCreated();
        return Task.CompletedTask;
    }

    public Task DisposeAsync() => Task.CompletedTask;

    // ── L1: Happy path — first caller acquires ───────────────────────────────

    [Fact]
    public async Task TryAcquire_FirstCaller_ReturnsNonNull()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act
        await using var lockHandle = await lockManager.TryAcquireAsync(db, "Checkly.Test.L1", CancellationToken.None);

        // Assert
        Assert.NotNull(lockHandle);
    }

    // ── L2: Second caller (same scope, lock still open) → null ───────────────

    [Fact]
    public async Task TryAcquire_SameScopeSecondCaller_ReturnsNull()
    {
        // Arrange: Pod A holds the lock via scope1
        using var scope1 = _sp.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();
        await using var lockHandle = await lockManager.TryAcquireAsync(db1, "Checkly.Test.L2", CancellationToken.None);
        Assert.NotNull(lockHandle); // Pod A acquired

        // Pod B uses a separate scope/connection — must be denied
        using var scope2 = _sp.CreateScope();
        var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var lockHandlePodB = await lockManager.TryAcquireAsync(db2, "Checkly.Test.L2", CancellationToken.None);

        // Assert
        Assert.Null(lockHandlePodB);
        // Cleanup: db2 has an open transaction from the failed attempt → rollback
        if (db2.Database.CurrentTransaction is not null)
            await db2.Database.CurrentTransaction.RollbackAsync();
    }

    // ── L3: Different scopes don't conflict ──────────────────────────────────

    [Fact]
    public async Task TryAcquire_DifferentScopes_BothAcquire()
    {
        // Arrange
        using var scope1 = _sp.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();

        using var scope2 = _sp.CreateScope();
        var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act
        await using var lock1 = await lockManager.TryAcquireAsync(db1, "Checkly.Test.L3.ServiceA", CancellationToken.None);
        await using var lock2 = await lockManager.TryAcquireAsync(db2, "Checkly.Test.L3.ServiceB", CancellationToken.None);

        // Assert: both acquired (different keys)
        Assert.NotNull(lock1);
        Assert.NotNull(lock2);
    }

    // ── L4: Hash stability ───────────────────────────────────────────────────

    [Fact]
    public void ComputeFnv1a64_SameInput_ProducesSameHash()
    {
        const string scope = "Checkly.ReminderService";
        
        // Arrange - Act
        var hash1 = DistributedLockManager.ComputeFnv1a64(scope);
        var hash2 = DistributedLockManager.ComputeFnv1a64(scope);
        var hash3 = DistributedLockManager.ComputeFnv1a64(scope);

        // Assert
        Assert.Equal(hash1, hash2);
        Assert.Equal(hash1, hash3);
    }

    // ── L5: Hash uniqueness for obvious names ────────────────────────────────

    [Fact]
    public void ComputeFnv1a64_DifferentInputs_ProduceDifferentHashes()
    {
        // Arrange - Act
        var hash1 = DistributedLockManager.ComputeFnv1a64("Checkly.ReminderService");
        var hash2 = DistributedLockManager.ComputeFnv1a64("Checkly.RetentionService");
        var hash3 = DistributedLockManager.ComputeFnv1a64("Checkly.ReportService");

        // Assert
        Assert.NotEqual(hash1, hash2);
        Assert.NotEqual(hash1, hash3);
        Assert.NotEqual(hash2, hash3);
    }

    // ── L6: Commit-on-dispose releases the lock ──────────────────────────────

    [Fact]
    public async Task TryAcquire_AfterDispose_LockReleased_NewCallerSucceeds()
    {
        // Arrange: Pod A acquires and immediately releases
        using var scope1 = _sp.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        var lockHandle = await lockManager.TryAcquireAsync(db1, "Checkly.Test.L6", CancellationToken.None);
        Assert.NotNull(lockHandle);
        await lockHandle.DisposeAsync(); // Commits transaction → lock released

        // Act: new caller on a new scope should now be able to acquire
        using var scope2 = _sp.CreateScope();
        var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();
        await using var lockHandle2 = await lockManager.TryAcquireAsync(db2, "Checkly.Test.L6", CancellationToken.None);

        // Assert
        Assert.NotNull(lockHandle2);
    }

    // ── Gap1: Null/Empty Scope Argument Validation ───────────────────────────

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public async Task TryAcquire_WithNullOrEmptyScope_ThrowsArgumentException(string invalidScope)
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act & Assert
        await Assert.ThrowsAnyAsync<ArgumentException>(() => 
            lockManager.TryAcquireAsync(db, invalidScope, CancellationToken.None));
    }

    // ── Gap2: CancellationRequested Throws ───────────────────────────────────

    [Fact]
    public async Task TryAcquire_CancellationRequested_ThrowsOperationCanceledException()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();
        using var cts = new CancellationTokenSource();
        cts.Cancel(); // pre-cancel the token

        // Act & Assert
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => 
            lockManager.TryAcquireAsync(db, "Checkly.Test.Gap2", cts.Token));
    }
}
