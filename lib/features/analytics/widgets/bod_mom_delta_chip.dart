import 'package:flutter/material.dart';
import '../../../_shared/theme/app_colors.dart';
import '../../../_shared/widgets/primitives/pill_chip.dart';

/// A chip that displays the Month-over-Month (MoM) delta variance of average scores.
///
/// Compares the last period's score to the second-to-last period's score in the [trend] list.
class BodMomDeltaChip extends StatelessWidget {
  final List<dynamic> trend;

  const BodMomDeltaChip({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.length < 2) {
      return _buildGreyChip('— 0.0%');
    }

    final lastPeriod = trend[trend.length - 1];
    final prevPeriod = trend[trend.length - 2];

    final double lastScore = (lastPeriod['avgScore'] ?? 0.0).toDouble();
    final double prevScore = (prevPeriod['avgScore'] ?? 0.0).toDouble();

    final double delta = lastScore - prevScore;

    if (delta > 0.0) {
      return PillChip(
        label: '↑ ${delta.toStringAsFixed(1)}%',
        type: PillChipType.green,
      );
    } else if (delta < 0.0) {
      return PillChip(
        label: '↓ ${delta.abs().toStringAsFixed(1)}%',
        type: PillChipType.red,
      );
    } else {
      return _buildGreyChip('— 0.0%');
    }
  }

  Widget _buildGreyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.polar,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.swan, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove, size: 14, color: AppColors.wolf),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.wolf,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
