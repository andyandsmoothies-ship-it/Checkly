import 'package:flutter/material.dart';

/// Checkly color primitives — Apothecary "Editorial Utilitarian" palette.
///
/// These are raw color constants, independent of ThemeData.
/// Import this when you need direct color access without pulling in themes.
class AppColors {
  AppColors._();

  // ── Brand ──
  static const primarySeed = Color(0xFF4CAE4F); // Muted Green

  // ── Semantic ──
  static const destructive = Color(0xFFEF4444);
  static const success = Color(0xFF16A34A);
  static const successContainer = Color(
    0xFFE8F5E9,
  ); // Light green tint for success banners
  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(
    0xFFFEEAD1,
  ); // Warm amber tint for stat card bg
  static const warningText = Color(
    0xFFB45309,
  ); // High contrast warning text for badges
  static const info = Color(0xFF0EA5E9);

  // ── Apothecary Palette ──
  static const oatmeal = Color(0xFFE8E2D6);
  static const softPeach = Color(0xFFF5E6DA);
  static const sageGray = Color(0xFFD1D9D1);
  static const warmCream = Color(0xFFF9F7F2);
  static const charcoal = Color(0xFF2D312E);
  static const deepForest = Color(0xFF151D15);
}

/// Blueprint scoring-mode brand accents.
/// These are intentional document-type identifiers (analogous to app-icon brand colors).
/// Centralised here so they flow through the token system and support future dark-mode overrides.
class BlueprintColors {
  BlueprintColors._();

  static const audit = Color(0xFF1565C0); // Blue  — Audit & Inspection
  static const assessment = Color(0xFF2E7D32); // Green — Scored Assessment
  static const survey = Color(0xFF7B1FA2); // Purple — Form & Survey
  static const checklist = Color(0xFFE65100); // Deep Orange — Basic Checklist
}
