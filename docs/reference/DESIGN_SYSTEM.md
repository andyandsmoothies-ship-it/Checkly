# UDAT Design System

> Design system reference for both the PWA and Flutter mobile app.

---

## Flutter Mobile Design System

> Stack: Flutter · Material 3 · GetIt · GoRouter

### Theme (AppTheme)
- **Source**: `lib/_shared/theme/app_theme.dart`
- **Palette**: Warm neutral tones — `charcoal`, `sageGray`, `softPeach`, `parchment`
- **Status Colors**: `success` (green), `warning` (amber), `error` (red)
- **Scoring Colors**: Traffic light — `≥90 → success`, `≥70 → warning`, `<70 → error`

### Typography (AppFonts)
- **Source**: `lib/_shared/theme/app_fonts.dart`
- **Display**: Serif style for headings and scores
- **Body**: System default Material 3 typography

### Key UI Patterns

| Pattern | Description | Source |
|:--------|:------------|:-------|
| **Criteria Bottom Sheet** | Tap a criterion row → opens modal bottom sheet with full editing controls | `audit_form_page.dart` |
| **Live Score HUD** | Sticky points display (`earned / max pts`) with circular progress | `_ScoreHud` widget |
| **Status Badges** | Color-coded chips on criterion rows (pass/fail/pending) | `_StatusBadge` widget |
| **Is Required Indicator** | Red asterisk `*` appended to criterion titles to denote mandatory fields | `CriterionCard` |
| **Scoring Rules Card** | 3 groups: Scoring Formula → Critical Failure Rules → Audit Behavior | `_ScoringRulesCard` |
| **Layout Locking** | Root sections commit to flat criteria OR sub-sections, never both | `_SectionEditor` |
| **Scored Choices Input** | Radio-tile selector for scored choice criteria (e.g., Poor=0/Good=5/Excellent=10) | `CriterionScaleEditor` |
| **Input Type Badge** | Colored badge on collapsed criterion row showing input type (YES·NO, 0·1·2, LOW→HIGH, 1 OF N, N OF N) | `CriterionEditor.build()` |
| **Quick Jump Navigation** | Bottom sheet allowing quick navigation to any section/group | `AuditQuickJumpSheet` |
| **Empty States** | Standardized fallback for empty datasets (icons, title, subtitle). Never use raw `Text`. | `ChecklyEmptyState` widget |
| **Insight Card** | Renders actionable heuristic insights with success/warning/error semantic colors | `InsightCard` |
| **Insights Radar Chart** | Renders a polygonal 3+ category radar chart, utilizing fl_chart constraints | `InsightsRadarChart` |

---

## PWA Design System (Legacy Reference)

> Stack: React · Tailwind CSS · shadcn/ui · Plus Jakarta Sans

---

## Architecture

```
src/tokens.css     ← CSS variables (colors, shades, spacing, shadows, gradients)
src/index.css      ← Tailwind directives + utility classes + global styles
tailwind.config.ts ← Token-to-utility mappings (colors, typography, z-index, border-radius)
```

---

## Color Tokens

### Semantic Palette

| Token | Purpose | Light |
|-------|---------|-------|
| `primary` | Brand, CTAs, links | `hsl(221 83% 53%)` |
| `destructive` | Errors, deletions, overdue | `hsl(0 84% 60%)` |
| `success` | Passed, completed, in-range | `hsl(142 76% 36%)` |
| `warning` | Caution, pending, faults | `hsl(38 92% 50%)` |
| `info` | Informational, draft status | `hsl(199 89% 48%)` |

### Shade Scales (50–900)

Each semantic color has a full 10-step shade scale. Usage:

```tsx
// Background tints
<div className="bg-primary-50" />     // Lightest (~97% lightness)
<div className="bg-destructive-100" /> // Very light tint
// Foreground accents
<span className="text-success-700" /> // Darker shade for emphasis on light bg
```

