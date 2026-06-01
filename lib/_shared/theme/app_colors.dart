import 'package:flutter/material.dart';

/// Checkly color primitives — Apothecary "Editorial Utilitarian" palette.
///
/// These are raw color constants, independent of ThemeData.
/// Import this when you need direct color access without pulling in themes.
class AppColors {
  AppColors._();

  // ── Core Brand Colors ──
  static const featherGreen = Color(0xFF58CC02);
  static const maskGreen = Color(0xFF89E219);
  static const eel = Color(0xFF4B4B4B);
  static const snow = Color(0xFFFFFFFF);

  // ── Secondary Semantic Colors ──
  static const macaw = Color(0xFF1CB0F6);
  static const cardinal = Color(0xFFFF4B4B);
  static const bee = Color(0xFFFFC800);
  static const fox = Color(0xFFFF9600);
  static const beetle = Color(0xFFCE82FF);
  static const humpback = Color(0xFF2B70C9);

  // ── Neutral Scale ──
  static const swan = Color(0xFFE5E5E5);
  static const polar = Color(0xFFF7F7F7);
  static const hare = Color(0xFFAFAFAF);
  static const wolf = Color(0xFF777777);

  // ── Illustration Pastel Palette ──
  // Greens
  static const seaSponge = Color(0xFFD7FFB8);
  static const turtle = Color(0xFFA5ED6E);
  // Blues
  static const iguana = Color(0xFFDDF4FF);
  static const beluga = Color(0xFFBBF2FF);
  static const blueJay = Color(0xFF84D8FF);
  // Reds/Pinks
  static const walkingFish = Color(0xFFFFDFE0);
  static const flamingo = Color(0xFFFFB2B2);
  // Yellows
  static const canary = Color(0xFFFFF5D3);
  static const duck = Color(0xFFFBE56D);
  // Purples
  static const starfish = Color(0xFFFFAADE);

  // ── Brand ──
  static const primarySeed =
      featherGreen; // Muted Green reskinned to Feather Green

  // ── Semantic ──
  static const destructive = cardinal;
  static const success = featherGreen;
  static const successContainer = seaSponge; // Light green tint reskinned
  static const warning = bee;
  static const warningContainer = canary; // Warm amber tint reskinned
  static const warningText = fox; // High contrast warning text reskinned
  static const info = macaw;

  // ── Apothecary Palette mappings for backward compatibility ──
  static const oatmeal = swan;
  static const softPeach = walkingFish;
  static const sageGray = swan;
  static const warmCream = polar;
  static const charcoal = eel;
  static const deepForest = eel;
}

/// Blueprint scoring-mode brand accents.
/// These are intentional document-type identifiers (analogous to app-icon brand colors).
/// Centralised here so they flow through the token system and support future dark-mode overrides.
class BlueprintColors {
  BlueprintColors._();

  static const audit = Color(0xFF1565C0); // Blue  — Audit & Inspection
  static const assessment = Color(0xFF2E7D32); // Green — Scored Assessment
  static const simpleAssessment = Color(
    0xFF00838F,
  ); // Teal — Simple Scored Assessment
  static const survey = Color(0xFF7B1FA2); // Purple — Form & Survey
  static const checklist = Color(0xFFE65100); // Deep Orange — Basic Checklist
}
