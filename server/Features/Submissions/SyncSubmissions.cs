using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/sync/submissions — Mobile delta-sync endpoint.
/// Returns a keyset paginated, incremental list of submissions modified after a given timestamp.
///
/// Security:
///   - Non-admin callers MUST supply ?storeId or ?areaId. Unbounded syncs are rejected (400).
///   - IDOR: the caller's identity is verified against the requested storeId/areaId.
///   - Admin bypasses scope requirement and receives all matching records.
///
/// Pagination: Keyset. ?limit=50. Hard cap at 200.
/// Cursor: ?cursorUpdatedAt=ISO8601&cursorId=UUID.
/// Delta Fallback: ?since=ISO8601 timestamp (used if cursor is omitted). Defaults to DateTimeOffset.MinValue.
/// </summary>
public static class SyncSubmissions
{
    /// <summary>Flat projection emitted to mobile clients.</summary>
    public sealed record SubmissionSyncDto(
        Guid Id,
        string Status,
        string? VoidReason,
        DateTimeOffset? VoidedAt,
        DateTimeOffset UpdatedAt,
        Guid? StoreId,
        string? StoreName,
        decimal? TotalScore,
        string? ScoringMode,
        decimal? RawEarnedPoints = null,
        decimal? RawMaxPoints = null,
        bool? IsWeighted = null);

    public sealed record CursorPagedResult<T>(IEnumerable<T> Items, bool HasNextPage);

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        ILoggerFactory loggerFactory,
        CancellationToken ct,
        DateTimeOffset? since = null,
        DateTimeOffset? cursorUpdatedAt = null,
        Guid? cursorId = null,
        Guid? storeId = null,
        Guid? areaId = null,
        int limit = 50)
    {
        var logger = loggerFactory.CreateLogger(typeof(SyncSubmissions));
        var isAdmin = user.IsInRole("admin");

        // ── Rule 1: Scope guard — non-admins must provide storeId or areaId ──
        if (!isAdmin && !storeId.HasValue && !areaId.HasValue)
            return TypedResults.BadRequest(new
            {
                error = "A storeId or areaId query parameter is required for non-admin callers."
            });

        // ── Rule 2: IDOR guard ───────────────────────────────────────────────
        // Admin bypasses; others must own the requested scope.
        if (!isAdmin)
        {
            // For store-scoped requests, run the access guard with a representative submission-like tuple.
            // We pass the storeId directly (auditorId=null is safe — guard checks role-level).
            var hasAccess = await ResourceAccessGuard.CanAccessAsync(
                user, new ResourceScope(StoreId: storeId, AreaId: areaId), db, ct);

            if (!hasAccess)
                return TypedResults.Forbid();
        }

        if (!cursorUpdatedAt.HasValue || !cursorId.HasValue)
        {
            logger.LogInformation("SyncSubmissions fallback to full-sync (no cursor provided). StoreId: {StoreId}, AreaId: {AreaId}, Since: {Since}", storeId, areaId, since);
        }

        // ── Clamp pagination params ──────────────────────────────────────────
        limit = Math.Clamp(limit, 1, 200);

        // ── Build query ──────────────────────────────────────────────────────
        var query = db.Submissions.AsNoTracking().AsQueryable();

        // Apply tenant scope filter (non-admin or admin who chose to scope)
        if (storeId.HasValue)
            query = query.Where(s => s.StoreId == storeId.Value);
        else if (areaId.HasValue)
            query = query.Where(s => s.Store != null && s.Store.AreaId == areaId.Value);

        // Cursor logic
        if (cursorUpdatedAt.HasValue && cursorId.HasValue)
        {
            query = query.Where(s => s.UpdatedAt > cursorUpdatedAt.Value || 
                                    (s.UpdatedAt == cursorUpdatedAt.Value && s.Id > cursorId.Value));
        }
        else 
        {
            // ── Rule 6: Coalesce null since to MinValue (prevent unbounded scans) ─
            var sinceEffective = since ?? DateTimeOffset.MinValue;
            query = query.Where(s => s.UpdatedAt >= sinceEffective);
        }

        // ── Rule 4: Stable ordering to prevent cursor drift ──────────────────
        var ordered = query
            .OrderBy(s => s.UpdatedAt)
            .ThenBy(s => s.Id);

        var items = await ordered
            .Take(limit + 1)
            .Select(s => new SubmissionSyncDto(
                s.Id,
                s.Status,
                s.VoidReason,
                s.VoidedAt,
                s.UpdatedAt,
                s.StoreId,
                s.StoreName,
                s.TotalScore,
                s.ScoringMode,
                s.RawEarnedPoints, s.RawMaxPoints, s.IsWeighted))
            .ToListAsync(ct);

        var hasNextPage = items.Count > limit;
        var resultItems = items.Take(limit);

        return TypedResults.Ok(new CursorPagedResult<SubmissionSyncDto>(resultItems, hasNextPage));
    }
}
