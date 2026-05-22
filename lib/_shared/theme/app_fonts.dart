import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dual-font system: Manrope (display/UI) + Lora (serif accents).
///
/// Usage:
///   AppFonts.displayStyle(fontSize: 14, fontWeight: FontWeight.w600)
///   AppFonts.serifStyle(fontSize: 48)
class AppFonts {
  AppFonts._();

  /// Nunito — headings, labels, body text, all UI elements.
  static TextStyle displayStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  /// Nunito — bold accent for hero numbers, greeting text, large scores.
  static TextStyle serifStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w900,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
