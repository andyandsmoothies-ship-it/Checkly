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
        if (!Guid.TryParse(submissionId, out var parsedSubmissionId))
            return TypedResults.BadRequest();

        // Prevent Path Traversal (e.g. ../../appsettings)
        if (fileName.Contains("..") || fileName.Contains('/') || fileName.Contains('\\'))
            return TypedResults.BadRequest();

        var filePath = Path.Combine(env.ContentRootPath, "data", "photos", parsedSubmissionId.ToString(), fileName);

        if (!File.Exists(filePath))
            return TypedResults.NotFound();

        // IDOR: Look up submission to verify ownership.
        // V4 Ghost File Bypass fix: if submission is null (deleted), deny immediately.
        // Previously: `if (submission is not null)` — null fell through to serve orphaned files (TOCTOU).
        var submission = await db.Submissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == parsedSubmissionId, ct);

        if (submission is null)
            return TypedResults.NotFound(); // Submission deleted — orphaned file, deny access

        var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
            user, submission.StoreId, areaId: null, auditorId: submission.AuditorId, db, ct);
        if (!hasAccess)
            return TypedResults.Forbid();

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
