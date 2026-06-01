import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_manager.dart';
import '../manager/bod_analytics_data.dart' show BodAgingBucket, ApDetailEntry;

/// Modal bottom sheet displaying detailed overdue Action Plans for a selected aging bucket in the Area.
class AreaBodApBucketDetailSheet extends StatefulWidget {
  final BodAgingBucket bucket;
  final AreaBodManager manager;

  const AreaBodApBucketDetailSheet({
    super.key,
    required this.bucket,
    required this.manager,
  });

  @override
  State<AreaBodApBucketDetailSheet> createState() => _AreaBodApBucketDetailSheetState();
}

class _AreaBodApBucketDetailSheetState extends State<AreaBodApBucketDetailSheet> {
  @override
  void initState() {
    super.initState();
    // Load details asynchronously when the sheet mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadApDetails(widget.bucket);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgCol = isLight ? AppColors.polar : AppColors.eel;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    return AnimatedBuilder(
      animation: widget.manager,
      builder: (context, _) {
        final isLoading = widget.manager.isApDetailLoading;
        final items = widget.manager.apDetails;

        return Container(
          decoration: BoxDecoration(
            color: bgCol,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${widget.bucket.displayName} Overdue Action Plans',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: subTextCol),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading) ...[
                const _SkeletonItem(),
                const SizedBox(height: 8),
                const _SkeletonItem(),
                const SizedBox(height: 8),
                const _SkeletonItem(),
              ] else if (items.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No overdue action plans in this category.',
                      style: TextStyle(
                        color: subTextCol,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final ApDetailEntry item = items[index];
                      final int overdue = item.ageInDays;

                      return UniversalListCard(
                        title: item.criteriaLabel,
                        subtitle: 'Store: ${item.storeName}',
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.walkingFish,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_late,
                            color: AppColors.cardinal,
                          ),
                        ),
                        badges: [
                          PillChip(
                            label: 'Manager: ${item.managerName}',
                            type: PillChipType.blue,
                          ),
                          PillChip(
                            label: '$overdue Days Overdue',
                            type: PillChipType.red,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonItem extends StatefulWidget {
  const _SkeletonItem();

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final bgCol = isLight ? AppColors.polar : AppColors.eel;
    final borderCol = isLight ? AppColors.swan : AppColors.swan.withValues(alpha: 0.2);

    if (disableAnimations) {
      return StrokeCard(
        color: bgCol,
        borderColor: borderCol,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.swan,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 150, color: AppColors.swan),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: AppColors.swan),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.3 + (_controller.value * 0.5),
          child: StrokeCard(
            color: bgCol,
            borderColor: borderCol,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.swan,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 16, width: 150, color: AppColors.swan),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 100, color: AppColors.swan),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
