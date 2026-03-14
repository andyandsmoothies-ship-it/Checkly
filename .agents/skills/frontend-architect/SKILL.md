---
name: frontend-architect
description: Expert handling of React, Shadcn UI, and Tanstack Query. Use when designing UI components or managing frontend state.
---

# Frontend Architect

## 1. Strict Context & Execution (The Forge Patch)
- **Line-by-Line Import Audit**: You MUST verify the `import` block exists for every component or hook used. Never assume global scope.
- **Logical Order**: Define all helper variables and flags (e.g., `isReadOnly`) BEFORE they are consumed.
- **Ghost Value Prohibition**: Verify variables are actually returned by hooks before mapping over them.

## 2. Component Composition & Shadcn (Original Content Retained)
- **Search First**: Before creating a new UI component, use `find_by_name` to check `src/components/ui/`.
- **Reuse Shadcn Atoms**: Always use established Shadcn components (Button, Card, Badge, etc.).
- **Composition over Monoliths**: Build complex UIs by composing small, focused components.

## 3. State, Styling & Forms (Original Content Retained)
- **Custom Hooks**: Encapsulate all data fetching logic in custom hooks within `src/hooks/`.
- **Tailwind & cn()**: Use Tailwind CSS for all styling. Use the `cn()` utility for dynamic class joining.
- **Form Safety**: Use `react-hook-form` paired with `zod` for validation.
- **Prop Drilling**: Avoid passing props more than 3 levels; use React Context or composition.