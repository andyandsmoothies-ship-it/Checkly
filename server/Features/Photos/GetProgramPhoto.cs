using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Storage;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Photos;

/// <summary>
/// GET /api/photos/programs/evidence/{assignmentId}/{fileName} — serves program evidence photo.
/// IDOR: Validates caller can access the assignment's store.
/// </summary>
public static class GetProgramPhoto
{
    public static async Task<IResult> HandleAsync(
        string assignmentId,
        string fileName,
        ClaimsPrincipal user,
        AppDbContext db,
        IFileStorage storage,
        CancellationToken ct)
    {
        if (!Guid.TryParse(assignmentId, out var parsedAssignmentId))
            return TypedResults.BadRequest();

        // Prevent Path Traversal
        if (fileName.Contains("..") || fileName.Contains('/') || fileName.Contains('\\'))
            return TypedResults.BadRequest();

        // IDOR: Look up assignment to verify ownership
        var assignment = await db.ProgramAssignments
            .AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == parsedAssignmentId, ct);

        if (assignment is null)
            return TypedResults.NotFound();

        var hasAccess = await ResourceAccessGuard.CanAccessAsync(
            user, new ResourceScope(StoreId: assignment.StoreId), db, ct);
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

        var stream = await storage.ReadAsync("photos", $"programs/{parsedAssignmentId}/{fileName}", ct);
        if (stream is null)
            return TypedResults.NotFound();

        return Results.Stream(stream, contentType);
    }
}
