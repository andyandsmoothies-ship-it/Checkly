using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace Checkly.Api.Common.Persistence;

/// <summary>
/// Acquires a PostgreSQL advisory lock scoped to an EF Core database transaction,
/// then executes a caller-provided critical section inside that same strategy closure.
///
/// Key Design Decisions:
/// <list type="bullet">
/// <item>Uses <c>pg_try_advisory_xact_lock</c> — non-blocking, transaction-scoped (auto-released on commit/rollback).</item>
/// <item>Hash is computed via FNV-1a 64-bit for deterministic, stable key generation — NEVER string.GetHashCode().</item>
/// <item><see cref="AppDbContext"/> is received at the call site (not via constructor DI) to avoid scoped-into-singleton DI violation.</item>
/// <item>Returns <c>false</c> on lock denial OR transient DB fault (safe degradation — never crashes BackgroundService).</item>
/// <item>The caller's critical section runs INSIDE <c>CreateExecutionStrategy().ExecuteAsync()</c> — this is the only safe pattern
/// when a retrying execution strategy is configured globally. Exporting an open transaction outside the strategy closure
/// causes all subsequent EF queries on that context to throw <see cref="InvalidOperationException"/>.</item>
/// </list>
/// </summary>
public sealed class DistributedLockManager
{
    /// <summary>
    /// Attempts to acquire a named PostgreSQL advisory lock and, if successful,
    /// executes <paramref name="criticalSection"/> inside the same execution strategy closure.
    /// </summary>
    /// <param name="db">The EF Core DbContext for the current service scope.</param>
    /// <param name="lockScope">
    /// Human-readable lock namespace (e.g., <c>"Checkly.ReminderService"</c>).
    /// Internally hashed to a stable 64-bit integer using FNV-1a. Never use raw integers.
    /// </param>
    /// <param name="criticalSection">
    /// The work to execute while holding the lock. Runs inside the execution strategy closure.
    /// The transaction is committed automatically when this delegate completes successfully.
    /// </param>
    /// <param name="ct">Cancellation token — <see cref="OperationCanceledException"/> is re-thrown, not swallowed.</param>
    /// <returns>
    /// <c>true</c> if the lock was acquired and <paramref name="criticalSection"/> executed successfully.
    /// <c>false</c> if: (a) another pod holds the lock, or (b) a transient DB fault occurred.
    /// </returns>
    /// <exception cref="ArgumentException">Thrown if <paramref name="lockScope"/> is null, empty, or whitespace.</exception>
    /// <exception cref="OperationCanceledException">Re-thrown when the cancellation token is cancelled.</exception>
    public async Task<bool> TryExecuteInLockAsync(
        AppDbContext db,
        string lockScope,
        Func<CancellationToken, Task> criticalSection,
        CancellationToken ct = default)
    {
        // Gap1 guard: reject invalid scope strings immediately — before any DB round-trip.
        if (string.IsNullOrWhiteSpace(lockScope))
            throw new ArgumentException("Lock scope must be a non-empty, non-whitespace string.", nameof(lockScope));

        var lockKey = ComputeFnv1a64(lockScope);
        var executed = false;

        try
        {
            // CRITICAL PATTERN: All EF Core queries that occur while a transaction is open
            // MUST execute inside the same CreateExecutionStrategy().ExecuteAsync() closure
            // that opened the transaction. Exporting the transaction outside this closure
            // and running further EF queries in the caller will throw InvalidOperationException
            // because a new strategy instance sees a transaction it doesn't own.
            var strategy = db.Database.CreateExecutionStrategy();
            await strategy.ExecuteAsync(async () =>
            {
                await using var transaction = await db.Database.BeginTransactionAsync(ct);

                // EF Core 7+ SqlQuery<T> with column alias "Value" (required by EF Core scalar projection).
                // pg_try_advisory_xact_lock returns true if lock acquired, false if held by another session.
                // IMPORTANT: The column alias must be "Value" — EF Core maps scalar results to this name.
                var acquired = await db.Database
                    .SqlQuery<bool>($"SELECT pg_try_advisory_xact_lock({lockKey}) AS \"Value\"")
                    .SingleAsync(ct);

                if (!acquired)
                {
                    await transaction.RollbackAsync(ct);
                    return;
                }

                // Lock acquired: execute the caller's critical section inside this closure.
                // All EF Core queries in criticalSection run within this strategy + transaction scope.
                await criticalSection(ct);
                await transaction.CommitAsync(ct);
                executed = true;
            });
        }
        catch (OperationCanceledException)
        {
            throw; // Always re-throw — stoppingToken was cancelled, pod is shutting down.
        }
        catch (NpgsqlException)
        {
            // Transient DB fault (connection drop, timeout, socket reset).
            // Safe degradation: treat as "lock not acquired" — caller skips this tick gracefully.
            return false;
        }
        catch (DbUpdateException)
        {
            // EF Core wraps some transient errors in DbUpdateException.
            return false;
        }

        return executed;
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
}
