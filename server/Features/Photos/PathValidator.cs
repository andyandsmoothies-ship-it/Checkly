namespace Checkly.Api.Features.Photos;

/// <summary>
/// WARN-05 / Item-16: Centralized path traversal guard for file name parameters.
/// Extracts the identical inline guard from GetPhoto and GetProgramPhoto
/// so any future URL-encoded traversal variants (.%2F, %5C) can be blocked in one place.
/// </summary>
internal static class PathValidator
{
    /// <summary>
    /// Returns true when <paramref name="fileName"/> contains a path traversal sequence.
    /// </summary>
    internal static bool IsTraversal(string fileName)
        => fileName.Contains("..") || fileName.Contains('/') || fileName.Contains('\\');
}
