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
              'Please note: ${total - answered} questions are still unanswered.',
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
                'Location verification failed — you are ${result.distance} meters away from the store '
                '(max ${GpsService.maxDistanceMeters} meters).',
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
          content: Text('📍 Location services are unavailable. Your audit will be saved without coordinate pinning.'),
        ),
      );
    }
  }
}

Future<void> showGeofenceBlockDialog({
  required BuildContext context,
  required int? distanceMeters,
  required int allowedRadius,
  required bool gpsFailed,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.location_off_rounded,
            color: Theme.of(ctx).colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Submission Blocked',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This audit enforces strict geofencing. Submission is blocked because:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (gpsFailed)
            const Text(
              '• GPS coordinates could not be resolved. A precise GPS signal is required to submit this audit.',
            )
          else
            Text(
              '• You are located $distanceMeters meters away from the store. The maximum allowed geofence boundary is $allowedRadius meters.',
            ),
          const SizedBox(height: 16),
          Text(
            'Please move inside the store boundaries and try again.',
            style: TextStyle(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool?> showGeofenceWarningDialog({
  required BuildContext context,
  required int? distanceMeters,
  required int allowedRadius,
  required bool gpsFailed,
}) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 28,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Geofence Warning',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You are outside the store boundaries. Would you like to bypass this warning and submit anyway?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          if (gpsFailed)
            const Text(
              '• GPS coordinates could not be resolved. This submission will be marked as bypassed without a distance measurement.',
            )
          else
            Text(
              '• You are located $distanceMeters meters away from the store (maximum allowed: $allowedRadius meters).',
            ),
          const SizedBox(height: 16),
          Text(
            'Note: Your GPS coordinates and bypass actions will be logged in the database outbox telemetry.',
            style: TextStyle(
              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel Submission'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.warning,
            foregroundColor: Colors.white,
          ),
          child: const Text('Bypass & Submit'),
        ),
      ],
    ),
  );
}
