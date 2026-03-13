import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../auth/manager/auth_manager.dart';

final _di = GetIt.instance;

/// Shown when a user has logged in but has no role assigned yet.
/// They must wait for an admin to assign their role.
class AccessPendingPage extends StatelessWidget {
  const AccessPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = _di<AuthManager>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 64,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Pending',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been created, but you don\'t have a role assigned yet.\n\n'
                  'Please contact your administrator to get access.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
