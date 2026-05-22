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
  static const warningText = AppColors.warningText;
  static const info = AppColors.info;

  // ---------- Light Theme ----------
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: Brightness.light,
      error: AppColors.destructive,
      surface: AppColors.warmCream,
    ).copyWith(primaryContainer: AppColors.softPeach);

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
    final baseTextTheme = ThemeData(
      brightness: colorScheme.brightness,
    ).textTheme;
    final textTheme = GoogleFonts.nunitoTextTheme(baseTextTheme);
    final isLight = colorScheme.brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight ? AppColors.snow : colorScheme.surface,

      // AppBar — flat white with 2px Swan bottom border
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isLight ? AppColors.snow : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        shape: Border(
          bottom: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: 2,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards — flat with 2px Swan border, zero elevation
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.snow : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: 2,
          ),
        ),
      ),

      // Buttons — Rounded, bold styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // Input fields — Flat, thick Swan borders, focused to Macaw Blue
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.snow
            : colorScheme.surfaceContainerHighest.withAlpha(60),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.macaw, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardinal, width: 2),
        ),
      ),

      // FAB — circular shape
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),

      // Chip — filled pastels/neutrals with solid borders
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.polar : AppColors.charcoal,
        selectedColor: colorScheme.primary.withAlpha(40),
        labelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: 2,
          ),
        ),
      ),

      // Bottom navigation — styled via custom widget
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: -0.5,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.iOS: _SlideRightToLeftTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Custom global right-to-left slide transitions builder for a premium, gamified feel.
class _SlideRightToLeftTransitionsBuilder extends PageTransitionsBuilder {
  const _SlideRightToLeftTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
          ),
      child: child,
    );
  }
}
