using System.Security.Claims;
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
                if (areaProfile?.AreaCode != null)
                {
                    var storeIds = await db.Stores
                        .Where(s => s.AreaCode == areaProfile.AreaCode)
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

        var submissions = await query
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => new SubmissionDto(
                s.Id, s.TemplateId, s.TemplateTitle,
                s.StoreId, s.StoreName, s.AuditorId,
                s.AuditorName, s.Status, s.TotalScore,
                s.SectionScores, s.Notes,
                s.CreatedAt, s.CompletedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(submissions);
    }
}
