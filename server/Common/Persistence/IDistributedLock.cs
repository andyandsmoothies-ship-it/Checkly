namespace Checkly.Api.Common.Persistence;

/// <summary>
/// Represents an acquired PostgreSQL advisory lock scoped to a database transaction.
/// Disposing commits the EF Core transaction, which automatically releases the
/// transaction-scoped advisory lock.
///
/// If the lock was NOT acquired (another pod holds it or a transient DB fault occurred),
/// <see cref="DistributedLockManager.TryAcquireAsync"/> returns null — this interface
/// is never instantiated in that case.
/// </summary>
public interface IDistributedLock : IAsyncDisposable { }
