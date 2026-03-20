using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// DELETE /api/templates/{id} — soft-delete a template (AdminOnly).
/// </summary>
public static class DeleteTemplate
{
    public static async Task<IResult> HandleAsync(
        Guid id, ClaimsPrincipal user,
        AppDbContext db, CancellationToken ct)
    {
        var template = await db.Templates.FindAsync([id], ct);
        if (template is null)
            return Results.NotFound();

        template.IsActive = false;
        template.UpdatedAt = DateTimeOffset.UtcNow;

        AuditLogger.Log(db, user, "template_deleted", "template", id,
            $"Soft-deleted template '{template.Title}'", $"/api/templates/{id}");

        await db.SaveChangesAsync(ct);
        return Results.NoContent();
    }
}
