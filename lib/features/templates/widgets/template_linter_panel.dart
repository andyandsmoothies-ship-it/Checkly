import 'package:flutter/material.dart';
import '../models/lint_result.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../../../_shared/theme/app_colors.dart';

class TemplateLinterPanel extends StatelessWidget {
  final LintResult lintResult;
  final bool bypassLinter;
  final ValueChanged<bool> onBypassChanged;
  final ValueChanged<String>? onScrollToTarget;

  const TemplateLinterPanel({
    super.key,
    required this.lintResult,
    required this.bypassLinter,
    required this.onBypassChanged,
    this.onScrollToTarget,
  });

  @override
  Widget build(BuildContext context) {
    final hasErrors = lintResult.hasErrors;
    final totalIssuesCount =
        lintResult.errors.length + lintResult.warnings.length;

    // Header area with Bypass Checkbox
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.humpback),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Template Compliance Check',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalIssuesCount > 0) ...[
                const SizedBox(width: 8),
                PillChip(
                  label: '$totalIssuesCount',
                  type: hasErrors ? PillChipType.red : PillChipType.yellow,
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Skip Checks', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 4),
            Checkbox(
              value: bypassLinter,
              onChanged: (val) {
                if (val != null) {
                  onBypassChanged(val);
                }
              },
            ),
          ],
        ),
      ],
    );

    if (totalIssuesCount == 0) {
      return StrokeCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const Divider(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF388E3C)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No issues detected. Your template is fully compliant!',
                      style: TextStyle(
                        color: Color(0xFF388E3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StrokeCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 24),
          // Errors list
          if (lintResult.errors.isNotEmpty) ...[
            Text(
              'Compliance Issues',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.cardinal,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...lintResult.errors.map(
              (err) => _buildIssueRow(context, err, true),
            ),
            const SizedBox(height: 16),
          ],
          // Warnings list
          if (lintResult.warnings.isNotEmpty) ...[
            Text(
              'Improvement Suggestions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.fox,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...lintResult.warnings.map(
              (warn) => _buildIssueRow(context, warn, false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIssueRow(BuildContext context, LintIssue issue, bool isError) {
    final icon = Icon(
      isError ? Icons.error_outline : Icons.warning_amber_outlined,
      color: isError ? AppColors.cardinal : AppColors.fox,
    );

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (issue.ruleId.isNotEmpty)
                  Text(
                    'Rule: ${issue.ruleId}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (issue.targetId != null &&
        issue.targetId!.isNotEmpty &&
        onScrollToTarget != null) {
      return InkWell(
        onTap: () => onScrollToTarget!(issue.targetId!),
        borderRadius: BorderRadius.circular(8),
        child: row,
      );
    }

    return row;
  }
}
