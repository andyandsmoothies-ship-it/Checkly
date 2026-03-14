import 'package:flutter/material.dart';

/// Circular avatar showing a score number in a tinted background.
///
/// Matches the Apothecary reference: primary/10 circle with bold score text.
/// ```dart
/// ScoreAvatar(score: 92)
/// ScoreAvatar(score: 78, size: 48)
/// ```
class ScoreAvatar extends StatelessWidget {
  final int score;
  final double size;

  const ScoreAvatar({super.key, required this.score, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
