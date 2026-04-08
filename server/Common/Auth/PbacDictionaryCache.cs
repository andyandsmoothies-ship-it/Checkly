using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// Singleton in-memory capability cache for PBAC.
/// Holds a Dictionary keyed by role string → set of capability strings.
///
/// Thread safety: _cache is declared volatile. Writes use Volatile.Write() for an
/// atomic reference swap so reader threads (GetCapabilities) always see a complete,
/// consistent dictionary — never a half-written one.
///
/// Loaded once on startup via InitializeAsync(). On live changes, the Postgres
/// LISTEN/NOTIFY listener (PbacCacheListenerService) calls InitializeAsync()
/// again, which atomically swaps in the fresh dictionary. No lock is needed.
/// </summary>
public sealed class PbacDictionaryCache
{
    // Non-volatile field — thread visibility is managed explicitly via Volatile.Write (writer)
    // and Volatile.Read (reader) rather than the volatile keyword. Combining volatile keyword
    // with Volatile.Write triggers CS0420 because passing ref to a volatile field strips
    // the volatile semantics. Explicit calls give us the same guarantee without the warning.
    private Dictionary<string, HashSet<string>> _cache = [];

    /// <summary>
    /// True once InitializeAsync has completed successfully.
    /// The CapabilityAuthorizationHandler denies all requests if this is false (fail-safe).
    /// IsReady is NOT reset to false during cache refresh — the listener keeps the old
    /// snapshot live until the new one is fully built and swapped in.
    /// </summary>
    public bool IsReady { get; private set; }

    /// <summary>
    /// Loads capabilities from the role_capabilities table into memory.
    /// Safe to call multiple times (idempotent). Each call builds a fresh dictionary
    /// and atomically swaps it in via Volatile.Write.
    /// Must be called once in Program.cs after db.Database.Migrate() completes.
    /// </summary>
    public async Task InitializeAsync(IServiceProvider sp)
    {
        using var scope = sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var rows = await db.RoleCapabilities.AsNoTracking().ToListAsync();

        // Build the new dictionary BEFORE swapping — readers continue using the old snapshot
        // during this entire build phase. No reader is blocked.
        var newCache = rows
            .GroupBy(r => r.Role)
            .ToDictionary(
                g => g.Key,
                g => g.Select(r => r.Capability).ToHashSet(StringComparer.Ordinal));

        // Atomic reference swap: after this line, all subsequent readers see the new dictionary.
        // The old dictionary is safely GC'd once all readers holding a local snapshot release it.
        Volatile.Write(ref _cache, newCache);

        IsReady = true;
    }

    /// <summary>
    /// Returns the capability set for the given role.
    /// Returns an empty set if the role has no capabilities or is unknown.
    ///
    /// Thread-safe: captures a local snapshot of _cache before any read operation.
    /// A concurrent InitializeAsync() may swap _cache mid-flight, but once this method
    /// has captured the snapshot reference, it reads from a consistent, immutable view.
    /// </summary>
    public IReadOnlySet<string> GetCapabilities(string role)
    {
        // Volatile.Read captures the latest reference written by any writer thread.
        // Without this, the JIT may cache _cache in a register and miss a concurrent swap.
        var snapshot = Volatile.Read(ref _cache);
        return snapshot.TryGetValue(role, out var set)
            ? set
            : (IReadOnlySet<string>)new HashSet<string>();
    }
}

