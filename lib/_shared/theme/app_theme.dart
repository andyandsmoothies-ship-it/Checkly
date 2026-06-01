import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'checkly_theme_tokens.dart';

/// Defines the overall design theme/spirit for the Checkly application.
enum ThemeSpirit {
  /// Signature gamified look with 3D tactile layers and rounded shapes
  duolingo,

  /// Flat, sleek, modern layout with narrow borders and sharp corners
  minimalist,
}

/// Checkly design system — "Apothecary" Editorial Utilitarian aesthetic.
///
/// Color constants are defined in [AppColors].
/// Typography helpers are in [AppFonts].
/// This file builds ThemeData from those primitives.
class AppTheme {
  AppTheme._();

  /// Global switch to swap the design spirit of the entire application.
  static ThemeSpirit activeSpirit = ThemeSpirit.duolingo;

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

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final baseTextTheme = ThemeData(
      brightness: colorScheme.brightness,
    ).textTheme;
    final textTheme = GoogleFonts.nunitoTextTheme(baseTextTheme);
    final isLight = colorScheme.brightness == Brightness.light;

    // Resolve our active design tokens based on the global spirit selection
    final tokens = activeSpirit == ThemeSpirit.duolingo
        ? const ChecklyThemeTokens(
            cardRadius: 16.0,
            button3dDepth: 4.0,
            cardBorderWidth: 2.0,
          )
        : const ChecklyThemeTokens(
            cardRadius: 4.0,
            button3dDepth: 0.0,
            cardBorderWidth: 1.0,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isLight ? AppColors.snow : colorScheme.surface,
      extensions: [tokens], // Register our custom design system tokens

      // AppBar — flat white with outline matching our border width token
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isLight ? AppColors.snow : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        shape: Border(
          bottom: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: tokens.cardBorderWidth,
          ),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),

      // Cards — flat with outline matching our corner radius and border width tokens
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.snow : colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          side: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: tokens.cardBorderWidth,
          ),
        ),
      ),

      // Buttons — Corner radius matching tokens
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.cardRadius),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // Input fields — Flat, custom Swan borders, focused to Macaw Blue
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
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: tokens.cardBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: tokens.cardBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(color: AppColors.macaw, width: tokens.cardBorderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          borderSide: BorderSide(color: AppColors.cardinal, width: tokens.cardBorderWidth),
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
          borderRadius: BorderRadius.circular(tokens.cardRadius + 4.0),
          side: BorderSide(
            color: isLight ? AppColors.swan : AppColors.swan.withAlpha(40),
            width: tokens.cardBorderWidth,
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
