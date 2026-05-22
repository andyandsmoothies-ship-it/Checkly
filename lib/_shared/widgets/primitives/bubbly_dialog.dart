import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// A custom, flat modal dialog featuring heavy rounded corners and high contrast borders.
///
/// Complies with Checkly's Duolingo aesthetic guidelines by utilizing 24px corner roundness,
/// zero elevation, and a distinct 2px [AppColors.swan] border wrap.
class BubblyDialog extends StatelessWidget {
  final Widget? title;
  final Widget content;
  final List<Widget> actions;

  const BubblyDialog({
    super.key,
    this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.swan, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.eel,
                ),
                child: title!,
              ),
              const SizedBox(height: 16),
            ],
            DefaultTextStyle(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: AppColors.wolf),
              child: content,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: action,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
