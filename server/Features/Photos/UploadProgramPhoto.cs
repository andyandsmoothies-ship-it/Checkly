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

        if (!ImageValidation.IsValidImageMagicBytes(header, bytesRead))
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

}
