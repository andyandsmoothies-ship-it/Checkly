import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/checkly_theme_tokens.dart';

/// A custom, highly animated 3D switch designed to feel tactile and playful.
///
/// Implements standard track slide physics using [AnimatedAlign] and [AnimatedContainer].
/// Shifts track colors dynamically, switching instantly to [AppColors.featherGreen] when active.
class BubblySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BubblySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Resolve dynamic 3D depth from theme tokens
    final tokens = Theme.of(context).extension<ChecklyThemeTokens>();
    final depth3d = tokens?.button3dDepth ?? 4.0;
    final switchDepth = depth3d > 0 ? 2.0 : 0.0;

    final trackColor = value ? AppColors.featherGreen : AppColors.swan;
    // Solid bottom border for a tactile 3D slot appearance
    final bottomBorderColor = value
        ? Color.lerp(AppColors.featherGreen, Colors.black, 0.2) ??
              AppColors.featherGreen
        : Color.lerp(AppColors.swan, Colors.black, 0.15) ?? AppColors.swan;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: 58,
          height: 36,
          child: Stack(
            children: [
              // Track shadow/3D slot layer (only if switchDepth > 0)
              if (switchDepth > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: switchDepth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: bottomBorderColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              // Track face layer
              Positioned(
                left: 0,
                right: 0,
                bottom: switchDepth,
                top: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: value ? AppColors.featherGreen : AppColors.swan,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        alignment: value
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  offset: const Offset(0, 2),
                                  blurRadius: 2,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
