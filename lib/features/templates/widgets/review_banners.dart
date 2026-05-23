import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';

class ReviewValidationBanner extends StatelessWidget {
  final List<String> errors;

  const ReviewValidationBanner({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error, width: 1),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.cancel_outlined,
          color: theme.colorScheme.error,
          size: 20,
        ),
        title: Text(
          'Needs Attention — ${errors.length} issue${errors.length == 1 ? '' : 's'} to fix',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
        initiallyExpanded: false,
        children: errors
            .map(
              (e) => ListTile(
                dense: true,
                leading: Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  e,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ReviewQualityBanner extends StatelessWidget {
  final bool isV6Valid;
  final bool isProductionReady;
  final int sectionCount;
  final int totalCriteria;

  const ReviewQualityBanner({
    super.key,
    required this.isV6Valid,
    required this.isProductionReady,
    required this.sectionCount,
    required this.totalCriteria,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isV6Valid && isProductionReady) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.successContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$sectionCount sections, $totalCriteria criteria — Production ready',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.warningContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: AppTheme.warning,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Consider adding more — aim for 3+ sections with 5+ criteria for a thorough audit.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warning,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
