using System.Text.Json;
using Serilog;

namespace Checkly.Api.Common.Scoring;

internal static class ScoringConfigParser
{
    private static readonly HashSet<string> ValidDirections =
        new(StringComparer.OrdinalIgnoreCase) { "up", "down", "none" };

    /// <summary>
    /// Parses the template's ScoringLogicConfig JSON and returns the three dispatch fields.
    /// New format: { "scoreDirection": "down", "isWeighted": true, "progressiveRepeat": false }
    /// Legacy compat: { "scoringMode": "penalty" } maps to ("down", true, false).
    /// Defaults on null/malformed input: ("down", false, false).
    /// </summary>
    internal static (string ScoreDirection, bool IsWeighted, bool ProgressiveRepeat) Parse(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return ("down", false, false);

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            bool progressiveRepeat = false;
            if (root.TryGetProperty("progressiveRepeat", out var prProp) &&
                (prProp.ValueKind == JsonValueKind.True || prProp.ValueKind == JsonValueKind.False))
            {
                progressiveRepeat = prProp.GetBoolean();
            }

            // New format: scoreDirection + isWeighted take precedence over legacy key.
            if (root.TryGetProperty("scoreDirection", out var sdProp) &&
                sdProp.ValueKind == JsonValueKind.String)
            {
                var raw = sdProp.GetString() ?? string.Empty;
                var direction = ValidDirections.Contains(raw) ? raw.ToLowerInvariant() : "down";

                bool isWeighted = false;
                if (root.TryGetProperty("isWeighted", out var iwProp) &&
                    (iwProp.ValueKind == JsonValueKind.True || iwProp.ValueKind == JsonValueKind.False))
                {
                    isWeighted = iwProp.GetBoolean();
                }

                return (direction, isWeighted, progressiveRepeat);
            }

            // Legacy fallback: map old scoringMode string to new fields.
            if (root.TryGetProperty("scoringMode", out var smProp) &&
                smProp.ValueKind == JsonValueKind.String)
            {
                return (smProp.GetString() ?? string.Empty) switch
                {
                    "penalty" => ("down", true, progressiveRepeat),
                    "accumulation" => ("up", false, progressiveRepeat),
                    "survey" => ("none", false, progressiveRepeat),
                    _ => ("down", false, progressiveRepeat), // checklist + unknown
                };
            }

            // No scoreDirection key — default to "down" but still honour isWeighted if present.
            bool fallbackWeighted = false;
            if (root.TryGetProperty("isWeighted", out var fwProp) &&
                (fwProp.ValueKind == JsonValueKind.True || fwProp.ValueKind == JsonValueKind.False))
            {
                fallbackWeighted = fwProp.GetBoolean();
            }
            return ("down", fallbackWeighted, progressiveRepeat);
        }
        catch (JsonException ex)
        {
            Log.Warning(ex, "Malformed ScoringLogicConfig JSON: {Json}", json);
            return ("down", false, false);
        }
    }
}
