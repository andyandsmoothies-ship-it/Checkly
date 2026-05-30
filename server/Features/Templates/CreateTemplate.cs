using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// POST /api/templates — create a new template (AdminOnly).
/// </summary>
public static class CreateTemplate
{
    public static async Task<IResult> HandleAsync(
        CreateTemplateRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var createdBy = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var template = new Template
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Type = request.Type,
            Description = request.Description,
            ScoringLogicConfig = request.ScoringLogicConfig,
            DisplayNoun = request.DisplayNoun,
            CategoryTag = request.CategoryTag,
            Version = 1,
            IsActive = true,
            CreatedBy = createdBy,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Templates.Add(template);
        AuditLogger.Log(db, user, "template_created", "template", template.Id,
            $"Created template '{template.Title}'", "/api/templates");
        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/templates/{template.Id}",
            new TemplateDto(
                template.Id, template.Title, template.Description, template.Type,
                template.Version, template.ScoringLogicConfig, template.DisplayNoun, template.CategoryTag, template.IsActive, template.CreatedAt, template.UpdatedAt));
    }
}
