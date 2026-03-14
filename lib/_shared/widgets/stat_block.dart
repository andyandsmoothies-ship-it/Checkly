import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Asymmetric stat block — large accent-colored container with serif number.
///
/// Matches the Apothecary reference: bottom-aligned content, configurable
/// background colour and height.
/// ```dart
/// StatBlock(
///   value: '3',
///   label: 'Open Action Plans',
///   color: AppColors.softPeach,
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
    this.color = AppColors.softPeach,
    this.height = 160,
    this.uppercaseLabel = false,
    this.bordered = false,
  });

  /// Compact bordered variant — white bg with sage border.
  const StatBlock.compact({
    super.key,
    required this.value,
    required this.label,
    this.height = 128,
  }) : color = Colors.white,
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
        border: bordered
            ? Border.all(color: AppColors.sageGray.withValues(alpha: 0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            value,
            style: AppFonts.serifStyle(
              fontSize: height > 140 ? 36 : 24,
              color: AppColors.charcoal,
            ),
          ),
          SizedBox(height: height > 140 ? 8 : 4),
          Text(
            uppercaseLabel ? label.toUpperCase() : label,
            style: AppFonts.displayStyle(
              fontSize: uppercaseLabel ? 10 : 14,
              fontWeight: FontWeight.w500,
              color: AppColors.charcoal.withValues(
                alpha: uppercaseLabel ? 0.6 : 0.8,
              ),
              letterSpacing: uppercaseLabel ? -0.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}
