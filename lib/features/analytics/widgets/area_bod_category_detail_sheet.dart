import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/universal_list_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_manager.dart';
import '../manager/bod_analytics_data.dart' show CategoryStoreEntry;

/// Modal bottom sheet displaying detailed store rankings for a selected category section in the Area Manager view.
class AreaBodCategoryDetailSheet extends StatefulWidget {
  final String categoryName;
  final AreaBodManager manager;

  const AreaBodCategoryDetailSheet({
    super.key,
    required this.categoryName,
    required this.manager,
  });

  @override
  State<AreaBodCategoryDetailSheet> createState() =>
      _AreaBodCategoryDetailSheetState();
}

class _AreaBodCategoryDetailSheetState
    extends State<AreaBodCategoryDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.manager.loadCategoryDetail(widget.categoryName);
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: AnimatedBuilder(
        animation: widget.manager,
        builder: (context, _) {
          final isLoading = widget.manager.isCategoryDetailLoading;
          final items = widget.manager.categoryDetail;
          final error = widget.manager.error;

          final sortedItems = List<CategoryStoreEntry>.from(items)
            ..sort((a, b) => a.avgScore.compareTo(b.avgScore));

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
                        '${widget.categoryName} Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subTextCol),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                Text(
                  'Live data as of ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subTextCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading) ...[
                  const _SkeletonItem(),
                  const SizedBox(height: 8),
                  const _SkeletonItem(),
                  const SizedBox(height: 8),
                  const _SkeletonItem(),
                ] else if (error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        error,
                        style: const TextStyle(
                          color: AppColors.cardinal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else if (sortedItems.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No store data for this category',
                        style: TextStyle(
                          color: subTextCol,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: sortedItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: UniversalListCard(
                              title: item.storeName,
                              subtitle:
                                  'Audits: ${item.auditCount} | Failures: ${item.failureCount}',
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? AppColors.walkingFish
                                      : AppColors.walkingFish.withValues(
                                          alpha: 0.2,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: AppColors.cardinal,
                                ),
                              ),
                              badges: [
                                PillChip(
                                  label: '${item.avgScore.toStringAsFixed(1)}%',
                                  type: item.avgScore < 70
                                      ? PillChipType.red
                                      : item.avgScore < 85
                                      ? PillChipType.blue
                                      : PillChipType.green,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonItem extends StatefulWidget {
  const _SkeletonItem();

  @override
  State<_SkeletonItem> createState() => _SkeletonItemState();
}

class _SkeletonItemState extends State<_SkeletonItem>
    with SingleTickerProviderStateMixin {
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
    if (disableAnimations) {
      return StrokeCard(
        color: Theme.of(context).brightness == Brightness.light
            ? AppColors.polar
            : AppColors.eel,
        borderColor: AppColors.swan,
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
            color: Theme.of(context).brightness == Brightness.light
                ? AppColors.polar
                : AppColors.eel,
            borderColor: AppColors.swan,
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
