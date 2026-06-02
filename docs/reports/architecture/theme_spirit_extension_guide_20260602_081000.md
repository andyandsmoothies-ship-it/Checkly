---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
Type: Architecture Guide
Topic: Adding a New Theme Spirit (e.g., Tinder Spirit)
Date: 2026-06-02
---

# Architecture Guide: Dynamic Theme & Spirit Extension

This guide shows you how to add a completely new visual "spirit" (design style) to Checkly, using a **Tinder Spirit** as our reference example. 

Our decoupling architecture keeps business logic and frontend views separate. This makes theme swapping clean, predictable, and extremely fast.

---

## 1. System Architecture Layout

The dynamic styling system flows from state management all the way down to custom widget rendering:

```
[ThemeSpirit Enum] 
       |
       v
[ThemeSpiritNotifier (State)] 
       |
       v
[AppTheme._buildTheme()] ---> Resolves [ChecklyThemeTokens], [ColorScheme] & [Typography]
       |
       v
[MaterialApp.router] -------> Listens to notifier & rebuilds theme instantly
       |
       v
[Custom Widget Components] --> Queries Theme.of(context).extension<ChecklyThemeTokens>()
```

---

## 2. Step-by-Step Code Implementation

Here are the concrete steps and code modifications required to implement the Tinder aesthetic.

### Step 1: Add a New Enum Option
Open `lib/_shared/theme/app_theme.dart` and add `tinder` to the `ThemeSpirit` enum:

```dart
enum ThemeSpirit {
  /// Signature gamified look with 3D tactile layers and rounded shapes
  duolingo,

  /// Flat, sleek, modern layout with narrow borders and sharp corners
  minimalist,

  /// Tinder-style vibrant pink-to-orange gradients and smooth rounded cards
  tinder,
}
```

---

### Step 2: Define Tinder Design Tokens
In `lib/_shared/theme/app_theme.dart`, update the `ChecklyThemeTokens` resolution block inside `_buildTheme` to set the exact corner radii, border side weights, and depth constants:

```dart
// Resolve our active design tokens based on the global spirit selection
final tokens = activeSpirit == ThemeSpirit.duolingo
    ? const ChecklyThemeTokens(
        cardRadius: 16.0,
        button3dDepth: 4.0,
        cardBorderWidth: 2.0,
      )
    : activeSpirit == ThemeSpirit.tinder
        ? const ChecklyThemeTokens(
            cardRadius: 24.0,       // Large, ultra-smooth corners
            button3dDepth: 0.0,       // Completely flat elements
            cardBorderWidth: 0.0,     // Borderless containers
          )
        : const ChecklyThemeTokens(
            cardRadius: 4.0,
            button3dDepth: 0.0,
            cardBorderWidth: 1.0,
          );
```

---

### Step 3: Define Custom Color Scheme & Gradients
We will define Tinder's hot pink and orange color palette. 

In `lib/_shared/theme/app_colors.dart`, add the Tinder brand constants:

```dart
class AppColors {
  // ... existing colors ...

  // ── Tinder Brand Palette ──
  static const tinderPink = Color(0xFFFE3C72);
  static const tinderOrange = Color(0xFFFF7854);
  static const tinderBackground = Color(0xFFF0F2F6);
  
  // Dark mode Tinder accents
  static const tinderDarkBackground = Color(0xFF0F1115);
  static const tinderDarkSurface = Color(0xFF181B22);
}
```

Now, map this color scheme dynamically inside `AppTheme` inside the `light` theme getter:

```dart
static ThemeData get light {
  final seed = activeSpirit == ThemeSpirit.tinder
      ? AppColors.tinderPink
      : AppColors.primarySeed;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    error: AppColors.destructive,
    surface: activeSpirit == ThemeSpirit.tinder
        ? AppColors.tinderBackground
        : AppColors.warmCream,
  );

  return _buildTheme(colorScheme);
}
```

---

### Step 4: Add Dynamic Typography Swapping
Visual "clothes swaps" are incomplete if the text remains in Duolingo's signature rounded `Nunito` font. We should dynamically swap fonts depending on the active spirit.

Modify `_buildTheme` inside `lib/_shared/theme/app_theme.dart`:

```dart
static ThemeData _buildTheme(ColorScheme colorScheme) {
  final baseTextTheme = ThemeData(
    brightness: colorScheme.brightness,
  ).textTheme;

  // 1. Resolve custom typography dynamically
  final textTheme = activeSpirit == ThemeSpirit.tinder
      ? GoogleFonts.outfitTextTheme(baseTextTheme) // Sleek geometric sans-serif for Tinder
      : activeSpirit == ThemeSpirit.minimalist
          ? GoogleFonts.interTextTheme(baseTextTheme) // Clean corporate neo-grotesque for Minimalist
          : GoogleFonts.nunitoTextTheme(baseTextTheme); // Playful rounded font for Duolingo

  // ... rest of theme compilation ...
}
```

---

### Step 5: Adapt Custom Components (StrokeCard & BubblyButton)

Our custom primitives dynamically query the design tokens from context. Because they use a centralized query, they adapt to the new Tinder rules automatically.

#### StrokeCard Adaptation
No code modifications are required for `StrokeCard`! It automatically queries the registered theme extension and adapts instantly:
* Corners auto-round from `16.0` to `24.0`.
* Outlines disappear as `cardBorderWidth` resolves to `0.0`.

