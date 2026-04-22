using Checkly.Api.Common.Auth;

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
            .RequireCapability(AppCapabilities.TemplatesCreate);

        group.MapPut("/{id}/tree", SaveTemplateTree.HandleAsync)
            .WithName("SaveTemplateTree")
            .RequireCapability(AppCapabilities.TemplatesUpdate);

        group.MapPut("/{id}", UpdateTemplate.HandleAsync)
            .WithName("UpdateTemplate")
            .RequireCapability(AppCapabilities.TemplatesUpdate);

        group.MapDelete("/{id}", DeleteTemplate.HandleAsync)
            .WithName("DeleteTemplate")
            .RequireCapability(AppCapabilities.TemplatesDelete);

        group.MapPost("/{id}/clone", CloneTemplate.HandleAsync)
            .WithName("CloneTemplate")
            .RequireCapability(AppCapabilities.TemplatesCreate);

        // Group CRUD
        group.MapPost("/{templateId}/groups", CreateGroup.HandleAsync)
            .WithName("CreateGroup")
            .RequireCapability(AppCapabilities.TemplatesCreate);

        group.MapPut("/{templateId}/groups/{groupId}", UpdateGroup.HandleAsync)
            .WithName("UpdateGroup")
            .RequireCapability(AppCapabilities.TemplatesUpdate);

        group.MapDelete("/{templateId}/groups/{groupId}", DeleteGroup.HandleAsync)
            .WithName("DeleteGroup")
            .RequireCapability(AppCapabilities.TemplatesDelete);

        // Criterion CRUD
        group.MapPost("/{templateId}/groups/{groupId}/criteria", CreateCriterion.HandleAsync)
            .WithName("CreateCriterion")
            .RequireCapability(AppCapabilities.TemplatesCreate);

        group.MapPut("/{templateId}/criteria/{criterionId}", UpdateCriterion.HandleAsync)
            .WithName("UpdateCriterion")
            .RequireCapability(AppCapabilities.TemplatesUpdate);

        group.MapDelete("/{templateId}/criteria/{criterionId}", DeleteCriterion.HandleAsync)
            .WithName("DeleteCriterion")
            .RequireCapability(AppCapabilities.TemplatesDelete);

        // Template assignments (access control)
        group.MapPut("/{id}/assignments", UpdateAssignments.HandleAsync)
            .WithName("UpdateTemplateAssignments")
            .RequireCapability(AppCapabilities.TemplatesUpdate);

        // Delta sync endpoint
        var syncGroup = app.MapGroup("/api/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        syncGroup.MapGet("/templates", SyncTemplates.HandleAsync)
            .WithName("SyncTemplates");

        syncGroup.MapGet("/submissions", Checkly.Api.Features.Submissions.SyncSubmissions.HandleAsync)
            .WithName("SyncSubmissions");
    }
}
