import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Checkly design system — "Apothecary" Editorial Utilitarian aesthetic.
///
/// Primary: #4CAE4F (Muted Green)
/// Display font: Manrope | Serif accent: Lora
/// Light bg: Warm Cream #F9F7F2 | Dark bg: Deep Forest #151D15
class AppTheme {
  AppTheme._();

  // ---------- Color Tokens ----------
  static const _primarySeed = Color(0xFF4CAE4F); // Muted Green
  static const _destructive = Color(0xFFEF4444);
  static const _success = Color(0xFF16A34A);
  static const _warning = Color(0xFFF59E0B);
  static const _info = Color(0xFF0EA5E9);

  // ---------- Apothecary Palette ----------
  static const oatmeal = Color(0xFFE8E2D6);
  static const softPeach = Color(0xFFF5E6DA);
  static const sageGray = Color(0xFFD1D9D1);
  static const warmCream = Color(0xFFF9F7F2);
  static const charcoal = Color(0xFF2D312E);
  static const deepForest = Color(0xFF151D15);

  // ---------- Light Theme ----------
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
      error: _destructive,
      surface: warmCream,
    );

    return _buildTheme(colorScheme);
  }

  // ---------- Dark Theme ----------
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
      error: _destructive,
      surface: deepForest,
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.manropeTextTheme();

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

      // Cards — sage gray border at 50% opacity
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.brightness == Brightness.light
            ? Colors.white
            : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: sageGray.withValues(alpha: 0.5)),
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
          borderSide: BorderSide(color: sageGray.withValues(alpha: 0.5)),
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
        backgroundColor: oatmeal.withValues(alpha: 0.5),
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: sageGray.withValues(alpha: 0.3)),
        ),
      ),

      // Bottom navigation — styled via custom widget, but keep base config
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

  // ---------- Extension Colors ----------
  static const success = _success;
  static const warning = _warning;
  static const info = _info;
}
