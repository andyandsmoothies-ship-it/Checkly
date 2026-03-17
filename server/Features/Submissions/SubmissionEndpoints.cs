namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Maps the /api/submissions route group (requires authentication).
/// </summary>
public static class SubmissionEndpoints
{
    public static void MapSubmissionEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/submissions")
            .WithTags("Submissions")
            .RequireAuthorization();

        group.MapPost("/", CreateSubmission.HandleAsync)
            .WithName("CreateSubmission");

        group.MapGet("/", ListSubmissions.HandleAsync)
            .WithName("ListSubmissions");

        group.MapGet("/survey-results", GetSurveyResults.HandleAsync)
            .WithName("GetSurveyResults");

        group.MapGet("/{id}", GetSubmission.HandleAsync)
            .WithName("GetSubmission");

        group.MapPut("/{id}", UpdateSubmission.HandleAsync)
            .WithName("UpdateSubmission");

        group.MapPut("/{id}/review", ReviewSubmission.HandleAsync)
            .WithName("ReviewSubmission");

        group.MapPut("/{id}/finalize", FinalizeSubmission.HandleAsync)
            .WithName("FinalizeSubmission");
    }
}
