import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../../_shared/theme/app_fonts.dart';

class TemplateFooter extends StatelessWidget {
  final int totalPoints;
  final double totalDensity;
  final bool densityEnabled;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;

  const TemplateFooter({
    super.key,
    required this.totalPoints,
    required this.totalDensity,
    required this.densityEnabled,
    required this.canSave,
    required this.saving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: AppTheme.sageGray.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // PTS badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.oatmeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalPoints PTS',
                style: AppFonts.serifStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Density badge — only shown when density enabled (Rule 6)
            if (densityEnabled) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (totalDensity - 100).abs() < 0.01
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.softPeach,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${totalDensity.toStringAsFixed(1)}%',
                  style: AppFonts.serifStyle(
                    fontSize: 14,
                    color: (totalDensity - 100).abs() < 0.01
                        ? AppTheme.success
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Save button — disabled when canSave is false (Rule 1)
            FilledButton.icon(
              onPressed: (saving || !canSave) ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(saving ? 'Saving...' : 'Save Template'),
            ),
          ],
        ),
      ),
    );
  }
}
