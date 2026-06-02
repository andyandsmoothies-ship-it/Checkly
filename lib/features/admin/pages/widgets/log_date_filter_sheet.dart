import 'package:flutter/material.dart';
import '../../../../_shared/theme/app_colors.dart';

/// Renders a sheet allowing users to filter system logs by date range.
void showLogDateFilterSheet({
  required BuildContext context,
  required DateTimeRange? currentRange,
  required VoidCallback onPickRange,
  required VoidCallback onClear,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
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
                    'Filter by Date',
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
              InkWell(
                onTap: () {
                  Navigator.maybePop(ctx);
                  onPickRange();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: currentRange != null ? AppColors.featherGreen.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentRange != null ? AppColors.featherGreen : AppColors.swan,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentRange == null
                            ? 'Select Date Range'
                            : 'Change Date Range',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.eel,
                        ),
                      ),
                      const Icon(
                        Icons.date_range_rounded,
                        color: AppColors.featherGreen,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (currentRange != null) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.maybePop(ctx);
                    onClear();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cardinal,
                        width: 2,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Clear Date Filter',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cardinal,
                          ),
                        ),
                        Icon(
                          Icons.delete_sweep_rounded,
                          color: AppColors.cardinal,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
