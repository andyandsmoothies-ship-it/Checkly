import 'package:meta/meta.dart';

abstract class SyncModule {
  int get priority;
  Future<void> executePull();
  Future<void> executePush();
}

abstract class BaseSyncModule implements SyncModule {
  BaseSyncModule({required void Function(int delaySecs) scheduleRetry})
    : _scheduleRetry = scheduleRetry;

  static const List<int> backoffDelays = [2, 4, 8, 60];

  final void Function(int delaySecs) _scheduleRetry;

  @override
  Future<void> executePull() async {}

  @override
  Future<void> executePush() async {}

  @protected
  Future<void> processQueue<T>(
    List<T> items, {
    required bool Function() isOnline,
    required int Function(T item) getRetryCount,
    required Future<void> Function(T item) push,
    Future<void> Function(T item)? onPushSucceeded,
    required Future<void> Function(T item) onSuccess,
    required Future<void> Function(T item, String error) onExhausted,
    required Future<void> Function(
      T item,
      int newRetryCount,
      DateTime nextRetry,
      String error,
    )
    onRetry,
    required bool Function(Object error) isFatalError,
    Future<void> Function(T item)? onConflict,
    Future<void> Function()? onOffline,
  }) async {
    for (final item in items) {
      if (!isOnline()) {
        await onOffline?.call();
        return;
      }

      try {
        await push(item);
        await onPushSucceeded?.call(item);
        await onSuccess(item);
      } catch (error) {
        if (isFatalError(error)) {
          await onExhausted(item, error.toString());
          continue;
        }

        if (error.toString().contains('409') && onConflict != null) {
          await onConflict(item);
          continue;
        }

        final currentRetries = getRetryCount(item);
        if (currentRetries < backoffDelays.length) {
          final delaySecs = backoffDelays[currentRetries];
          final nextRetry = DateTime.now().toUtc().add(
            Duration(seconds: delaySecs),
          );
          await onRetry(item, currentRetries + 1, nextRetry, error.toString());
          _scheduleRetry(delaySecs);
        } else {
          await onExhausted(item, 'Max retries exceeded');
        }
        break;
      }
    }
  }
}
