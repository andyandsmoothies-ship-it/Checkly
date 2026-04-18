using System.Text.Json;
using System.Collections.Generic;
using System.Linq;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Services;

/// <summary>
/// Evaluates which answers should trigger an Action Plan based on
/// configurable rules stored in Criterion.Metadata.actionPlanTrigger.
///
/// Backward compatible: pass_fail criteria without a trigger definition
/// fall back to the legacy Value == "non_conform" check.
///
/// Cap: Maximum 10 triggered answers per evaluation to prevent AP explosion.
/// </summary>
public static class ActionPlanEvaluator
{
    private const int MaxTriggersPerSubmission = 10;

    /// <summary>
    /// Returns the subset of answers that should generate an ActionPlan.
    /// </summary>
    public static List<Answer> GetTriggeredAnswers(
        List<Answer> answers,
        List<Criterion> criteria)
    {
        var triggered = new List<Answer>();

        foreach (var answer in answers)
        {
            if (triggered.Count >= MaxTriggersPerSubmission)
                break;

            var criterion = criteria.FirstOrDefault(c => c.Id == answer.CriteriaId);
            if (criterion is null)
                continue;

            if (ShouldTrigger(answer, criterion))
                triggered.Add(answer);
        }

        return triggered;
    }

    private static bool HasNegativeSignal(Answer answer)
    {
        if (string.Equals(answer.Value, "non_conform", System.StringComparison.OrdinalIgnoreCase)) return true;
        if ((answer.NumericValue ?? 0) > 0) return true;
        if (!string.IsNullOrWhiteSpace(answer.Note)) return true;
        if (!string.IsNullOrWhiteSpace(answer.PhotoUrl)) return true;
        if (answer.IsRepeatedError == true) return true;
        return false;
    }

    private static bool ShouldTrigger(Answer answer, Criterion criterion)
    {
        // 1. Criticality Override: Any CCP or RISK criterion that has a negative signal MUST trigger an action plan.
        if ((criterion.IsRisk || criterion.IsCcp) && HasNegativeSignal(answer))
        {
            return true;
        }

        var trigger = ParseTrigger(criterion.Metadata);

        // No trigger defined → use legacy behavior
        if (trigger is null)
        {
            // Legacy: only pass_fail with "non_conform" triggers an AP
            return criterion.InputType == "pass_fail"
                && string.Equals(answer.Value, "non_conform", System.StringComparison.OrdinalIgnoreCase);
        }

        return trigger.Condition switch
        {
            "value_equals" => trigger.Values is not null
                && trigger.Values.Contains(answer.Value ?? ""),

            "value_in" => trigger.Values is not null
                && answer.Value is not null
                && trigger.Values.Any(v =>
                    answer.Value.Split(',', System.StringSplitOptions.TrimEntries)
                        .Contains(v)),

            "numeric_lt" => trigger.Threshold.HasValue
                && answer.NumericValue.HasValue
                && answer.NumericValue.Value < trigger.Threshold.Value,

            "numeric_gt" => trigger.Threshold.HasValue
                && answer.NumericValue.HasValue
                && answer.NumericValue.Value > trigger.Threshold.Value,

            "always" => true,

            "never" => false,

            // Unknown condition → no trigger (safe default)
            _ => false
        };
    }

    private static TriggerRule? ParseTrigger(string? metadata)
    {
        if (string.IsNullOrEmpty(metadata))
            return null;

        try
        {
            using var doc = JsonDocument.Parse(metadata);
            if (!doc.RootElement.TryGetProperty("actionPlanTrigger", out var triggerEl))
                return null;

            var condition = triggerEl.TryGetProperty("condition", out var condEl)
                ? condEl.GetString() : null;

            if (condition is null)
                return null;

            List<string>? values = null;
            if (triggerEl.TryGetProperty("values", out var valuesEl)
                && valuesEl.ValueKind == JsonValueKind.Array)
            {
                values = valuesEl.EnumerateArray()
                    .Select(v => v.GetString() ?? "")
                    .ToList();
            }

            decimal? threshold = null;
            if (triggerEl.TryGetProperty("threshold", out var threshEl)
                && threshEl.TryGetDecimal(out var t))
            {
                threshold = t;
            }

            return new TriggerRule(condition, values, threshold);
        }
        catch (JsonException)
        {
            return null; // Malformed metadata → no trigger
        }
    }

    private sealed record TriggerRule(
        string? Condition,
        List<string>? Values,
        decimal? Threshold);
}
