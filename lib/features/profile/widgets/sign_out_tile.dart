import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/services/sync_engine.dart';
import '../../auth/manager/auth_manager.dart';

final _di = GetIt.instance;

/// Sign-out tile with 3-case outbox-aware confirmation dialog.
///
/// Outbox status is fetched via SyncEngine to avoid UI coupling to DAOs.
class SignOutTile extends StatefulWidget {
  const SignOutTile({super.key});

  @override
  State<SignOutTile> createState() => _SignOutTileState();
}

class _SignOutTileState extends State<SignOutTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        'SIGN OUT',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _confirmSignOut(context),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final syncable = await _di<SyncEngine>().syncableCount();
    final exhausted = await _di<SyncEngine>().exhaustedCount();

    if (!context.mounted) return;

    // Case 1: Recoverable submissions in-flight — warn but allow escape.
    if (syncable > 0) {
      final shouldForce = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Audits Still Uploading'),
          content: Text(
            'You have $syncable audit${syncable == 1 ? '' : 's'} still uploading. '
            'Signing out now will permanently delete ${syncable == 1 ? 'it' : 'them'} from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Wait'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Sign Out Anyway',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldForce == true) {
        _di<AuthManager>().logout();
      }
      return;
    }

    // Case 2: Only exhausted (permanently failed) rows remain — warn + allow escape.
    if (exhausted > 0) {
      final shouldForce = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Unsynced Audits Will Be Lost'),
          content: Text(
            '$exhausted audit${exhausted == 1 ? '' : 's'} failed to upload and '
            'cannot be recovered. Signing out will permanently delete '
            '${exhausted == 1 ? 'it' : 'them'} from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: Text(
                'Sign Out Anyway',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (shouldForce == true) {
        _di<AuthManager>().logout();
      }
      return;
    }

    // Case 3: Outbox is clean — standard confirmation.
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _di<AuthManager>().logout();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
