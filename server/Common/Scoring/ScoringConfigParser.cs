using System.Text.Json;
using Serilog;

namespace Checkly.Api.Common.Scoring;

internal static class ScoringConfigParser
{
    internal static (string ScoringMode, bool ProgressiveRepeat) Parse(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return ("penalty", false);
        }

        try
        {
            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            string scoringMode = "penalty";
            if (root.TryGetProperty("scoringMode", out var smProp) && smProp.ValueKind == JsonValueKind.String)
            {
                scoringMode = smProp.GetString() ?? "penalty";
            }

            bool progressiveRepeat = false;
            if (root.TryGetProperty("progressiveRepeat", out var prProp))
            {
                if (prProp.ValueKind == JsonValueKind.True || prProp.ValueKind == JsonValueKind.False)
                {
                    progressiveRepeat = prProp.GetBoolean();
                }
            }

            return (scoringMode, progressiveRepeat);
        }
        catch (JsonException ex)
        {
            Log.Warning(ex, "Malformed ScoringLogicConfig JSON: {Json}", json);
            return ("penalty", false);
        }
    }
}
