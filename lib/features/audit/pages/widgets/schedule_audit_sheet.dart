import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../admin/widgets/schedule_audit_form.dart';
import '../../manager/history_manager.dart';

final _di = GetIt.instance;

/// Displays the schedule/assign-task bottom sheet.
///
/// Extracted from [_HistoryPageState._showScheduleSheet] to keep
/// the main page file below the 400-line architectural threshold.
void showScheduleSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Assign Task',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ScheduleAuditForm(
              onSuccess: () {
                Navigator.pop(sheetContext);
                _di<HistoryManager>().loadHistory();
              },
            ),
          ),
        ],
      ),
    ),
  );
}
