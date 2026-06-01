import 'package:flutter/material.dart';

/// Enterprise-grade custom design system tokens registered via [ThemeExtension].
///
/// Decouples visual variables (roundness, shadow depths, outline weights) from the
/// components and screens themselves. Allows dynamically changing the app spirit.
class ChecklyThemeTokens extends ThemeExtension<ChecklyThemeTokens> {
  final double cardRadius;
  final double button3dDepth;
  final double cardBorderWidth;

  const ChecklyThemeTokens({
    required this.cardRadius,
    required this.button3dDepth,
    required this.cardBorderWidth,
  });

  @override
  ChecklyThemeTokens copyWith({
    double? cardRadius,
    double? button3dDepth,
    double? cardBorderWidth,
  }) {
    return ChecklyThemeTokens(
      cardRadius: cardRadius ?? this.cardRadius,
      button3dDepth: button3dDepth ?? this.button3dDepth,
      cardBorderWidth: cardBorderWidth ?? this.cardBorderWidth,
    );
  }

  @override
  ChecklyThemeTokens lerp(
    ThemeExtension<ChecklyThemeTokens>? other,
    double t,
  ) {
    if (other is! ChecklyThemeTokens) {
      return this;
    }
    return ChecklyThemeTokens(
      cardRadius: _lerpDouble(cardRadius, other.cardRadius, t),
      button3dDepth: _lerpDouble(button3dDepth, other.button3dDepth, t),
      cardBorderWidth: _lerpDouble(cardBorderWidth, other.cardBorderWidth, t),
    );
  }

  /// Safe helper to interpolate double values.
  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
