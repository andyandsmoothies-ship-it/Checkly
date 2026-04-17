using System.Text.Json;

namespace Checkly.Api.Tests;

public static class ScoringTestVectorReader
{
    private static readonly string _vectorFilePath = ResolveVectorFilePath();

    private static string ResolveVectorFilePath()
    {
        // Walk up from bin/Debug/net10.0/ until we find the .git root
        var dir = new DirectoryInfo(AppDomain.CurrentDomain.BaseDirectory);
        for (int i = 0; i < 10; i++)
        {
            if (dir is null) break;
            if (Directory.Exists(Path.Combine(dir.FullName, ".git")))
                return Path.Combine(dir.FullName, "test", "scoring_test_vectors.json");
            dir = dir.Parent;
        }
        // Fallback: environment variable for exotic CI setups
        var envRoot = Environment.GetEnvironmentVariable("CHECKLY_REPO_ROOT");
        if (!string.IsNullOrEmpty(envRoot))
            return Path.Combine(envRoot, "test", "scoring_test_vectors.json");

        throw new InvalidOperationException(
            "Cannot locate .git root. Set CHECKLY_REPO_ROOT env var to the repo root directory.");
    }

    public static IEnumerable<object[]> LoadVectors()
    {
        if (!File.Exists(_vectorFilePath))
            throw new InvalidOperationException(
                $"Vector file not found at: {_vectorFilePath}");

        var json = File.ReadAllText(_vectorFilePath);
        var file = JsonSerializer.Deserialize<VectorFile>(json)
            ?? throw new InvalidOperationException("Vector file deserialized to null.");

        return file.Vectors.Select(v => new object[] { v });
    }
}
