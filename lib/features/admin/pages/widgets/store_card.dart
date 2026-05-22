import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';
import '../../../stores/model/store_dto.dart';
import '../../../../_shared/widgets/primitives/primitives.dart';

/// Reusable card widget for displaying stores inside the administrative dashboard.
/// Leverages the [UniversalListCard] layout primitive for premium high-contrast aesthetics.
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

    return UniversalListCard(
      title: store.name,
      titleStyle: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: isActive ? null : Colors.grey,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onEdit,
      leading: Container(
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
      badges: [
        PillChip(
          label: isActive ? 'Active' : 'Inactive',
          type: isActive ? PillChipType.green : PillChipType.red,
        ),
      ],
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (store.address != null && store.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.wolf,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    store.address!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.wolf,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              final smText = store.managerName ?? 'Unassigned';
              final isUnassigned = store.managerName == null;

              if (isUnassigned) {
                return const PillChip(
                  label: 'SM: Unassigned',
                  type: PillChipType.yellow,
                  icon: Icon(
                    Icons.warning_amber,
                    size: 12,
                    color: AppColors.fox,
                  ),
                );
              }

              return Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.wolf,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'SM: $smText',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.wolf,
                        fontWeight: FontWeight.w600,
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
      trailing: (onEdit != null || onToggleActive != null)
          ? PopupMenuButton<String>(
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
                  const PopupMenuItem(value: 'edit', child: Text('Edit Store')),
                if (onToggleActive != null)
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isActive ? 'Deactivate' : 'Activate'),
                  ),
              ],
            )
          : null,
    );
  }
}
