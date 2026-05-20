import 'package:flutter/material.dart';

import '../../../../_shared/theme/app_theme.dart';
import '../../../stores/model/store_dto.dart';

class StoreCard extends StatelessWidget {
  final StoreDto store;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;

  const StoreCard({
    super.key,
    required this.store,
    this.onEdit,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = store.isActive ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        mouseCursor: onEdit == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + status
              Row(
                children: [
                  // Store icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: isActive ? theme.colorScheme.primary : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isActive ? null : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isActive ? AppTheme.success : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // 3-dot menu — hidden in read-only mode
                  if (onEdit != null || onToggleActive != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'toggle') onToggleActive?.call();
                      },
                      itemBuilder: (ctx) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Store'),
                          ),
                        if (onToggleActive != null)
                          PopupMenuItem(
                            value: 'toggle',
                            child: Text(isActive ? 'Deactivate' : 'Activate'),
                          ),
                      ],
                    ),
                ],
              ),

              // Address (if present)
              if (store.address != null && store.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        store.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Manager row (always visible)
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final smText = store.managerName ?? 'Unassigned';
                  final isUnassigned = store.managerName == null;

                  if (isUnassigned) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 12,
                            color: AppTheme.warningText,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'SM: Unassigned',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.warningText,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'SM: $smText',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
