import 'package:flutter/material.dart';

import '../../../_shared/theme/app_theme.dart';
import '../../templates/models/template_dto.dart';
import '../manager/audit_manager.dart';

/// Bottom sheet that lets the auditor jump directly to any section.
///
/// Receives [currentSection] as a value (not the full page state)
/// to stay stateless and avoid over-coupling. Section selection
/// is propagated back via [onSectionSelected].
class AuditQuickJumpSheet extends StatelessWidget {
  final AuditManager manager;
  final TemplateTreeDto template;
  final int currentSection;
  final ValueChanged<int> onSectionSelected;

  const AuditQuickJumpSheet({
    super.key,
    required this.manager,
    required this.template,
    required this.currentSection,
    required this.onSectionSelected,
  });

  // ── Pure utility helpers (mirrors page-level private methods) ──

  int _groupAnsweredCount(GroupDto group) {
    int count = 0;
    for (final c in group.criteria) {
      final a = manager.answers[c.id];
      if (a != null && (a.value != null || a.numericValue != null)) count++;
    }
    for (final child in group.children) {
      count += _groupAnsweredCount(child);
    }
    return count;
  }

  int _groupTotalCount(GroupDto group) {
    int count = group.criteria.length;
    for (final child in group.children) {
      count += _groupTotalCount(child);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Jump to Section',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(template.groups.length, (i) {
                  final group = template.groups[i];
                  final answered = _groupAnsweredCount(group);
                  final total = _groupTotalCount(group);
                  final isCurrent = i == currentSection;
                  final isComplete = answered >= total;

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: isComplete
                          ? AppTheme.success.withAlpha(30)
                          : isCurrent
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      child: isComplete
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.success,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: theme.textTheme.labelSmall?.fontSize,
                                color: isCurrent
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                    title: Text(
                      group.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      '$answered / $total done',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isComplete
                            ? AppTheme.success
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: isCurrent,
                    onTap: () {
                      Navigator.pop(context);
                      onSectionSelected(i);
                    },
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
