namespace Checkly.Api.Features.Photos;

/// <summary>
/// Maps photo endpoints — upload and serve.
/// </summary>
public static class PhotoEndpoints
{
    public static IEndpointConventionBuilder MapPhotoEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/photos")
            .WithTags("Photos")
            .RequireAuthorization();

        group.MapPost("/upload/{submissionId}", UploadPhoto.HandleAsync)
            .WithName("UploadPhoto")
            .DisableAntiforgery();

        group.MapGet("/{submissionId}/{fileName}", GetPhoto.HandleAsync)
            .WithName("GetPhoto");



        group.MapGet("/programs/evidence/{assignmentId}/{fileName}", GetProgramPhoto.HandleAsync)
            .WithName("GetProgramPhoto");

        return group;
    }
}
