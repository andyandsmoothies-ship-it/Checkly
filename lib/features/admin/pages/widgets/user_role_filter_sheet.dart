import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

/// Renders a sheet allowing users to filter user accounts by role.
void showUserRoleFilterSheet({
  required BuildContext context,
  required String currentFilter,
  required int Function(String) countByRole,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final roles = [
        {'id': 'all', 'label': 'All Users', 'count': countByRole('all')},
        {'id': 'admin', 'label': 'Admin', 'count': countByRole('admin')},
        {'id': 'auditor', 'label': 'Auditor', 'count': countByRole('auditor')},
        {'id': 'area_manager', 'label': 'Area Manager', 'count': countByRole('area_manager')},
        {'id': 'store_manager', 'label': 'Store Manager', 'count': countByRole('store_manager')},
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Role',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.eel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...roles.map((role) {
                final isSelected = currentFilter == role['id'];
                return InkWell(
                  onTap: () {
                    onSelected(role['id'] as String);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.featherGreen.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              role['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.featherGreen : AppColors.eel,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.featherGreen
                                    : AppColors.swan.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${role['count']}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : AppColors.eel.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.featherGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
