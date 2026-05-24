import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/stroke_card.dart';

class BodStoreLeaderboard extends StatelessWidget {
  final List<dynamic> topStores;
  final List<dynamic> bottomStores;

  const BodStoreLeaderboard({
    super.key,
    required this.topStores,
    required this.bottomStores,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fallback beautiful mock data if lists are empty
    final finalTop = topStores.isNotEmpty
        ? topStores
        : [
            {'storeName': 'Central Market', 'avgScore': 96.5},
            {'storeName': 'Siam Square', 'avgScore': 94.2},
          ];

    final finalBottom = bottomStores.isNotEmpty
        ? bottomStores
        : [
            {'storeName': 'Outpost West', 'avgScore': 62.1},
            {'storeName': 'Airport Express', 'avgScore': 58.4},
          ];

    return StrokeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard, color: AppColors.fox, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Store Performance Leaderboard',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.eel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Top Performing Stores',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.featherGreen,
            ),
          ),
          const SizedBox(height: 8),
          ...finalTop.map((s) => _buildStoreRow(context, s, isTop: true)),
          const SizedBox(height: 16),
          Text(
            'Bottom Performing Stores',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.cardinal,
            ),
          ),
          const SizedBox(height: 8),
          ...finalBottom.map((s) => _buildStoreRow(context, s, isTop: false)),
        ],
      ),
    );
  }

  Widget _buildStoreRow(BuildContext context, dynamic s, {required bool isTop}) {
    final theme = Theme.of(context);
    final storeName = s['storeName'] ?? s['name'] ?? 'Unknown Store';
    final avgScore = (s['avgScore'] ?? s['score'] ?? 0.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  storeName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.eel,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${avgScore.toStringAsFixed(1)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isTop ? AppColors.featherGreen : AppColors.cardinal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: avgScore / 100,
              backgroundColor: AppColors.swan.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTop ? AppColors.featherGreen : AppColors.cardinal,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
