---
name: component-scaffolding
description: >
  Scaffold production-ready React or React Native components with TypeScript,
  tests, styles, and barrel exports. Use when creating new components,
  setting up component architecture, or scaffolding component folders.
  Triggers: "scaffold component", "create component", "new component",
  "component folder", "component template", "component architecture".
---

# Component Scaffolding

## When to Use

- Creating a new React or React Native component from scratch
- Setting up a consistent folder structure for a component library
- Scaffolding multiple related components at once

## Folder Structure

Every component gets a folder with co-located files:

```
ComponentName/
├── ComponentName.tsx        # Component implementation
├── ComponentName.types.ts   # Props and types
├── ComponentName.styles.ts  # Styles (CSS modules, styled-components, or Tailwind)
├── ComponentName.test.tsx   # Tests
├── ComponentName.stories.tsx # Storybook stories (optional)
└── index.ts                 # Barrel export
```

**Why this structure?** Co-location keeps related files together, barrel exports give clean imports (`import { Button } from './Button'`), and separate `.types.ts` files enable sharing types without importing the component.

## Component Template

```tsx
import { forwardRef } from 'react';
import type { ComponentNameProps } from './ComponentName.types';

export const ComponentName = forwardRef<HTMLDivElement, ComponentNameProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <div ref={ref} className={className} {...props}>
        {children}
      </div>
    );
  }
);

ComponentName.displayName = 'ComponentName';
```

**Key decisions:**
- **`forwardRef` by default** — consumers can attach refs without wrapper components
- **Spread `...props`** — enables composition (data attributes, aria attributes)
- **`displayName`** — shows readable name in React DevTools instead of `ForwardRef`

## Decision Guide

| Question | Recommendation |
|----------|---------------|
| Needs internal state? | Use `useState` + custom hook if complex |
| Fetches data? | Extract to a custom hook, keep component pure |
| Reused across pages? | Put in `components/shared/`, add Storybook story |
| Page-specific? | Co-locate with the page |
| Has complex logic? | Split into container (logic) + presentational (UI) |
| Native + Web? | Use `Platform.select()` or `.native.tsx` / `.web.tsx` suffixes |

## Accessibility Checklist

When scaffolding interactive components:
- Add `role` attribute if using non-semantic elements
- Include `aria-label` or `aria-labelledby` for icon-only buttons
- Support keyboard navigation (`onKeyDown` for Enter/Space)
- Manage focus for modals and dropdowns (`useRef` + `focus()`)
- Use semantic HTML first (`<button>`, `<nav>`, `<dialog>`)