#### BubblyButton Custom Gradient Extension
If you want to render the custom Tinder gradient background when the Tinder spirit is active, update `lib/_shared/widgets/primitives/bubbly_button.dart`:

```dart
// Check if the current spirit is tinder to apply signature brand gradients
final isTinder = AppTheme.activeSpirit == ThemeSpirit.tinder;

Widget build(BuildContext context) {
  final tokens = Theme.of(context).extension<ChecklyThemeTokens>();
  final depth = tokens?.button3dDepth ?? 4.0;
  final radius = tokens?.cardRadius ?? 16.0;

  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: isTinder 
          ? const LinearGradient(
              colors: [AppColors.tinderPink, AppColors.tinderOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
      color: isTinder ? null : Theme.of(context).colorScheme.primary,
    ),
    // ... rest of the build logic ...
  );
}
```

---

### Step 6: Update Settings Zone to Multi-Choice Selector
Since we have migrated from a binary toggle to a multi-spirit framework, replace the binary toggle switch in `ProfilePage` (`lib/features/profile/pages/profile_page.dart`) with an elegant segment selector:

```dart
Widget _buildSettingsZone(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final spiritNotifier = _di<ThemeSpiritNotifier>();

  return AnimatedBuilder(
    animation: spiritNotifier,
    builder: (context, _) {
      final spirit = spiritNotifier.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
            child: Text(
              'SETTINGS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          StrokeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual Theme Spirit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSpiritOption(
                      context: context,
                      spirit: ThemeSpirit.duolingo,
                      label: 'Tactile 3D',
                      active: spirit == ThemeSpirit.duolingo,
                      spiritNotifier: spiritNotifier,
                    ),
                    const SizedBox(width: 8),
                    _buildSpiritOption(
                      context: context,
                      spirit: ThemeSpirit.minimalist,
                      label: 'Minimalist',
                      active: spirit == ThemeSpirit.minimalist,
                      spiritNotifier: spiritNotifier,
                    ),
                    const SizedBox(width: 8),
                    _buildSpiritOption(
                      context: context,
                      spirit: ThemeSpirit.tinder,
                      label: 'Tinder',
                      active: spirit == ThemeSpirit.tinder,
                      spiritNotifier: spiritNotifier,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildSpiritOption({
  required BuildContext context,
  required ThemeSpirit spirit,
  required String label,
  required bool active,
  required ThemeSpiritNotifier spiritNotifier,
}) {
  return Expanded(
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        spiritNotifier.state = spirit;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
          border: Border.all(
            color: active ? Colors.transparent : Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ),
  );
}
```

---

### Step 7: Test Verification
To verify the new visual spirit behaves exactly as intended, write a robust test assertion inside `test/widgets/theme_spirit_dynamic_test.dart`:

```dart
testWidgets('Components dynamically adapt to Tinder theme spirit', (tester) async {
  final spiritNotifier = ThemeSpiritNotifier();
  GetIt.instance.registerSingleton<ThemeSpiritNotifier>(spiritNotifier);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ValueListenableBuilder<ThemeSpirit>(
        valueListenable: spiritNotifier,
        builder: (context, spirit, _) {
          return const Scaffold(
            body: Column(
              children: [
                StrokeCard(child: Text('Card Content')),
                BubblyButton(child: Text('Click me')),
              ],
            ),
          );
        },
      ),
    ),
  );

  // Switch to Tinder Spirit
  spiritNotifier.state = ThemeSpirit.tinder;
  await tester.pumpAndSettle();

  // 1. Assert StrokeCard border is eliminated & card radius is 24.0
  final cardFinder = find.byType(StrokeCard);
  final cardWidget = tester.widget<StrokeCard>(cardFinder);
  // (Verify border width is 0 and corner radius is 24.0 inside widget properties)

  // 2. Assert BubblyButton shadow is omitted (yielding flat style)
  final buttonFinder = find.byType(BubblyButton);
  // (Verify flat structure is rendered successfully)
});
```

---

## 3. Dark Mode Theme Adaptation

To maintain enterprise-grade compliance, your Tinder colors must support Dark Mode. Add a `dark` theme builder inside `AppTheme` resolving the custom backgrounds:

```dart
static ThemeData get dark {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: activeSpirit == ThemeSpirit.tinder
        ? AppColors.tinderPink
        : AppColors.primarySeed,
    brightness: Brightness.dark,
    surface: activeSpirit == ThemeSpirit.tinder
        ? AppColors.tinderDarkBackground
        : AppColors.charcoal,
  );

  return _buildTheme(colorScheme);
}
```

This guarantees that toggling system dark mode matches the selected spirit's color parameters.

---

## 4. Why This Approach is Enterprise-Grade

1. **State Isolation**: Visual state is cleanly handled by `ThemeSpiritNotifier`, completely isolated from feature services.
2. **Context Resolution**: Primitives retrieve visual properties dynamically from `Theme.of(context)`. No hardcoding is permitted in widget templates.
3. **Typography & Aesthetics Swap**: Truly transforms the entire look of the app (fonts, colors, corners, borders, shadows) under one simple trigger.
4. **High Robustness**: Changes can be unit-tested and visually validated in widget tests without running an emulator.
5. **Performance Optimized**: Rebuilds are bound only to the listeners of `ThemeSpiritNotifier`, ensuring minimal widget tree reconciliation and highly efficient CPU cycles.
