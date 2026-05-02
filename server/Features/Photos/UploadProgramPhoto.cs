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
    public static async Task<IResult> HandleAsync(
        string photoLocalKey,
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

        // Extension Sanitization
        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".heic" };
        if (!allowedExtensions.Contains(ext))
            return TypedResults.BadRequest(new { error = "Unsupported file type" });

        var evidence = await db.ProgramEvidence
            .Include(e => e.Assignment)
            .FirstOrDefaultAsync(e => e.PhotoLocalKey == photoLocalKey, ct);

        if (evidence is null || evidence.Assignment is null)
            return TypedResults.NotFound(new { error = "Evidence not found" });

        // IDOR: Verify the caller can access this assignment's store
        var hasAccess = await ResourceAccessGuard.CanAccessAsync(
            user, new ResourceScope(StoreId: evidence.Assignment.StoreId), db, ct);
        if (!hasAccess)
            return TypedResults.Forbid();

        // Save via storage abstraction
        var fileName = $"{photoLocalKey}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var key = $"programs/{evidence.AssignmentId}/{fileName}";

        await using var saveStream = file.OpenReadStream();
        await storage.SaveAsync("photos", key, saveStream, ct);

        var photoUrl = $"/api/photos/programs/evidence/{evidence.AssignmentId}/{fileName}";

        // Patch the evidence row
        evidence.PhotoLocalKey = photoUrl;
        await db.SaveChangesAsync(ct);

        return TypedResults.Created(photoUrl, new { url = photoUrl, fileName, size = file.Length });
    }

    private static bool IsValidImageMagicBytes(byte[] header, int bytesRead)
    {
        if (bytesRead < 3) return false;

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) return true;

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (bytesRead >= 8 &&
            header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
            header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            return true;

        // WebP: RIFF at [0-3] and WEBP at [8-11]
        if (bytesRead >= 12 &&
            header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
            header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
            return true;

        // HEIC: "ftyp" ASCII at offset 4
        if (bytesRead >= 8 &&
            header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70)
            return true;

        return false;
    }
}
