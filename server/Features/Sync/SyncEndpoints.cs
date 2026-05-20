namespace Checkly.Api.Features.Sync;

/// <summary>
/// WARN-02: Extracted from TemplateEndpoints.cs.
/// All /api/sync/* routes belong here — not inside the Templates feature.
/// </summary>
public static class SyncEndpoints
{
    public static void MapSyncEndpoints(this WebApplication app)
    {
        var syncGroup = app.MapGroup("/api/sync")
            .WithTags("Sync")
            .RequireAuthorization();

        syncGroup.MapGet("/templates", Templates.SyncTemplates.HandleAsync)
            .WithName("SyncTemplates");

        syncGroup.MapGet("/submissions", Submissions.SyncSubmissions.HandleAsync)
            .WithName("SyncSubmissions");

        syncGroup.MapGet("/profile", Auth.SyncProfile.HandleAsync)
            .WithName("SyncProfile");
    }
}
