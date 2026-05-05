import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../manager/admin_user_manager.dart';

class UserManagementDialogs {
  UserManagementDialogs._();

  static Future<bool> confirmDeactivate(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User?'),
        content: Text(
          'Are you sure you want to deactivate ${user['fullName']}? '
          'They will lose access to the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static Future<bool?> confirmTransfer(
    BuildContext context,
    String existingManagerName,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transfer Store Assignment?'),
        content: Text(
          'This position is currently held by $existingManagerName. '
          'Do you want to remove them and assign this user instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Transfer'),
          ),
        ],
      ),
    );
  }

  static void showResetPasswordDialog({
    required BuildContext sheetCtx,
    required String userId,
    required String userName,
    required AdminUserManager manager,
  }) {
    final passCtrl = TextEditingController();
    String? passError;

    showDialog(
      context: sheetCtx,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (dlgCtx, setDlgState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Set a new password for $userName'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      errorText: passError,
                      helperText: passError == null
                          ? 'Min 8 chars: uppercase, digit, special char'
                          : null,
                    ),
                    onChanged: (_) {
                      if (passError != null) {
                        setDlgState(() => passError = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dlgCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final pass = passCtrl.text;
                    if (pass.isEmpty) {
                      setDlgState(() => passError = 'Password is required');
                      return;
                    }
                    try {
                      await manager.resetPassword(userId, pass);
                      if (dlgCtx.mounted) {
                        Navigator.of(dlgCtx).pop(); // Close dialog
                        Navigator.of(sheetCtx).pop(); // Close edit sheet
                        ScaffoldMessenger.of(dlgCtx).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset successfully'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    } catch (e) {
                      setDlgState(
                        () => passError =
                            'We couldn\'t reset the password. Please try again.',
                      );
                    }
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
