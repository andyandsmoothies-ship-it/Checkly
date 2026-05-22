import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/widgets/primitives/primitives.dart';
import '../../auth/manager/auth_manager.dart';

final _di = GetIt.instance;

/// Shown when a user has logged in but has no role assigned yet.
/// They must wait for an admin to assign their role.
class AccessPendingPage extends StatelessWidget {
  const AccessPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = _di<AuthManager>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hourglass container with high-contrast, flat borders
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.canary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bee, width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 64,
                    color: AppColors.fox,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Pending',
                  style: AppFonts.displayStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your account has been created, but you don\'t have a role assigned yet.\n\n'
                  'Please contact your administrator to get access.',
                  textAlign: TextAlign.center,
                  style: AppFonts.displayStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.wolf,
                  ),
                ),
                const SizedBox(height: 32),
                BubblyButton(
                  onPressed: () async {
                    await auth.logout();
                  },
                  color: AppColors.polar,
                  textColor: AppColors.eel,
                  icon: const Icon(Icons.logout, color: AppColors.eel),
                  label: 'Sign Out',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
