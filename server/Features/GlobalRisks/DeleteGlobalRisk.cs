using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// DELETE /api/global-risks/{id} — SOFT-DELETE ONLY (sets is_active = false).
/// Admin-only (guarded by RequireCapability at endpoint level).
/// CRITICAL: Never calls db.GlobalRisks.Remove(). The RESTRICT FK on submission_risks
/// means a hard delete would fail if any SubmissionRisk references this GlobalRisk.
/// Idempotent: deleting an already-deactivated risk returns 200 OK.
/// </summary>
public static class DeleteGlobalRisk
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var risk = await db.GlobalRisks.FirstOrDefaultAsync(x => x.Id == id, ct);
        if (risk is null)
            return TypedResults.NotFound(new { message = "Global risk not found." });

        // Idempotent: already deactivated — return success without re-logging
        if (!risk.IsActive)
            return TypedResults.Ok(new { message = "Risk deactivated." });

        var callerId = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var cid) ? cid : (Guid?)null;

        risk.IsActive = false;
        risk.UpdatedAt = DateTimeOffset.UtcNow;

        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = "deactivate_global_risk",
            Category = "global_risks",
            EntityType = "global_risk",
            EntityId = risk.Id,
            Message = $"Deactivated global risk: {risk.Label}",
            Path = $"/api/global-risks/{id}",
            Level = "warning",
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { message = "Risk deactivated." });
    }
}
