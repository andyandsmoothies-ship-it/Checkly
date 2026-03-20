using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Photos;

/// <summary>
/// POST /api/photos/upload — saves photo to filesystem.
/// Files stored at: data/photos/{submissionId}/{filename}
/// IDOR: Validates caller can access the submission.
/// </summary>
public static class UploadPhoto
{
    public static async Task<IResult> HandleAsync(
        Guid submissionId,
        IFormFile file,
        ClaimsPrincipal user,
        AppDbContext db,
        IWebHostEnvironment env,
        CancellationToken ct)
    {
        if (file.Length == 0)
            return TypedResults.BadRequest(new { error = "Empty file" });

        var submission = await db.Submissions.FindAsync(submissionId);
        if (submission is null)
            return TypedResults.NotFound(new { error = "Submission not found" });

        // IDOR: Verify the caller can access this submission
        var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
            user, submission.StoreId, submission.AuditorId, db, ct);
        if (!hasAccess)
            return TypedResults.Forbid();

        // Save to filesystem
        var photoDir = Path.Combine(env.ContentRootPath, "data", "photos", submissionId.ToString());
        Directory.CreateDirectory(photoDir);

        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath = Path.Combine(photoDir, fileName);

        await using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream, ct);

        var photoUrl = $"/api/photos/{submissionId}/{fileName}";

        return TypedResults.Created(photoUrl, new { url = photoUrl, fileName, size = file.Length });
    }
}
