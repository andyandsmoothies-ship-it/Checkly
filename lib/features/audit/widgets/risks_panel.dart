import 'package:flutter/material.dart';

import '../manager/audit_manager.dart';

void showRisksPanel(BuildContext context, AuditManager manager) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return ListenableBuilder(
        listenable: manager,
        builder: (context, _) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    '⚠ Critical Risks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Tap to flag a risk. This will zero the audit score.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (manager.availableRisks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No global risks configured yet.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: manager.availableRisks.length,
                      itemBuilder: (context, index) {
                        final risk = manager.availableRisks[index];
                        final isTriggered = manager.triggeredRiskIds.contains(
                          risk.id,
                        );
                        return ListTile(
                          leading: Icon(
                            isTriggered ? Icons.warning : Icons.warning_amber,
                            color: isTriggered
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.outline,
                          ),
                          title: Text(risk.label),
                          trailing: FilterChip(
                            label: Text(
                              isTriggered ? 'Triggered' : 'Flag Risk',
                              style: TextStyle(
                                color: isTriggered
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                fontWeight: isTriggered
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                            selected: isTriggered,
                            selectedColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            checkmarkColor: Theme.of(context).colorScheme.error,
                            onSelected: (selected) {
                              if (selected) {
                                manager.triggerGlobalRisk(risk.id);
                              } else {
                                manager.unTriggerGlobalRisk(risk.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    },
  );
}
