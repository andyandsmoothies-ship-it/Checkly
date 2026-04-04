---
name: interaction-design
description: >
  Design meaningful interactions and microinteractions. Create delightful user
  experiences through thoughtful animation, feedback, and responsive interface
  design.
---

# Interaction Design

## When to Use

- Designing user flows and touchpoints
- Creating animations and transitions
- Defining error and loading states
- Building microinteractions
- Improving usability and feedback
- Mobile interaction patterns

## Quick Start

Minimal working example:

```yaml
Common Interaction Patterns:

Swipe:
  Use: Mobile lists, carousels
  Feedback: Visual sliding, momentum
  Accessibility: Keyboard alternative (arrows)

Tap & Hold:
  Use: Context menus, drag prep
  Feedback: Visual feedback after delay
  Duration: ~500ms before trigger

Pinch & Zoom:
  Use: Image viewing, maps
  Feedback: Smooth zoom animation
  Boundaries: Set min/max zoom levels

Drag & Drop:
  Use: Reordering, moving items
  Feedback: Visual during drag, drop confirmation
  Fallback: Alternative method (buttons)

Double Tap:
  Use: Zoom, favorite, select
  Feedback: Immediate visual response
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Animation & Transition Design](references/animation-transition-design.md) | Animation & Transition Design |
| [Error Handling & Feedback](references/error-handling-feedback.md) | Error Handling & Feedback |
| [Accessibility in Interactions](references/accessibility-in-interactions.md) | Accessibility in Interactions |
