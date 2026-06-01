import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../manager/bod_analytics_data.dart';

/// Interactive modal sheet displaying sync telemetry for a store and triggering a live sync request.
class BodStoreSyncModal extends StatefulWidget {
  final BodStorePerformanceEntry store;

  const BodStoreSyncModal({super.key, required this.store});

  @override
  State<BodStoreSyncModal> createState() => _BodStoreSyncModalState();
}

class _BodStoreSyncModalState extends State<BodStoreSyncModal> {
  bool _isSyncing = false;
  bool _syncComplete = false;

  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    // Simulate database and transmission sync latency
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format human-readable relative time
    String timeAgo = 'Never synced';
    if (widget.store.lastSyncedAt != null) {
      final difference = DateTime.now().difference(widget.store.lastSyncedAt!);
      if (difference.inMinutes < 1) {
        timeAgo = 'Synced just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = 'Synced ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = 'Synced ${difference.inHours}h ago';
      } else {
        timeAgo = 'Synced ${difference.inDays}d ago';
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.store.storeName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.wolf),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.polar,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.swan, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sync,
                  color: widget.store.lastSyncedAt != null
                      ? AppColors.featherGreen
                      : AppColors.cardinal,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Database Sync',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.wolf,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeAgo,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.eel,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_syncComplete) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.seaSponge,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.turtle, width: 2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.featherGreen,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sync Complete!',
                    style: TextStyle(
                      color: AppColors.eel,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else if (_isSyncing) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.featherGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            FilledButton.icon(
              onPressed: _performSync,
              icon: const Icon(Icons.sync),
              label: const Text('Perform Live Sync'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.featherGreen,
                foregroundColor: AppColors.snow,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
