import 'package:flutter/material.dart';

// ============================================================
// Section Navigation Bar — Submit always visible (Slice 1)
// ============================================================

class AuditSectionNavBar extends StatelessWidget {
  final int currentSection;
  final int totalSections;
  final bool allAnswered;
  final bool isSubmitting;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onSubmit;

  const AuditSectionNavBar({
    super.key,
    required this.currentSection,
    required this.totalSections,
    required this.allAnswered,
    required this.isSubmitting,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Prev button
            IconButton.filledTonal(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left, size: 22),
              tooltip: 'Previous section',
            ),

            const SizedBox(width: 4),

            // Section dots (fallback to text for >8 sections)
            if (totalSections <= 8)
              Semantics(
                label: 'Section ${currentSection + 1} of $totalSections',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    totalSections,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == currentSection ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == currentSection
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                '${currentSection + 1}/$totalSections',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

            const SizedBox(width: 4),

            // Next button
            IconButton.filledTonal(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right, size: 22),
              tooltip: 'Next section',
            ),

            const Spacer(),

            // Submit button — ALWAYS visible (Slice 1)
            FilledButton.icon(
              onPressed: !isSubmitting ? onSubmit : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 18),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
