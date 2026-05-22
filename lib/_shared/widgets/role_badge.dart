import 'package:flutter/material.dart';

import '../constants/app_roles.dart';
import '../widgets/primitives/primitives.dart';

enum RoleBadgeSize { small, medium }

/// A unified badge for displaying user roles across the application.
///
/// Refactored to use [PillChip] primitives for consistent gamified styling.
class RoleBadge extends StatelessWidget {
  final String role;
  final RoleBadgeSize size;

  const RoleBadge({
    super.key,
    required this.role,
    this.size = RoleBadgeSize.small,
  });

  static PillChipType _getRoleChipType(String role) {
    return switch (role) {
      AppRoles.admin => PillChipType.purple,
      AppRoles.auditor => PillChipType.blue,
      AppRoles.storeManager => PillChipType.yellow,
      AppRoles.areaManager => PillChipType.green,
      _ => PillChipType.blue,
    };
  }

  static String _getRoleLabel(String role) {
    return switch (role) {
      AppRoles.admin => 'Admin',
      AppRoles.auditor => 'Auditor',
      AppRoles.storeManager => 'Store Mgr',
      AppRoles.areaManager => 'Area Mgr',
      _ => role,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PillChip(label: _getRoleLabel(role), type: _getRoleChipType(role));
  }
}
