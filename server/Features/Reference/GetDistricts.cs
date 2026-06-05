using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Reference;

/// <summary>
/// GET /api/reference/districts?province=... — returns distinct non-empty districts for active stores in a province.
/// </summary>
public static class GetDistricts
{
    public static async Task<IResult> HandleAsync(
        string? province,
        AppDbContext db,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(province))
        {
            return Results.BadRequest("Province parameter is required.");
        }

        var cleanProvince = province.Trim();

        var districts = await db.Stores
            .AsNoTracking()
            .Where(s => s.IsActive == true && s.Address2 != null && s.Address2.Province == cleanProvince)
            .Select(s => s.Address2!.District)
            .Where(d => d != null && d != "")
            .Distinct()
            .OrderBy(d => d)
            .ToListAsync(ct);

        return Results.Ok(districts);
    }
}
