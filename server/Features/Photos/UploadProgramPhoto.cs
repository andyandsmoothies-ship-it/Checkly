using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Storage;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Photos;

/// <summary>
/// POST /api/photos/programs/evidence/{photoLocalKey} — saves program evidence photo to filesystem.
/// Files stored at: data/photos/programs/{assignmentId}/{filename}
/// IDOR: Validates caller can access the assignment's store.
/// Patches the ProgramEvidence row's PhotoLocalKey with the final CDN URL.
/// </summary>
public static class UploadProgramPhoto
{
    public static Task<IResult> HandleAsync(string photoLocalKey)
    {
        return Task.FromResult<IResult>(TypedResults.Problem(
            statusCode: 410,
            title: "Gone",
            detail: "Program photo upload via this endpoint is deprecated. Use the submission photo endpoint."));
    }
}
