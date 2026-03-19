---
name: frontend-accessibility
description: >
  Implement WCAG compliance using semantic HTML, ARIA, keyboard navigation, and
  screen reader support. Use when building inclusive applications for all users.
---

# Frontend Accessibility

## When to Use

- Compliance with accessibility standards
- Inclusive design requirements
- Screen reader support
- Keyboard navigation
- Color contrast issues

## Quick Start

Minimal working example:

```html
<!-- Good semantic structure -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>

<main>
  <article>
    <header>
      <h1>Article Title</h1>
      <time datetime="2024-01-15">January 15, 2024</time>
    </header>
    <p>Article content...</p>
  </article>

  <aside aria-label="Related articles">
    <h2>Related Articles</h2>
    <ul>
      <li><a href="/article1">Article 1</a></li>
      <li><a href="/article2">Article 2</a></li>
    </ul>
  </aside>
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Semantic HTML and ARIA](references/semantic-html-and-aria.md) | Semantic HTML and ARIA |
| [Keyboard Navigation](references/keyboard-navigation.md) | Keyboard Navigation |
| [Color Contrast and Visual Accessibility](references/color-contrast-and-visual-accessibility.md) | Color Contrast and Visual Accessibility |
| [Screen Reader Announcements](references/screen-reader-announcements.md) | Screen Reader Announcements |
| [Accessibility Testing](references/accessibility-testing.md) | Accessibility Testing |
