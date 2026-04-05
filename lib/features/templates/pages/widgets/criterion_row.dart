import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../models/template_dto.dart';
import 'flag_badge.dart';

/// Dense criterion row with label, points badge, CCP/RISK flags,
/// and an optional `ⓘ` info icon.
///
/// **Preview-only** — interactive inputs are intentionally omitted.
/// Descriptions are accessible on-demand via the `ⓘ` icon to keep
/// the row compact by default.
class CriterionRow extends StatelessWidget {
  final CriterionDto criterion;

  const CriterionRow({super.key, required this.criterion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bullet
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppTheme.sageGray.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),

          // Label
          Expanded(
            child: Text(
              criterion.label,
              style: AppFonts.displayStyle(
                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),

          // Points badge — only for scored input types
          if (criterion.pointsWeight != null &&
              criterion.inputType != 'text' &&
              criterion.inputType != 'single_choice' &&
              criterion.inputType != 'multi_choice') ...[
            const SizedBox(width: 8),
            Text(
              '${criterion.pointsWeight!.toStringAsFixed(1)} pts',
              style: AppFonts.serifStyle(
                fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],

          // CCP badge
          if (criterion.isCcp) ...[
            const SizedBox(width: 6),
            FlagBadge(label: 'CCP', color: AppTheme.warning),
          ],

          // RISK badge
          if (criterion.isRisk) ...[
            const SizedBox(width: 6),
            FlagBadge(label: 'RISK', color: theme.colorScheme.error),
          ],

          // Info icon — on-demand rubric access (only when description exists)
          if (criterion.description != null &&
              criterion.description!.isNotEmpty) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Criterion Description'),
                  content: SingleChildScrollView(
                    child: Text(criterion.description!),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('CLOSE'),
                    ),
                  ],
                ),
              ),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
