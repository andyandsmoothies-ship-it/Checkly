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
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Assign Task',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.maybePop(sheetContext),
                ),
              ],
            ),
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
