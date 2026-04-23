using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// POST /api/global-risks — creates a new global risk entry.
/// Admin-only (guarded by RequireCapability at endpoint level).
/// Returns 201 Created with the new GlobalRiskDto.
/// </summary>
public static class CreateGlobalRisk
{
    public static async Task<IResult> HandleAsync(
        CreateGlobalRiskRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Validate label
        if (string.IsNullOrWhiteSpace(request.Label))
            return TypedResults.BadRequest(new { message = "Label is required." });

        var callerId = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : (Guid?)null;

        var risk = new GlobalRisk
        {
            Id = Guid.NewGuid(),
            Label = request.Label.Trim(),
            Description = request.Description?.Trim(),
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };
        db.GlobalRisks.Add(risk);

        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = "create_global_risk",
            Category = "global_risks",
            EntityType = "global_risk",
            EntityId = risk.Id,
            Message = $"Created global risk: {risk.Label}",
            Path = "/api/global-risks",
            Level = "info",
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/global-risks/{risk.Id}",
            new GlobalRiskDto(risk.Id, risk.Label, risk.Description, risk.IsActive, risk.CreatedAt, risk.UpdatedAt));
    }
}
