using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions — role-based filtered list.
/// admin → all, auditor → own, store_manager → their store, area_manager → their area.
/// </summary>
public static class ListSubmissions
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";

        var query = db.Submissions.AsNoTracking().AsQueryable();

        switch (role)
        {
            case "admin":
                // Admin sees everything
                break;

            case "auditor":
                // Auditor sees only own submissions
                query = query.Where(s => s.AuditorId == userId);
                break;

            case "store_manager":
                // Store manager sees submissions for their store
                var profile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.Id == userId, ct);
                if (profile?.StoreId != null)
                    query = query.Where(s => s.StoreId == profile.StoreId);
                else
                    query = query.Where(s => false); // No store → no results
                break;

            case "area_manager":
                // Area manager sees submissions for all stores in their area
                var areaProfile = await db.Profiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.Id == userId, ct);
                if (areaProfile?.AreaId != null)
                {
                    var storeIds = await db.Stores
                        .Where(s => s.AreaId == areaProfile.AreaId)
                        .Select(s => s.Id)
                        .ToListAsync(ct);
                    query = query.Where(s => storeIds.Contains(s.StoreId!.Value));
                }
                else
                {
                    query = query.Where(s => false);
                }
                break;

            default:
                query = query.Where(s => false);
                break;
        }

        // Pagination (defaults: page 1, 50 items, max 100)
        var page = int.TryParse(httpContext.Request.Query["page"], out var p) ? Math.Max(1, p) : 1;
        var pageSize = int.TryParse(httpContext.Request.Query["pageSize"], out var ps) ? Math.Clamp(ps, 1, 100) : 50;

        var total = await query.CountAsync(ct);

        var submissions = await query
            .OrderByDescending(s => s.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new SubmissionDto(
                s.Id, s.TemplateId, s.TemplateTitle, s.DisplayNoun,
                s.StoreId, s.StoreName, s.AuditorId,
                s.AuditorName, s.Status, s.TotalScore,
                s.SectionScores, s.Notes,
                s.CreatedAt, s.CompletedAt, s.ScheduledAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<SubmissionDto>(submissions, total, page, pageSize));
    }
}
