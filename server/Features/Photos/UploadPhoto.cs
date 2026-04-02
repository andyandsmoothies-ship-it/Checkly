using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Photos;

/// <summary>
/// POST /api/photos/upload/{submissionId} — saves photo to filesystem.
/// Files stored at: data/photos/{submissionId}/{filename}
/// IDOR: Validates caller can access the submission.
/// If [answerId] is provided, the Answer row is patched with the CDN URL,
/// completing the two-phase media upload link.
/// </summary>
public static class UploadPhoto
{
    public static async Task<IResult> HandleAsync(
        Guid submissionId,
        Guid? answerId, // Optional: links upload to a specific Answer row
        IFormFile file,
        ClaimsPrincipal user,
        AppDbContext db,
        IWebHostEnvironment env,
        CancellationToken ct)
    {
        if (file.Length == 0)
            return TypedResults.BadRequest(new { error = "Empty file" });

        // DoS Prevention: Enforce 15MB absolute maximum boundary.
        if (file.Length > 15 * 1024 * 1024)
            return TypedResults.BadRequest(new { error = "File exceeds 15MB limit" });

        // Extension Spoofing / Arbitrary File Trust Prevention
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".heic" };
        if (!allowedExtensions.Contains(ext))
            return TypedResults.BadRequest(new { error = "Unsupported file type" });

        var submission = await db.Submissions.FindAsync(submissionId);
        if (submission is null)
            return TypedResults.NotFound(new { error = "Submission not found" });

        // IDOR: Verify the caller can access this submission
        var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
            user, submission.StoreId, areaId: null, auditorId: submission.AuditorId, db, ct);
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

        // Canonical answer patching: update the Answer row with the CDN URL.
        // This is the core of the two-phase media upload — the backend heals
        // the data relationship at the point of media ingestion.
        if (answerId.HasValue)
        {
            var answer = await db.Answers.FindAsync(new object[] { answerId.Value }, ct);
            if (answer != null && answer.SubmissionId == submissionId)
            {
                answer.PhotoUrl = photoUrl;
                await db.SaveChangesAsync(ct);
            }
        }

        return TypedResults.Created(photoUrl, new { url = photoUrl, fileName, size = file.Length });
    }
}
