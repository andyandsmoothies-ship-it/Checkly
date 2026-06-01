import 'package:flutter/material.dart';

class BuilderValidationBanner extends StatelessWidget {
  final int errorCount;
  final VoidCallback onDismiss;

  const BuilderValidationBanner({
    super.key,
    required this.errorCount,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$errorCount issue${errorCount == 1 ? '' : 's'} found. Fix before saving.',
              style: TextStyle(
                fontSize: theme.textTheme.bodySmall?.fontSize,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onDismiss,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
