using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Photos;

/// <summary>
/// GET /api/photos/{submissionId}/{fileName} — serves photo as binary stream.
/// IDOR: Validates caller can access the submission.
/// </summary>
public static class GetPhoto
{
    public static async Task<IResult> HandleAsync(
        string submissionId,
        string fileName,
        ClaimsPrincipal user,
        AppDbContext db,
        IWebHostEnvironment env,
        CancellationToken ct)
    {
        var filePath = Path.Combine(env.ContentRootPath, "data", "photos", submissionId, fileName);

        if (!File.Exists(filePath))
            return TypedResults.NotFound();

        // IDOR: Look up submission to verify ownership
        if (Guid.TryParse(submissionId, out var subId))
        {
            var submission = await db.Submissions
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == subId, ct);

            if (submission is not null)
            {
                var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
                    user, submission.StoreId, areaId: null, auditorId: submission.AuditorId, db, ct);
                if (!hasAccess)
                    return TypedResults.Forbid();
            }
        }

        var contentType = Path.GetExtension(fileName).ToLowerInvariant() switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".heic" => "image/heic",
            _ => "application/octet-stream"
        };

        return Results.File(filePath, contentType);
    }
}
