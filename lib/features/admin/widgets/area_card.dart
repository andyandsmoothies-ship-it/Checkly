import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../_shared/theme/app_fonts.dart';
import '../../../_shared/theme/app_theme.dart';

class AreaCard extends StatelessWidget {
  final Map<String, dynamic> area;
  final VoidCallback onTap;

  const AreaCard({super.key, required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = area['name'] as String? ?? 'Unnamed';
    final description = area['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.sageGray.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppFonts.displayStyle(
                        fontSize: Theme.of(
                          context,
                        ).textTheme.titleSmall?.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Store & user count badges
                    _buildBadges(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    final storeCount = area['storeCount'] as int? ?? 0;
    final managerName = area['managerName'] as String?;
    final areaId = area['id'] as String? ?? '';

    if (storeCount == 0 && managerName == null) {
      return Text(
        'No stores yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: [
        if (storeCount > 0)
          ActionChip(
            avatar: const Icon(Icons.store, size: 14),
            label: Text('$storeCount Stores'),
            visualDensity: VisualDensity.compact,
            onPressed: () => context.push('/admin/stores?areaId=$areaId'),
          ),
        ActionChip(
          avatar: const Icon(Icons.person, size: 14),
          label: Text(
            managerName != null ? 'AM: $managerName' : 'AM: Unassigned',
          ),
          visualDensity: VisualDensity.compact,
          onPressed: managerName != null
              ? () => context.push('/admin/users?search=$managerName')
              : null,
        ),
      ],
    );
  }
}
