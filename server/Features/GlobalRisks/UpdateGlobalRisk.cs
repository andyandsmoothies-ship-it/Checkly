using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// PUT /api/global-risks/{id} — partial update of a global risk.
/// Admin-only (guarded by RequireCapability at endpoint level).
/// Returns 200 OK with updated GlobalRiskDto, or 404 if not found.
/// Allows re-activating a deactivated risk via IsActive = true.
/// </summary>
public static class UpdateGlobalRisk
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        UpdateGlobalRiskRequest request,
        AppDbContext db,
        CancellationToken ct)
    {
        var risk = await db.GlobalRisks.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (risk is null)
            return TypedResults.NotFound(new { message = "Global risk not found." });

        if (request.Label is not null)
            risk.Label = request.Label.Trim();

        if (request.Description is not null)
            risk.Description = request.Description.Trim();

        if (request.IsActive is not null)
            risk.IsActive = request.IsActive.Value;

        risk.UpdatedAt = DateTimeOffset.UtcNow;

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(
            new GlobalRiskDto(risk.Id, risk.Label, risk.Description, risk.IsActive, risk.CreatedAt, risk.UpdatedAt));
    }
}
