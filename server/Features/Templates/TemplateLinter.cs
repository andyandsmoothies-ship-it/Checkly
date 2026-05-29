using System;
using System.Collections.Generic;
using System.Linq;
using Checkly.Api.Common.Scoring;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// Stateless server-side template linter for evaluating audit template trees.
/// </summary>
public static class TemplateLinter
{
    public static LintResult Run(SaveTemplateTree.SaveTreeRequest request, string templateType)
    {
        var errors = new List<LintIssue>();
        var warnings = new List<LintIssue>();

        // 1. Empty Structure Check (Blocking Rule)
        if (request.Groups == null || request.Groups.Count == 0)
        {
            errors.Add(new LintIssue(
                "EmptyStructureCheck",
                "Template must contain at least one group.",
                null,
                "Error"));
            return new LintResult(errors, warnings);
        }

        // Flatten the tree for easy single-pass validation checks
        var flatGroups = new List<SaveTemplateTree.SaveGroupRequest>();
        var flatCriteria = new List<SaveTemplateTree.SaveCriterionRequest>();
        Flatten(request.Groups, flatGroups, flatCriteria);

        // 2. Empty Section Name (Blocking Rule)
        foreach (var g in flatGroups)
        {
            if (string.IsNullOrWhiteSpace(g.Title))
            {
                errors.Add(new LintIssue(
                    "EmptySectionName",
                    "Group title cannot be empty.",
                    g.Id,
                    "Error"));
            }
        }

        // 3. Penalty Mode Group Sum (Blocking Rule)
        var (scoringMode, progressiveRepeat) = ScoringConfigParser.Parse(request.ScoringLogicConfig);
        if (!string.Equals(templateType, "survey", StringComparison.OrdinalIgnoreCase) &&
            string.Equals(scoringMode, "penalty", StringComparison.OrdinalIgnoreCase))
        {
            decimal sum = request.Groups.Sum(g => g.Weight ?? 0m);
            if (sum != 100m)
            {
                errors.Add(new LintIssue(
                    "PenaltyModeGroupSum",
                    "Group weights must sum to exactly 100% in penalty mode.",
                    null,
                    "Error"));
            }
        }

        // 4. Duplicate ID Check (Blocking Rule)
        var seenIds = new HashSet<Guid>();
        foreach (var g in flatGroups)
        {
            if (g.Id.HasValue && g.Id != Guid.Empty)
            {
                if (!seenIds.Add(g.Id.Value))
                {
                    errors.Add(new LintIssue(
                        "DuplicateIdCheck",
                        $"Duplicate ID '{g.Id.Value}' detected in group '{g.Title}'.",
                        g.Id.Value,
                        "Error"));
                }
            }
        }
        foreach (var c in flatCriteria)
        {
            if (c.Id.HasValue && c.Id != Guid.Empty)
            {
                if (!seenIds.Add(c.Id.Value))
                {
                    errors.Add(new LintIssue(
                        "DuplicateIdCheck",
                        $"Duplicate ID '{c.Id.Value}' detected in criterion '{c.Label}'.",
                        c.Id.Value,
                        "Error"));
                }
            }
        }

        // 5. Max Nesting Depth Exceeded (Blocking Rule)
        CheckDepth(request.Groups, 1, errors);

        // ─── Advisory Rules (Warnings) ───────────────────────────────────────

        // 6. Mixed Scored and Unscored Criteria Warning
        if (string.Equals(templateType, "qc", StringComparison.OrdinalIgnoreCase))
        {
            bool hasScored = flatCriteria.Any(c => (c.PointsWeight ?? 0) > 0);
            bool hasUnscored = flatCriteria.Any(c => (c.PointsWeight ?? 0) == 0);
            if (hasScored && hasUnscored)
            {
                warnings.Add(new LintIssue(
                    "MixedAuditWarning",
                    "Mixed scored/unscored criteria — score will be NULL on dashboards",
                    null,
                    "Warning"));
            }
        }

        // 7. Silent Risk in Survey Warning
        if (string.Equals(templateType, "survey", StringComparison.OrdinalIgnoreCase))
        {
            foreach (var c in flatCriteria)
            {
                if (c.IsRisk)
                {
                    warnings.Add(new LintIssue(
                        "SilentRiskInSurvey",
                        "Silent risk in survey",
                        c.Id,
                        "Warning"));
                }
            }
        }

        // 8. Progressive Zero Impact Warning
        if (progressiveRepeat)
        {
            foreach (var c in flatCriteria)
            {
                var impact = c.MinusImpact ?? c.PointsWeight ?? 0m;
                if (impact == 0m)
                {
                    warnings.Add(new LintIssue(
                        "ProgressiveZeroImpact",
                        "Progressive repeat penalty has no impact due to zero/null minusImpact or weight.",
                        c.Id,
                        "Warning"));
                }
            }
        }

        return new LintResult(errors, warnings);
    }

    private static void Flatten(
        List<SaveTemplateTree.SaveGroupRequest> groups,
        List<SaveTemplateTree.SaveGroupRequest> flatGroups,
        List<SaveTemplateTree.SaveCriterionRequest> flatCriteria)
    {
        if (groups == null) return;
        foreach (var g in groups)
        {
            flatGroups.Add(g);
            if (g.Criteria != null)
            {
                foreach (var c in g.Criteria)
                {
                    flatCriteria.Add(c);
                }
            }
            Flatten(g.Children, flatGroups, flatCriteria);
        }
    }

    private static void CheckDepth(List<SaveTemplateTree.SaveGroupRequest> groups, int currentDepth, List<LintIssue> errors)
    {
        if (groups == null) return;
        foreach (var g in groups)
        {
            if (currentDepth >= 3)
            {
                errors.Add(new LintIssue(
                    "MaxNestingDepthExceeded",
                    "Maximum nesting depth exceeded (only 2 levels allowed).",
                    g.Id,
                    "Error"));
            }
            CheckDepth(g.Children, currentDepth + 1, errors);
        }
    }
}
