using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Storage;

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
        IFileStorage storage,
        CancellationToken ct)
    {
        if (file.Length == 0)
            return TypedResults.BadRequest(new { error = "Empty file" });

        // DoS Prevention: Enforce 15MB absolute maximum boundary.
        if (file.Length > 15 * 1024 * 1024)
            return TypedResults.BadRequest(new { error = "File exceeds 15MB limit" });

        // Magic Byte Validation (P0.6): Read the first 12 bytes of the actual payload
        // and verify against known image signatures. This is the PRIMARY content check —
        // it runs before the extension check to block renamed executables regardless of filename.
        // NOTE: IFormFile.OpenReadStream() is non-seekable. We read the header bytes here,
        // then call file.CopyToAsync() later to write the full stream from the start.
        var header = new byte[12];
        int bytesRead;
        await using (var headerStream = file.OpenReadStream())
        {
            bytesRead = await headerStream.ReadAsync(header, 0, 12, ct);
        }

        if (!ImageValidation.IsValidImageMagicBytes(header, bytesRead))
            return TypedResults.Problem(
                title: "Invalid file content",
                detail: "File content does not match a supported image format.",
                statusCode: 415);

        // Extension Sanitization: secondary filename check after content is verified.
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".heic" };
        if (!allowedExtensions.Contains(ext))
            return TypedResults.BadRequest(new { error = "Unsupported file type" });

        var submission = await db.Submissions.FindAsync(submissionId);
        if (submission is null)
            return TypedResults.NotFound(new { error = "Submission not found" });

        // IDOR: Verify the caller can access this submission
        var hasAccess = await ResourceAccessGuard.CanAccessAsync(
            user, new ResourceScope(StoreId: submission.StoreId, OwnerId: submission.AuditorId), db, ct);
        if (!hasAccess)
            return TypedResults.Forbid();

        // Save via storage abstraction (decoupled from raw filesystem).
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var key = $"{submissionId}/{fileName}";

        await using var saveStream = file.OpenReadStream();
        await storage.SaveAsync("photos", key, saveStream, ct);

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
