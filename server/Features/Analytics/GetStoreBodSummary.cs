using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/stores/{storeId:guid}/bod-summary — Store BOD summary.
/// </summary>
public static class GetStoreBodSummary
{
    public static async Task<IResult> HandleAsync(
        Guid storeId,
        ClaimsPrincipal user,
        AppDbContext db,
        PbacDictionaryCache pbacCache,
        CancellationToken ct)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
        var userIdString = user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (role == AppRoles.Auditor)
        {
            return TypedResults.Forbid();
        }

        // Admins or users with capability 'analytics:bod' can access any store
        var hasBodCapability = pbacCache.IsReady && pbacCache.GetCapabilities(role).Contains(AppCapabilities.AnalyticsBod);
        var isAuthorized = role == AppRoles.Admin || hasBodCapability;

        if (!isAuthorized)
        {
            if (string.IsNullOrEmpty(userIdString) || !Guid.TryParse(userIdString, out var userGuid))
            {
                return TypedResults.Forbid();
            }

            var profile = await db.Profiles
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == userGuid, ct);

            if (profile == null)
            {
                return TypedResults.Forbid();
            }

            if (role == AppRoles.StoreManager)
            {
                if (profile.StoreId != storeId)
                {
                    return TypedResults.Forbid();
                }
            }
            else if (role == AppRoles.AreaManager)
            {
                var isAssigned = await db.ProfileStoreAssignments
                    .AnyAsync(a => a.ProfileId == userGuid && a.StoreId == storeId, ct);
                if (!isAssigned)
                {
                    return TypedResults.Forbid();
                }
            }
            else
            {
                return TypedResults.Forbid();
            }
        }

        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == storeId, ct);

        if (store == null)
        {
            return TypedResults.NotFound();
        }

        var recentAudits = await db.Submissions
            .AsNoTracking()
            .Where(s => s.StoreId == storeId && s.Status == "completed")
            .OrderByDescending(s => s.CompletedAt)
            .Take(5)
            .Select(s => new RecentAuditEntry(
                s.CompletedAt ?? s.CreatedAt,
                s.TotalScore ?? 0m,
                s.AuditorName ?? "Unknown"
            ))
            .ToListAsync(ct);

        var categoryBreakdownRaw = await db.SubmissionSectionScores
            .AsNoTracking()
            .Where(ss => ss.StoreId == storeId && ss.MaxScore > 0)
            .GroupBy(ss => ss.SectionTitle)
            .Select(g => new
            {
                CategoryName = g.Key,
                TotalScore = g.Sum(ss => ss.Score),
                TotalMaxScore = g.Sum(ss => ss.MaxScore)
            })
            .ToListAsync(ct);

        var categoryBreakdown = categoryBreakdownRaw
            .Select(x => new CategoryScoreEntry(
                x.CategoryName,
                x.TotalMaxScore > 0 ? Math.Round(x.TotalScore / x.TotalMaxScore * 100.0m, 1) : 0m
            ))
            .ToList();

        // 2. Province Benchmark & Peer Ranking
        string? quartileLabel = null;
        decimal regionalAvgScore = 0m;

        if (store.Address2 != null && !string.IsNullOrEmpty(store.Address2.Province))
        {
            var province = store.Address2.Province;

            var peers = await db.Stores
                .AsNoTracking()
                .Where(s => s.Address2 != null && s.Address2.Province == province && s.IsActive == true)
                .Join(db.StoreAnalyticsSnapshots.AsNoTracking(),
                    s => s.Id,
                    snap => snap.StoreId,
                    (s, snap) => new { s.Id, snap.AvgScore30d })
                .ToListAsync(ct);

            if (peers.Any())
            {
                regionalAvgScore = Math.Round(peers.Average(p => p.AvgScore30d), 1);

                if (peers.Count >= 4)
                {
                    var sortedPeers = peers.OrderByDescending(p => p.AvgScore30d).ToList();
                    var rank = sortedPeers.FindIndex(p => p.Id == storeId) + 1;

                    if (rank > 0)
                    {
                        var totalStores = peers.Count;
                        var percentile = (totalStores - rank) / (double)totalStores;

                        if (percentile >= 0.75)
                            quartileLabel = "Top 25% in Region";
                        else if (percentile >= 0.50)
                            quartileLabel = "Top 50% in Region";
                        else if (percentile >= 0.25)
                            quartileLabel = "Top 75% in Region";
                        else
                            quartileLabel = "Bottom 25% in Region";
                    }
                }
            }
        }

        // 3. SLA Overdue Action Plan Buckets
        var now = DateTimeOffset.UtcNow;
        var overdueAPs = await db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.StoreId == storeId && ap.Status == "open" && ap.Deadline != null && ap.Deadline < now)
            .Select(ap => new { ap.Deadline })
            .ToListAsync(ct);

        var apCount0To7d = overdueAPs.Count(ap => (now - ap.Deadline!.Value).TotalDays <= 7.0);
        var apCount8To30d = overdueAPs.Count(ap => (now - ap.Deadline!.Value).TotalDays > 7.0 && (now - ap.Deadline!.Value).TotalDays <= 30.0);
        var apCount31dPlus = overdueAPs.Count(ap => (now - ap.Deadline!.Value).TotalDays > 30.0);

        var slaOverdueBuckets = new List<BodApAgingBucket>
        {
            new BodApAgingBucket("0-7d", apCount0To7d),
            new BodApAgingBucket("8-30d", apCount8To30d),
            new BodApAgingBucket("31+d", apCount31dPlus)
        };

        return TypedResults.Ok(new StoreBodSummary(
            store.Name,
            recentAudits,
            categoryBreakdown,
            quartileLabel,
            regionalAvgScore,
            slaOverdueBuckets
        ));
    }
}
