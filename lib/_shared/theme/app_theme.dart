import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Checkly design system — "Apothecary" Editorial Utilitarian aesthetic.
///
/// Color constants are defined in [AppColors].
/// Typography helpers are in [AppFonts].
/// This file builds ThemeData from those primitives.
class AppTheme {
  AppTheme._();

  // ── Re-exports for backward compatibility ──
  // Pages can use AppTheme.oatmeal or AppColors.oatmeal interchangeably.
  static const oatmeal = AppColors.oatmeal;
  static const softPeach = AppColors.softPeach;
  static const sageGray = AppColors.sageGray;
  static const warmCream = AppColors.warmCream;
  static const charcoal = AppColors.charcoal;
  static const deepForest = AppColors.deepForest;
  static const success = AppColors.success;
  static const successContainer = AppColors.successContainer;
  static const warning = AppColors.warning;
  static const warningContainer = AppColors.warningContainer;
  static const info = AppColors.info;

  // ---------- Light Theme ----------
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: Brightness.light,
      error: AppColors.destructive,
      surface: AppColors.warmCream,
    ).copyWith(
      primaryContainer: AppColors.softPeach,
    );

    return _buildTheme(colorScheme);
  }

  // ---------- Dark Theme ----------
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: Brightness.dark,
      error: AppColors.destructive,
      surface: AppColors.deepForest,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTextTheme = ThemeData(brightness: colorScheme.brightness).textTheme;
    final textTheme = GoogleFonts.manropeTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards — Premium soft analytical styling
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        margin: EdgeInsets.zero,
        color: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(60),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.sageGray.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // FAB — circular shape
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),

      // Chip — warm oatmeal accents
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.oatmeal.withValues(alpha: 0.5),
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.sageGray.withValues(alpha: 0.3)),
        ),
      ),

      // Bottom navigation — styled via custom widget
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
