using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/sync/submissions — Mobile delta-sync endpoint.
/// Returns a paginated, incremental list of submissions modified after a given timestamp.
///
/// Security:
///   - Non-admin callers MUST supply ?storeId or ?areaId. Unbounded syncs are rejected (400).
///   - IDOR: the caller's identity is verified against the requested storeId/areaId.
///   - Admin bypasses scope requirement and receives all matching records.
///
/// Pagination: ?page=1&amp;pageSize=50. Hard cap at 200.
/// Delta: ?since=ISO8601 timestamp. Defaults to DateTimeOffset.MinValue (full sync) when omitted.
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

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct,
        DateTimeOffset? since = null,
        Guid? storeId = null,
        Guid? areaId = null,
        int page = 1,
        int pageSize = 50)
    {
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
            var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
                user, storeId, areaId, auditorId: null, db, ct);

            if (!hasAccess)
                return TypedResults.Forbid();
        }

        // ── Rule 6: Coalesce null since to MinValue (prevent unbounded scans) ─
        var sinceEffective = since ?? DateTimeOffset.MinValue;

        // ── Clamp pagination params ──────────────────────────────────────────
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 200);

        // ── Build query ──────────────────────────────────────────────────────
        var query = db.Submissions.AsNoTracking()
            .Where(s => s.UpdatedAt >= sinceEffective);

        // Apply tenant scope filter (non-admin or admin who chose to scope)
        if (storeId.HasValue)
            query = query.Where(s => s.StoreId == storeId.Value);
        else if (areaId.HasValue)
            // Area filter: join through Store.AreaId
            query = query.Where(s => s.Store != null && s.Store.AreaId == areaId.Value);

        // ── Rule 4: Stable ordering to prevent cursor drift ──────────────────
        var ordered = query
            .OrderBy(s => s.UpdatedAt)
            .ThenBy(s => s.Id);

        var total = await ordered.CountAsync(ct);

        var items = await ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
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

        return TypedResults.Ok(new PagedResult<SubmissionSyncDto>(items, total, page, pageSize));
    }
}
