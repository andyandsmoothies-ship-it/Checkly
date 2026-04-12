using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;

namespace Checkly.Api.Common.Persistence;

/// <summary>
/// Acquires a PostgreSQL advisory lock scoped to an EF Core database transaction.
///
/// Key Design Decisions:
/// <list type="bullet">
/// <item>Uses <c>pg_try_advisory_xact_lock</c> — non-blocking, transaction-scoped (auto-released on commit/rollback).</item>
/// <item>Hash is computed via FNV-1a 64-bit for deterministic, stable key generation — NEVER string.GetHashCode().</item>
/// <item><see cref="AppDbContext"/> is received at the call site (not via constructor DI) to avoid scoped-into-singleton DI violation.</item>
/// <item>Returns null on lock denial OR transient DB fault (safe degradation — never crashes BackgroundService).</item>
/// <item>Caller must <c>await using</c> the result — <see cref="IDistributedLock.DisposeAsync"/> commits the transaction and releases the lock.</item>
/// </list>
/// </summary>
public sealed class DistributedLockManager
{
    /// <summary>
    /// Attempts to acquire a named PostgreSQL advisory lock within a new database transaction.
    /// </summary>
    /// <param name="db">The EF Core DbContext for the current service scope.</param>
    /// <param name="lockScope">
    /// Human-readable lock namespace (e.g., <c>"Checkly.ReminderService"</c>).
    /// Internally hashed to a stable 64-bit integer using FNV-1a. Never use raw integers.
    /// </param>
    /// <param name="ct">Cancellation token — <see cref="OperationCanceledException"/> is re-thrown, not swallowed.</param>
    /// <returns>
    /// An <see cref="IDistributedLock"/> (<see cref="IAsyncDisposable"/>) if acquired — commit + release on dispose.
    /// Returns <c>null</c> if: (a) another pod holds the lock, or (b) transient DB fault occurred.
    /// </returns>
    /// <exception cref="ArgumentException">Thrown if <paramref name="lockScope"/> is null, empty, or whitespace.</exception>
    /// <exception cref="OperationCanceledException">Re-thrown when the cancellation token is cancelled.</exception>
    public async Task<IDistributedLock?> TryAcquireAsync(
        AppDbContext db,
        string lockScope,
        CancellationToken ct = default)
    {
        // Gap1 guard: reject invalid scope strings immediately — before any DB round-trip.
        if (string.IsNullOrWhiteSpace(lockScope))
            throw new ArgumentException("Lock scope must be a non-empty, non-whitespace string.", nameof(lockScope));

        var lockKey = ComputeFnv1a64(lockScope);

        try
        {
            // IMPORTANT: NpgsqlRetryingExecutionStrategy does not support user-initiated transactions
            // unless they are wrapped inside CreateExecutionStrategy().ExecuteAsync().
            // We must capture the transaction from inside the strategy closure.
            // Pattern: see VoidSubmission.HandleAsync and Submissions GEMINI.override.md.
            IDbContextTransaction? capturedTransaction = null;
            bool acquired = false;

            var strategy = db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                capturedTransaction = await db.Database.BeginTransactionAsync(ct);

                // EF Core 7+ SqlQuery<T> with column alias "Value" (required by EF Core scalar projection).
                // pg_try_advisory_xact_lock returns true if lock acquired, false if held by another session.
                // IMPORTANT: The column alias must be "Value" — EF Core maps scalar results to this name.
                acquired = await db.Database
                    .SqlQuery<bool>($"SELECT pg_try_advisory_xact_lock({lockKey}) AS \"Value\"")
                    .SingleAsync(ct);

                if (!acquired)
                {
                    await capturedTransaction.RollbackAsync(ct);
                    capturedTransaction = null;
                }
            });

            if (!acquired || capturedTransaction is null)
                return null;

            return new AcquiredLock(capturedTransaction);
        }
        catch (OperationCanceledException)
        {
            throw; // Always re-throw — stoppingToken was cancelled, pod is shutting down.
        }
        catch (NpgsqlException)
        {
            // Transient DB fault (connection drop, timeout, socket reset).
            // Safe degradation: treat as "lock not acquired" — caller skips this tick gracefully.
            return null;
        }
        catch (DbUpdateException)
        {
            // EF Core wraps some transient errors in DbUpdateException.
            return null;
        }
    }

    /// <summary>
    /// Computes a stable, deterministic 64-bit integer from a string using the FNV-1a algorithm.
    /// </summary>
    /// <remarks>
    /// NEVER use <c>string.GetHashCode()</c> — it is intentionally randomized per-process in .NET
    /// (security feature against hash-flooding attacks). FNV-1a produces the same output for the same
    /// input across runtimes and server restarts, making it safe for PostgreSQL advisory lock keys.
    /// </remarks>
    internal static long ComputeFnv1a64(string input)
    {
        const ulong fnvPrime = 1099511628211UL;
        const ulong fnvOffsetBasis = 14695981039346656037UL;

        var hash = fnvOffsetBasis;
        foreach (var c in input)
        {
            // Process both bytes of the char (UTF-16 LE) to avoid aliasing between ASCII-range strings.
            hash ^= (byte)(c & 0xFF);
            hash *= fnvPrime;
            hash ^= (byte)(c >> 8);
            hash *= fnvPrime;
        }

        // Postgres bigint is signed int64. Cast without overflow check (wrapping is intentional and safe for hash purposes).
        return unchecked((long)hash);
    }

    /// <summary>
    /// Internal wrapper: commits the EF Core transaction on dispose, releasing the xact-scoped advisory lock.
    /// </summary>
    private sealed class AcquiredLock(IDbContextTransaction transaction) : IDistributedLock
    {
        public async ValueTask DisposeAsync()
        {
            await transaction.CommitAsync();
            await transaction.DisposeAsync();
        }
    }
}
