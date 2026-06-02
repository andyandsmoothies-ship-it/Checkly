import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

/// Renders a sheet allowing users to filter system logs by severity.
void showLogLevelFilterSheet({
  required BuildContext context,
  required String currentFilter,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final levels = [
        {'id': 'all', 'label': 'All Levels', 'color': AppColors.eel},
        {'id': 'info', 'label': 'INFO', 'color': AppColors.macaw},
        {'id': 'warn', 'label': 'WARN', 'color': AppColors.fox},
        {'id': 'error', 'label': 'ERROR', 'color': AppColors.cardinal},
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
                    'Filter by Log Level',
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
              ...levels.map((lvl) {
                final isSelected = currentFilter == lvl['id'];
                return InkWell(
                  onTap: () {
                    onSelected(lvl['id'] as String);
                    Navigator.maybePop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.featherGreen.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.featherGreen : AppColors.swan,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lvl['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: lvl['color'] as Color,
                          ),
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
