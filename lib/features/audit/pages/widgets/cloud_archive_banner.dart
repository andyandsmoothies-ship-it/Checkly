import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../manager/history_manager.dart';

final _di = GetIt.instance;

/// Displays an informational banner when the user has archived audit records
/// that are not visible in the current local list.
///
/// Listens to [HistoryManager.hasArchivedRecords] via [ValueListenableBuilder]
/// and self-hides when no archived records exist.
class CloudArchiveBanner extends StatelessWidget {
  const CloudArchiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = _di<HistoryManager>();
    final theme = Theme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: manager.hasArchivedRecords,
      builder: (context, hasArchived, _) {
        if (!hasArchived) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.archive_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Some older audits were archived to save space.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => manager.searchCloudArchive(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Search archive'),
              ),
            ],
          ),
        );
      },
    );
  }
}
