---
name: design-system-creation
description: >
  Build comprehensive design systems with components, patterns, and guidelines.
  Enable consistent design, faster development, and better collaboration across
  teams.
---

# Design System Creation

## When to Use

- Multiple product interfaces or teams
- Scaling design consistency
- Reducing redundant component development
- Improving design-to-dev handoff
- Creating shared language across teams
- Building reusable components
- Documenting design standards

## Quick Start

Minimal working example:

```yaml
Design System Structure:

Foundation Layer:
  Typography:
    - Typefaces (Roboto, Inter)
    - Font sizes (scale: 12, 14, 16, 20, 28, 36, 48)
    - Font weights (Regular, Medium, Bold)
    - Line heights and letter spacing

Colors:
  - Primary brand color (#2196F3)
  - Secondary colors
  - Neutral palette (grays)
  - Semantic colors (success, error, warning)
  - Dark mode variants

Spacing:
  - Base unit: 4px
  - Scale: 4, 8, 12, 16, 24, 32, 48, 64px
  - Apply consistently across UI

Shadows & Elevation:
  - Elevation 0 (flat)
  - Elevation 1, 2, 4, 8, 16 (increasing depth)
  - Used for modals, cards, overlays
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Design System Components](references/design-system-components.md) | Design System Components |
| [Component Documentation](references/component-documentation.md) | Component Documentation |
| [Design System Governance](references/design-system-governance.md) | Design System Governance |
| [Design System Documentation](references/design-system-documentation.md) | Design System Documentation |
