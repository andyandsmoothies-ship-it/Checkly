namespace Checkly.Api.Common.Storage;

/// <summary>
/// Abstraction over the binary storage layer.
/// Decouples feature handlers from the underlying storage mechanism (local disk, cloud, etc.).
/// Uses a bucket-and-key model to enable seamless cloud migration.
/// </summary>
public interface IFileStorage
{
    /// <summary>Persists a stream to the specified bucket and key.</summary>
    Task SaveAsync(string bucket, string key, Stream content, CancellationToken ct);

    /// <summary>
    /// Returns a readable stream for the given file, or null if the file does not exist.
    /// Caller is responsible for disposing the returned stream.
    /// </summary>
    Task<Stream?> ReadAsync(string bucket, string key, CancellationToken ct);

    /// <summary>Returns true if the file exists at the given bucket/key path.</summary>
    Task<bool> ExistsAsync(string bucket, string key, CancellationToken ct);
}
