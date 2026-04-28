import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../../_shared/utils/date_format_utils.dart';

/// Compact deadline warning banner.
@visibleForTesting
class DeadlineBanner extends StatelessWidget {
  final DateTime deadline;
  const DeadlineBanner({required this.deadline, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: AppTheme.warning),
          const SizedBox(width: 8),
          Text(
            'Next Action Plan Deadline: ${timeAgo(deadline)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
