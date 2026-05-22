import 'package:flutter/material.dart';

import '../../../../_shared/constants/app_roles.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../../_shared/theme/app_fonts.dart';
import '../../../../_shared/widgets/role_badge.dart';

/// Premium identity card displayed at the top of the Profile page.
///
/// Shows a gradient background (primaryContainer → transparent), a radius-40
/// avatar with the user's initials, the full display name, email, and role
/// badge — all centered for a personal, premium feel.
///
/// Refactored to include a 2px Swan border, and role-based custom styled avatar
/// to perfectly match Checkly's premium bubbly visual identity.
class ProfileIdentityCard extends StatelessWidget {
  final String initials;
  final String displayName;
  final String email;
  final String role;

  const ProfileIdentityCard({
    super.key,
    required this.initials,
    required this.displayName,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final borderColor = isLight ? AppColors.swan : AppColors.swan.withAlpha(40);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.4),
            cs.primaryContainer.withValues(alpha: 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          _buildAvatar(context),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: AppFonts.displayStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isLight ? AppColors.eel : cs.onSurface,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: AppFonts.displayStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isLight ? AppColors.wolf : cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          RoleBadge(role: role, size: RoleBadgeSize.medium),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final Color avatarBg;
    final Color avatarText;
    final Color avatarBorder;

    switch (role) {
      case AppRoles.auditor:
        avatarBg = AppColors.seaSponge;
        avatarText = AppColors.eel;
        avatarBorder = AppColors.turtle;
        break;
      case AppRoles.storeManager:
        avatarBg = AppColors.canary;
        avatarText = AppColors.fox;
        avatarBorder = AppColors.duck;
        break;
      case AppRoles.areaManager:
        avatarBg = AppColors.iguana;
        avatarText = AppColors.humpback;
        avatarBorder = AppColors.blueJay;
        break;
      case AppRoles.admin:
        avatarBg = AppColors.walkingFish;
        avatarText = AppColors.cardinal;
        avatarBorder = AppColors.flamingo;
        break;
      default:
        avatarBg = AppColors.polar;
        avatarText = AppColors.wolf;
        avatarBorder = AppColors.swan;
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: avatarBorder, width: 2.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: avatarBg,
        child: Text(
          initials,
          style: AppFonts.displayStyle(
            color: avatarText,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
