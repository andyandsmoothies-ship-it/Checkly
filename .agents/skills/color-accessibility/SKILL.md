---
name: color-accessibility
description: >
  Design color palettes that are accessible to all users including those with
  color blindness. Ensure sufficient contrast, meaningful use of color, and
  inclusive design.
---

# Color Accessibility

## When to Use

- Creating color palettes
- Designing data visualizations
- Testing interface designs
- Status indicators and alerts
- Form validation states
- Charts and graphs

## Quick Start

Minimal working example:

```yaml
WCAG Contrast Ratios:

WCAG AA (Minimum):
  - Normal text: 4.5:1
  - Large text (18pt+): 3:1
  - UI components & graphical elements: 3:1
  - Focus indicators: 3:1

WCAG AAA (Enhanced):
  - Normal text: 7:1
  - Large text: 4.5:1
  - Better for accessibility

---
Testing Contrast:

Tools:
  - WebAIM Contrast Checker
  - Color Contrast Analyzer
  - Figma plugins
  - Browser DevTools

Formula (WCAG): Contrast = (L1 + 0.05) / (L2 + 0.05)
  Where L = relative luminance

// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Color Contrast Standards](references/color-contrast-standards.md) | Color Contrast Standards |
| [Color Vision Deficiency Simulation](references/color-vision-deficiency-simulation.md) | Color Vision Deficiency Simulation |
| [Accessible Color Usage](references/accessible-color-usage.md) | Accessible Color Usage |
| [Testing & Validation](references/testing-validation.md) | Testing & Validation |