> **Rule**: Use `bg-{token}` for the DEFAULT. Use `bg-{token}-{shade}` only when you need a specific tint/shade that `bg-{token}/opacity` cannot achieve.

### Surfaces

| Token | Usage |
|-------|-------|
| `background` / `foreground` | Page-level |
| `card` / `card-foreground` | Elevated surfaces |
| `popover` / `popover-foreground` | Floating panels |
| `muted` / `muted-foreground` | Subdued text, disabled |
| `secondary` / `secondary-foreground` | Secondary buttons, subtle fills |
| `accent` / `accent-foreground` | Highlights |

### Data Visualization

`chart-1` through `chart-5` — 5-color palette for charts/graphs.

---

## Typography Scale

| Class | Size | Line Height | Weight |
|-------|------|-------------|--------|
| `text-caption` | 11px | 16px | inherit |
| `text-body-sm` | 12px | 18px | inherit |
| `text-body` | 14px | 22px | inherit |
| `text-body-lg` | 16px | 24px | inherit |
| `text-heading-sm` | 18px | 26px | 700 |
| `text-heading` | 24px | 32px | 700 |
| `text-display` | 32px | 40px | 800 |

**Font**: Plus Jakarta Sans (imported via Google Fonts).

---

## Z-Index Scale

| Token | Value | Usage |
|-------|-------|-------|
| `z-dropdown` | 10 | Dropdown menus |
| `z-sticky` | 20 | Sticky headers, pill strips |
| `z-overlay` | 30 | Screen overlays, backdrop |
| `z-modal` | 40 | Modal dialogs, sheets |
| `z-toast` | 50 | Toast notifications |
| `z-skip-link` | 100 | A11y skip-to-content link |

---

## Elevation (Shadows)

| Token | Usage |
|-------|-------|
| `shadow-soft` | Subtle lift (buttons, inputs) |
| `shadow-card` | Card-level elevation |
| `shadow-elevated` | High emphasis (floating panels) |

---

## Border Radius Scale

| Class | Value |
|-------|-------|
| `rounded-sm` | `--radius - 8px` |
| `rounded-md` | `--radius - 4px` |
| `rounded-lg` | `--radius` (1rem) |
| `rounded-xl` | `--radius + 4px` |
| `rounded-2xl` | `--radius + 8px` |
| `rounded-3xl` | `--radius + 16px` |

---

## Component Patterns

### Status Badges

```tsx
// Use semantic token backgrounds at 10% opacity + token text
<Badge className="bg-success/10 text-success border-success/20">COMPLETED</Badge>
<Badge className="bg-destructive/10 text-destructive border-destructive/20">REJECTED</Badge>
<Badge className="bg-warning/10 text-warning border-warning/20">FLAGGED</Badge>
<Badge className="bg-info/10 text-info border-info/20">DRAFT</Badge>
```

### Score Display (Traffic Light)

```tsx
const scoreColor = score >= 90
  ? "text-success"
  : score >= 70
    ? "text-warning"
    : "text-destructive";
```

### Error/Warning States

```tsx
// Icon + background tint pattern
<div className="bg-destructive/10">
  <AlertTriangle className="text-destructive" />
</div>

<div className="bg-warning/10">
  <AlertCircle className="text-warning" />
</div>
```


### Glass Effects

```tsx
<div className="glass-card" />  // bg-white/70 backdrop-blur-md
<nav className="glass-nav" />   // bg-background/80 backdrop-blur-xl
```

---

## Conventions

1. **Never use raw Tailwind colors** (`text-red-500`, `bg-blue-100`). Use semantic tokens.
2. **Always use `cn()`** for class composition. Never template literals.
3. **Icons**: Lucide React only. Never import from `lucide`.
4. **Foreground pairing**: Every `bg-{token}` has a matching `text-{token}-foreground`.
5. **Opacity tinting**: Prefer `bg-{token}/10` over shade scales for light tints.
6. **Safe Areas**: Use `safe-bottom` and `safe-top` for notch-aware padding.
7. **Reduced Motion**: Handled globally — no per-component logic needed.
