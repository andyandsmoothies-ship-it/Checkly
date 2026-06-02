import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/bod_analytics_data.dart';

/// Reusable widget for displaying the list of Recent Audits inside boardroom store detail sheets.
class RecentAuditsSection extends StatelessWidget {
  final List<RecentAuditEntry> recentAudits;
  final Color textColor;
  final bool isLight;

  const RecentAuditsSection({
    super.key,
    required this.recentAudits,
    required this.textColor,
    this.isLight = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (recentAudits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Recent Audits',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        ...recentAudits.map((audit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: UniversalListCard(
              title: 'Audit by ${audit.auditorName}',
              subtitle:
                  'Date: ${audit.date.length >= 10 ? audit.date.substring(0, 10) : audit.date}',
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLight
                      ? AppColors.walkingFish
                      : AppColors.walkingFish.withValues(
                          alpha: 0.2,
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: AppColors.cardinal,
                ),
              ),
              badges: [
                PillChip(
                  label: '${audit.score.toStringAsFixed(1)}%',
                  type: PillChipType.blue,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
