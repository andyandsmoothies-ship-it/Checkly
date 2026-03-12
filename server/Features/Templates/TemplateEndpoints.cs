namespace Checkly.Api.Features.Templates;

/// <summary>
/// Maps the /api/templates and /api/sync/templates route groups.
/// </summary>
public static class TemplateEndpoints
{
    public static void MapTemplateEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/templates")
            .WithTags("Templates")
            .RequireAuthorization();

        group.MapGet("/", ListTemplates.HandleAsync)
            .WithName("ListTemplates");

        group.MapGet("/{id}", GetTemplate.HandleAsync)
            .WithName("GetTemplate");

        group.MapPost("/", CreateTemplate.HandleAsync)
            .WithName("CreateTemplate")
            .RequireAuthorization("AdminOnly");

        group.MapPut("/{id}", UpdateTemplate.HandleAsync)
            .WithName("UpdateTemplate")
            .RequireAuthorization("AdminOnly");

        group.MapDelete("/{id}", DeleteTemplate.HandleAsync)
            .WithName("DeleteTemplate")
            .RequireAuthorization("AdminOnly");

        // Group CRUD
        group.MapPost("/{templateId}/groups", CreateGroup.HandleAsync)
            .WithName("CreateGroup")
            .RequireAuthorization("AdminOnly");

        group.MapPut("/{templateId}/groups/{groupId}", UpdateGroup.HandleAsync)
            .WithName("UpdateGroup")
            .RequireAuthorization("AdminOnly");

        group.MapDelete("/{templateId}/groups/{groupId}", DeleteGroup.HandleAsync)
            .WithName("DeleteGroup")
            .RequireAuthorization("AdminOnly");

        // Criterion CRUD
        group.MapPost("/{templateId}/groups/{groupId}/criteria", CreateCriterion.HandleAsync)
            .WithName("CreateCriterion")
            .RequireAuthorization("AdminOnly");

        group.MapPut("/{templateId}/criteria/{criterionId}", UpdateCriterion.HandleAsync)
            .WithName("UpdateCriterion")
            .RequireAuthorization("AdminOnly");

        group.MapDelete("/{templateId}/criteria/{criterionId}", DeleteCriterion.HandleAsync)
            .WithName("DeleteCriterion")
            .RequireAuthorization("AdminOnly");

        // Delta sync endpoint
        var syncGroup = app.MapGroup("/api/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        syncGroup.MapGet("/templates", SyncTemplates.HandleAsync)
            .WithName("SyncTemplates");
    }
}
