import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../constants/app_roles.dart';

/// A circular avatar wrapper rendering high-contrast initials on pastel backdrops.
///
/// Designed to visually map user roles (Admin, Auditor, Store Manager, Area Manager)
/// to their corresponding gamified theme color keys with tactile 2px borders.
class PastelAvatar extends StatelessWidget {
  final String name;
  final String role;
  final double size;

  const PastelAvatar({
    super.key,
    required this.name,
    required this.role,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (role) {
      case AppRoles.admin:
        backgroundColor = AppColors.walkingFish;
        textColor = AppColors.cardinal;
        borderColor = AppColors.flamingo;
        break;
      case AppRoles.auditor:
        backgroundColor = AppColors.seaSponge;
        textColor = const Color(0xFF388E3C);
        borderColor = AppColors.turtle;
        break;
      case AppRoles.storeManager:
        backgroundColor = AppColors.canary;
        textColor = AppColors.fox;
        borderColor = AppColors.duck;
        break;
      case AppRoles.areaManager:
        backgroundColor = AppColors.iguana;
        textColor = AppColors.humpback;
        borderColor = AppColors.blueJay;
        break;
      default:
        backgroundColor = const Color(0xFFFBE4FF);
        textColor = AppColors.beetle;
        borderColor = AppColors.starfish;
        break;
    }

    final initials = _getInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
