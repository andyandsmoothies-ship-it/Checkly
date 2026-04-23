using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// GET /api/global-risks — returns all global risks (active and inactive).
/// Any authenticated user can call this (no PBAC gate).
/// Admin UI needs to see deactivated risks to re-activate them.
/// The Flutter sync endpoint (Slice 4) will filter is_active=true.
/// </summary>
public static class ListGlobalRisks
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        int page = 1,
        int pageSize = 50,
        CancellationToken ct = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 200);

        var query = db.GlobalRisks.AsNoTracking().OrderBy(x => x.Label);

        var total = await query.CountAsync(ct);
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new GlobalRiskDto(x.Id, x.Label, x.Description, x.IsActive, x.CreatedAt, x.UpdatedAt))
            .ToListAsync(ct);

        return TypedResults.Ok(new PagedResult<GlobalRiskDto>(items, total, page, pageSize));
    }
}
