import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';
import '../manager/area_bod_data.dart';

/// Store Performance rankings displaying Top and Under performing stores in the Area.
class AreaBodStoreLeaderboard extends StatefulWidget {
  final List<AreaStoreRankEntry> topStores;
  final List<AreaStoreRankEntry> bottomStores;
  final AreaGoldenStore? goldenStore;

  const AreaBodStoreLeaderboard({
    super.key,
    required this.topStores,
    required this.bottomStores,
    this.goldenStore,
  });

  @override
  State<AreaBodStoreLeaderboard> createState() => _AreaBodStoreLeaderboardState();
}

class _AreaBodStoreLeaderboardState extends State<AreaBodStoreLeaderboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store,
                color: AppColors.macaw,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Store Performance rankings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Stores ranked by audit scores. The flagship store acts as the baseline.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: subTextCol.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.macaw,
            unselectedLabelColor: subTextCol,
            indicatorColor: AppColors.macaw,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
            unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Top Performers'),
              Tab(text: 'Under Performers'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStoreList(widget.topStores),
                _buildStoreList(widget.bottomStores),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList(List<AreaStoreRankEntry> stores) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textCol = isLight ? AppColors.eel : AppColors.snow;
    final subTextCol = isLight ? AppColors.wolf : AppColors.hare;

    if (stores.isEmpty) {
      return Center(
        child: Text(
          'No store performance data found.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: subTextCol,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: stores.length,
      separatorBuilder: (context, index) => const Divider(
        height: 16,
        thickness: 1,
        color: AppColors.swan,
      ),
      itemBuilder: (context, index) {
        final row = stores[index];
        final score = row.avgScore;
        final isGolden = widget.goldenStore != null &&
            row.storeName.toLowerCase().trim() ==
                widget.goldenStore!.storeName.toLowerCase().trim();

        Color scoreColor = AppColors.macaw;
        if (isGolden) {
          scoreColor = AppColors.featherGreen;
        } else if (widget.goldenStore != null && widget.goldenStore!.avgScore > 0) {
          final pctOfGolden = score / widget.goldenStore!.avgScore;
          if (pctOfGolden >= 0.95) {
            scoreColor = AppColors.featherGreen;
          } else if (pctOfGolden >= 0.85) {
            scoreColor = AppColors.macaw;
          } else {
            scoreColor = AppColors.cardinal;
          }
        }

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isGolden
                    ? AppColors.featherGreen.withValues(alpha: 0.1)
                    : (isLight ? AppColors.polar : AppColors.eel),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isGolden ? AppColors.featherGreen : AppColors.swan,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: isGolden
                    ? const Icon(
                        Icons.star,
                        color: AppColors.featherGreen,
                        size: 16,
                      )
                    : Text(
                        '${index + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textCol,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          row.storeName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: textCol,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isGolden) ...[
                        const SizedBox(width: 6),
                        const PillChip(
                          label: 'Flagship',
                          type: PillChipType.green,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${row.auditCount} submissions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subTextCol,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scoreColor,
                  ),
                ),
                if (widget.goldenStore != null && !isGolden && widget.goldenStore!.avgScore > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${((score / widget.goldenStore!.avgScore) * 100).toStringAsFixed(0)}% of flagship',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subTextCol,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}
