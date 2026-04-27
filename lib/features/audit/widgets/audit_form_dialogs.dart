import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/services/gps_service.dart';
import '../../../_shared/theme/app_theme.dart';
import '../../stores/manager/store_manager.dart';
import '../manager/audit_manager.dart';

final _di = GetIt.instance;

Future<bool?> showResumeDraftDialog(
  BuildContext context,
  String draftAge,
) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Resume draft?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have an unsaved draft for this audit (saved $draftAge). '
            'Would you like to resume where you left off?',
          ),
          const SizedBox(height: 12),
          Text(
            'This draft is saved only on this device. It will expire in 14 days.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Discard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Resume'),
        ),
      ],
    ),
  );
}

Future<bool?> showSubmitConfirmDialog(
  BuildContext context, {
  required int answered,
  required int total,
  required double? liveScore,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Submit Audit?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? answered / total : 0,
              minHeight: 6,
              backgroundColor: Theme.of(
                ctx,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 12),
          Text('Criteria answered: $answered / $total'),
          const SizedBox(height: 4),
          Text(
            liveScore != null
                ? 'Score: ${liveScore.toStringAsFixed(1)}'
                : 'Survey — No Score',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: liveScore != null && liveScore >= 80
                  ? AppTheme.success
                  : liveScore != null && liveScore >= 50
                  ? AppTheme.warning
                  : Theme.of(ctx).colorScheme.error,
            ),
          ),
          if (answered < total) ...[
            const SizedBox(height: 12),
            Text(
              '⚠ ${total - answered} criteria unanswered',
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Submit Action'),
        ),
      ],
    ),
  );
}

Future<void> checkAndSetGps(BuildContext context, AuditManager manager) async {
  try {
    final gps = _di<GpsService>();
    final pos = await gps.getCurrentPosition();
    if (pos != null) {
      manager.setGps(pos.latitude, pos.longitude);

      final storeManager = _di<StoreManager>();
      final stores = storeManager.stores.value;
      final store = stores.where((s) => s.id == manager.storeId).firstOrNull;
      if (store != null && store.gpsLat != null && store.gpsLng != null) {
        final result = gps.checkProximity(
          userLat: pos.latitude,
          userLng: pos.longitude,
          storeLat: store.gpsLat!,
          storeLng: store.gpsLng!,
        );
        // Show proximity warning BEFORE navigation to prevent SnackBar clipping
        if (!result.inRange && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unverified location — ${result.distance}m from store '
                '(max ${GpsService.maxDistanceMeters}m)',
              ),
              backgroundColor: AppTheme.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Location unavailable — submitting without GPS'),
        ),
      );
    }
  }
}
