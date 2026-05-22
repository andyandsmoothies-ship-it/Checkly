import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Asymmetric stat block — large accent-colored container with serif number.
///
/// Refactored to use Swan borders on the compact variant and brand pastels as defaults.
/// ```dart
/// StatBlock(
///   value: '3',
///   label: 'Open Action Plans',
///   color: AppColors.walkingFish,
///   height: 160,
/// )
/// StatBlock.compact(
///   value: '24',
///   label: 'AUDITS',
///   height: 128,
/// )
/// ```
class StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double height;
  final bool uppercaseLabel;
  final bool bordered;

  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.walkingFish,
    this.height = 160,
    this.uppercaseLabel = false,
    this.bordered = false,
  });

  /// Compact bordered variant — polar bg with Swan border.
  const StatBlock.compact({
    super.key,
    required this.value,
    required this.label,
    this.height = 128,
  }) : color = AppColors.polar,
       uppercaseLabel = true,
       bordered = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: bordered ? Border.all(color: AppColors.swan, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: AppFonts.serifStyle(
              fontSize: height > 140 ? 36 : 24,
              color: AppColors.eel,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: height > 140 ? 8 : 4),
          Text(
            uppercaseLabel ? label.toUpperCase() : label,
            style: AppFonts.displayStyle(
              fontSize: uppercaseLabel ? 10 : 14,
              fontWeight: FontWeight.w700,
              color: AppColors.wolf,
              letterSpacing: uppercaseLabel ? 1.0 : 0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
