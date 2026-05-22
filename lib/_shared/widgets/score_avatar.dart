import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Circular avatar showing a score number in a gamified tiered pastel background.
///
/// Tiers:
/// - score >= 80: Green (SeaSponge bg + Turtle border)
/// - score >= 50: Yellow (Canary bg + Duck border)
/// - score < 50:  Red (WalkingFish bg + Flamingo border)
///
/// ```dart
/// ScoreAvatar(score: 92)
/// ScoreAvatar(score: 78, size: 48)
/// ```
class ScoreAvatar extends StatelessWidget {
  final int score;
  final double size;

  const ScoreAvatar({super.key, required this.score, this.size = 48});

  _ScoreTier get _tier {
    if (score >= 80) return _ScoreTier.high;
    if (score >= 50) return _ScoreTier.medium;
    return _ScoreTier.low;
  }

  @override
  Widget build(BuildContext context) {
    final bg = switch (_tier) {
      _ScoreTier.high => AppColors.seaSponge,
      _ScoreTier.medium => AppColors.canary,
      _ScoreTier.low => AppColors.walkingFish,
    };
    final border = switch (_tier) {
      _ScoreTier.high => AppColors.turtle,
      _ScoreTier.medium => AppColors.duck,
      _ScoreTier.low => AppColors.flamingo,
    };
    final textColor = switch (_tier) {
      _ScoreTier.high => const Color(0xFF388E3C),
      _ScoreTier.medium => AppColors.fox,
      _ScoreTier.low => AppColors.cardinal,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}

enum _ScoreTier { high, medium, low }
