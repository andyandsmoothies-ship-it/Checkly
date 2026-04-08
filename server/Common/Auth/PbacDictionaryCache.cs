using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Common.Auth;

/// <summary>
/// Singleton in-memory capability cache for PBAC.
/// Holds a Dictionary keyed by role string → set of capability strings.
/// Loaded once on startup via InitializeAsync(). Cache invalidation
/// via Postgres LISTEN/NOTIFY is deferred to Slice 3.
/// </summary>
public sealed class PbacDictionaryCache
{
    private Dictionary<string, HashSet<string>> _cache = [];

    /// <summary>
    /// True once InitializeAsync has completed successfully.
    /// The CapabilityAuthorizationHandler denies all requests if this is false (fail-safe).
    /// </summary>
    public bool IsReady { get; private set; }

    /// <summary>
    /// Loads capabilities from the role_capabilities table into memory.
    /// Must be called once in Program.cs after db.Database.Migrate() completes.
    /// </summary>
    public async Task InitializeAsync(IServiceProvider sp)
    {
        using var scope = sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var rows = await db.RoleCapabilities.AsNoTracking().ToListAsync();

        _cache = rows
            .GroupBy(r => r.Role)
            .ToDictionary(
                g => g.Key,
                g => g.Select(r => r.Capability).ToHashSet(StringComparer.Ordinal));

        IsReady = true;
    }

    /// <summary>
    /// Returns the capability set for the given role.
    /// Returns an empty set if the role has no capabilities or is unknown.
    /// </summary>
    public IReadOnlySet<string> GetCapabilities(string role) =>
        _cache.TryGetValue(role, out var set)
            ? set
            : (IReadOnlySet<string>)new HashSet<string>();
}
