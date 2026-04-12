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

        if (!IsValidImageMagicBytes(header, bytesRead))
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
        var hasAccess = await SubmissionAccessGuard.CanAccessAsync(
            user, submission.StoreId, areaId: null, auditorId: submission.AuditorId, db, ct);
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

    /// <summary>
    /// Validates the first 12 bytes of the uploaded file against known image magic byte signatures.
    /// Blocks executables, scripts, and arbitrary binary data renamed with image extensions.
    ///
    /// Supported signatures:
    ///   JPEG: FF D8 FF
    ///   PNG:  89 50 4E 47 0D 0A 1A 0A
    ///   WebP: RIFF (at 0) + WEBP (at 8)
    ///   HEIC: ftyp (ASCII) at offset 4
    /// </summary>
    private static bool IsValidImageMagicBytes(byte[] header, int bytesRead)
    {
        // Require at least 3 bytes to identify any signature
        if (bytesRead < 3)
            return false;

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
            return true;

        // PNG: 89 50 4E 47 0D 0A 1A 0A (8 bytes required)
        if (bytesRead >= 8 &&
            header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
            header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            return true;

        // WebP: RIFF at [0-3] and WEBP at [8-11] (12 bytes required)
        if (bytesRead >= 12 &&
            header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
            header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
            return true;

        // HEIC: "ftyp" ASCII at offset 4 (8 bytes required)
        if (bytesRead >= 8 &&
            header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70)
            return true;

        return false;
    }
}

