using Microsoft.AspNetCore.Hosting;

namespace Checkly.Api.Common.Storage;

/// <summary>
/// Local filesystem implementation of IFileStorage.
/// Resolves physical paths via IWebHostEnvironment to mirror the existing
/// data/photos/{submissionId}/{fileName} convention used in the photo handlers.
///
/// SECURITY: Validates keys for path traversal sequences before any disk I/O.
/// </summary>
public sealed class LocalFileStorage(IWebHostEnvironment env) : IFileStorage
{
    private static readonly Serilog.ILogger Logger = Serilog.Log.ForContext<LocalFileStorage>();

    public async Task SaveAsync(string bucket, string key, Stream content, CancellationToken ct)
    {
        var physicalPath = ResolvePath(bucket, key);

        var dir = Path.GetDirectoryName(physicalPath)!;
        Directory.CreateDirectory(dir);

        Logger.Debug("LocalFileStorage: saving to {Path}", physicalPath);

        await using var fs = new FileStream(physicalPath, FileMode.Create, FileAccess.Write);
        await content.CopyToAsync(fs, ct);
    }

    public Task<Stream?> ReadAsync(string bucket, string key, CancellationToken ct)
    {
        var physicalPath = ResolvePath(bucket, key);

        if (!File.Exists(physicalPath))
        {
            Logger.Debug("LocalFileStorage: file not found at {Path}", physicalPath);
            return Task.FromResult<Stream?>(null);
        }

        Logger.Debug("LocalFileStorage: reading from {Path}", physicalPath);
        Stream stream = new FileStream(physicalPath, FileMode.Open, FileAccess.Read, FileShare.Read);
        return Task.FromResult<Stream?>(stream);
    }

    public Task<bool> ExistsAsync(string bucket, string key, CancellationToken ct)
    {
        var physicalPath = ResolvePath(bucket, key);
        return Task.FromResult(File.Exists(physicalPath));
    }

    /// <summary>
    /// Resolves a bucket + key to an absolute path under ContentRootPath/data/.
    /// Throws ArgumentException if the key contains path traversal sequences.
    /// </summary>
    private string ResolvePath(string bucket, string key)
    {
        // SECURITY: Reject any key that attempts to escape the storage root.
        if (key.Contains("..") || key.Contains('\0'))
            throw new ArgumentException($"Invalid storage key: '{key}'", nameof(key));

        // Normalise forward slashes to OS separator so keys like "submissionId/fileName" work on Windows.
        var normalizedKey = key.Replace('/', Path.DirectorySeparatorChar);

        return Path.Combine(env.ContentRootPath, "data", bucket, normalizedKey);
    }
}
