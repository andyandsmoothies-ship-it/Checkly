using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using System.Threading;
using System.Threading.Tasks;
using System;

namespace Checkly.Api.Tests.Features.Notifications;

/// <summary>
/// ATDD acceptance suite for DistributedLockManager — Slice 1 (Thundering Herd Fix).
///
/// L1: First caller acquires lock → criticalSection executes → returns true
/// L2: Second caller (same scope string, first lock active) → returns false
/// L3: Different scope strings → both callers can acquire simultaneously
/// L4: FNV-1a hash is stable (same input → same output across calls)
/// L5: FNV-1a hash differentiates common namespaces (no obvious collision)
/// L6: After first call completes (transaction committed, lock released), a new caller can acquire it
/// Gap1: TryExecuteInLockAsync_WithNullOrEmptyScope_ThrowsArgumentException
/// Gap2: TryExecuteInLockAsync_CancellationRequested_ThrowsOperationCanceledException
/// </summary>
[Trait("Category", "DistributedLock")]
[Collection("ApiCollection")]
public class DistributedLockManagerTests : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private readonly TestWebApplicationFactory _fixture;
    private IServiceProvider _sp = null!;

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

    // ── L1: Happy path — first caller acquires and executes ─────────────────

    [Fact]
    public async Task TryExecuteInLock_FirstCaller_ReturnsTrueAndExecutes()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();
        var executed = false;

        // Act
        var result = await lockManager.TryExecuteInLockAsync(
            db,
            "Checkly.Test.L1",
            _ => { executed = true; return Task.CompletedTask; },
            CancellationToken.None);

        // Assert: lock acquired, delegate ran
        Assert.True(result);
        Assert.True(executed);
    }

    // ── L2: Second caller (same scope, first lock still held) → false ────────
    //
    // Pattern: Pod A holds the lock via a delegate that waits on a semaphore.
    // Pod B tries to acquire the same scope from a different DB scope.
    // Pod B must receive false while Pod A still holds the lock.
    // Then Pod A's delegate completes, releasing the lock normally.

    [Fact]
    public async Task TryExecuteInLock_SameScopeSecondCaller_ReturnsFalse()
    {
        // Arrange
        using var scopeA = _sp.CreateScope();
        var dbA = scopeA.ServiceProvider.GetRequiredService<AppDbContext>();

        using var scopeB = _sp.CreateScope();
        var dbB = scopeB.ServiceProvider.GetRequiredService<AppDbContext>();

        var lockManager = new DistributedLockManager();

        // A gate that keeps Pod A's delegate alive while Pod B attempts
        using var podAIsReady = new SemaphoreSlim(0, 1);
        using var podACanFinish = new SemaphoreSlim(0, 1);

        // Pod A: hold the lock, signal readiness, then wait for permission to release
        var podATask = lockManager.TryExecuteInLockAsync(
            dbA,
            "Checkly.Test.L2",
            async _ =>
            {
                podAIsReady.Release();          // Signal: lock is now held
                await podACanFinish.WaitAsync(); // Hold until Pod B has tried
            },
            CancellationToken.None);

        // Wait until Pod A has actually acquired the lock
        await podAIsReady.WaitAsync();

        // Act: Pod B tries to acquire the same lock scope — must be denied
        var podBResult = await lockManager.TryExecuteInLockAsync(
            dbB,
            "Checkly.Test.L2",
            _ => Task.CompletedTask,
            CancellationToken.None);

        // Release Pod A
        podACanFinish.Release();
        var podAResult = await podATask;

        // Assert: Pod A got it, Pod B was denied
        Assert.True(podAResult);
        Assert.False(podBResult);
    }

    // ── L3: Different scopes don't conflict ──────────────────────────────────

    [Fact]
    public async Task TryExecuteInLock_DifferentScopes_BothSucceed()
    {
        // Arrange
        using var scope1 = _sp.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();

        using var scope2 = _sp.CreateScope();
        var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act: run concurrently on different scope strings
        var task1 = lockManager.TryExecuteInLockAsync(db1, "Checkly.Test.L3.ServiceA", _ => Task.CompletedTask, CancellationToken.None);
        var task2 = lockManager.TryExecuteInLockAsync(db2, "Checkly.Test.L3.ServiceB", _ => Task.CompletedTask, CancellationToken.None);

        var results = await Task.WhenAll(task1, task2);

        // Assert: both acquired (different keys — no conflict)
        Assert.True(results[0]);
        Assert.True(results[1]);
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

    // ── L6: After completion, lock is released — new caller acquires ─────────

    [Fact]
    public async Task TryExecuteInLock_AfterFirstCompletes_NewCallerSucceeds()
    {
        // Arrange: Pod A acquires, runs delegate, transaction commits (lock auto-released)
        using var scope1 = _sp.CreateScope();
        var db1 = scope1.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        var firstResult = await lockManager.TryExecuteInLockAsync(
            db1,
            "Checkly.Test.L6",
            _ => Task.CompletedTask, // delegate completes → transaction commits → lock released
            CancellationToken.None);

        Assert.True(firstResult); // Pod A acquired

        // Act: new caller on a new scope should now acquire successfully
        using var scope2 = _sp.CreateScope();
        var db2 = scope2.ServiceProvider.GetRequiredService<AppDbContext>();

        var secondResult = await lockManager.TryExecuteInLockAsync(
            db2,
            "Checkly.Test.L6",
            _ => Task.CompletedTask,
            CancellationToken.None);

        // Assert: Pod B also acquired (lock was released by Pod A's transaction commit)
        Assert.True(secondResult);
    }

    // ── Gap1: Null/Empty Scope Argument Validation ───────────────────────────

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData(null)]
    public async Task TryExecuteInLock_WithNullOrEmptyScope_ThrowsArgumentException(string? invalidScope)
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act & Assert
        await Assert.ThrowsAnyAsync<ArgumentException>(() =>
            lockManager.TryExecuteInLockAsync(db, invalidScope!, _ => Task.CompletedTask, CancellationToken.None));
    }

    // ── Gap2: CancellationRequested Throws ───────────────────────────────────

    [Fact]
    public async Task TryExecuteInLock_CancellationRequested_ThrowsOperationCanceledException()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();
        using var cts = new CancellationTokenSource();
        cts.Cancel(); // pre-cancel the token

        // Act & Assert
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() =>
            lockManager.TryExecuteInLockAsync(db, "Checkly.Test.Gap2", _ => Task.CompletedTask, cts.Token));
    }

    // ── Gap3: Execution Timeout ─────────────────────────────────────────────

    [Fact]
    public async Task TryExecuteInLock_ExecutionTimeoutReached_ReturnsFalseGracefully()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();

        // Act: Set the timeout to 200 milliseconds, and let the critical section wait for 1 second
        var result = await lockManager.TryExecuteInLockAsync(
            db,
            "Checkly.Test.Gap3",
            async timeoutToken =>
            {
                await Task.Delay(1000, timeoutToken);
            },
            CancellationToken.None,
            TimeSpan.FromMilliseconds(200));

        // Assert: Return false due to timeout rather than throwing
        Assert.False(result);
    }

    // ── Gap4: Parent token cancellation mid-run ─────────────────────────────

    [Fact]
    public async Task TryExecuteInLock_ParentCancellationRequestedDuringRun_ThrowsOperationCanceledException()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var lockManager = new DistributedLockManager();
        using var cts = new CancellationTokenSource();

        // Act & Assert
        await Assert.ThrowsAnyAsync<OperationCanceledException>(async () =>
        {
            await lockManager.TryExecuteInLockAsync(
                db,
                "Checkly.Test.Gap4",
                async _ =>
                {
                    cts.Cancel(); // Cancel mid-execution
                    await Task.Delay(500, cts.Token);
                },
                cts.Token,
                TimeSpan.FromSeconds(5));
        });
    }
}
