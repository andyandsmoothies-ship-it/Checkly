import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Single source of truth for score → color mapping.
/// Ensures consistent color thresholds across the entire app.
Color scoreColor(double? score, ThemeData theme) {
  if (score == null) return theme.colorScheme.onSurfaceVariant;
  if (score >= 80) return AppTheme.success;
  if (score >= 50) return AppTheme.warning;
  return theme.colorScheme.error;
}
