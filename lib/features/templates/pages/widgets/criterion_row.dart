import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/theme/app_theme.dart';
import '../../models/template_dto.dart';
import 'flag_badge.dart';

/// Dense criterion row with label, points badge, and CCP/RISK flags.
class CriterionRow extends StatelessWidget {
  final CriterionDto criterion;

  const CriterionRow({super.key, required this.criterion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    fontSize: 13,
                    color: AppTheme.charcoal.withValues(alpha: 0.85),
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
                    fontSize: 12,
                    color: AppTheme.charcoal.withValues(alpha: 0.45),
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
            ],
          ),

          // Description (QC templates show the standard/requirement)
          if (criterion.description != null &&
              criterion.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 2),
              child: Text(
                criterion.description!,
                style: AppFonts.displayStyle(
                  fontSize: 11,
                  color: AppTheme.charcoal.withValues(alpha: 0.4),
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
