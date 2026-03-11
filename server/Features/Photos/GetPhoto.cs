namespace Checkly.Api.Features.Photos;

/// <summary>
/// GET /api/photos/{submissionId}/{fileName} — serves photo as binary stream.
/// </summary>
public static class GetPhoto
{
    public static IResult Handle(string submissionId, string fileName, IWebHostEnvironment env)
    {
        var filePath = Path.Combine(env.ContentRootPath, "data", "photos", submissionId, fileName);

        if (!File.Exists(filePath))
            return TypedResults.NotFound();

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
