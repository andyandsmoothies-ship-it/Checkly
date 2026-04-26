import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A banner displaying a rejected offline evidence payload (stale_conflict).
/// Allows the Store Manager to recover their typed text (Copy) and clear the outbox row (Dismiss).
class StaleConflictBanner extends StatelessWidget {
  final String correctionPlan;
  final String evidenceNote;
  final VoidCallback onDismiss;

  const StaleConflictBanner({
    super.key,
    required this.correctionPlan,
    required this.evidenceNote,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your offline evidence was not synced — this plan was already closed.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            'Correction Plan:\n$correctionPlan\n\nEvidence Note:\n${evidenceNote.isEmpty ? '(none)' : evidenceNote}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text:
                          'Correction Plan:\n$correctionPlan\n\nEvidence Note:\n${evidenceNote.isEmpty ? '(none)' : evidenceNote}',
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                child: const Text('Copy'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onDismiss,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
