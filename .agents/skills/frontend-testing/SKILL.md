---
name: frontend-testing
description: >
  Implement comprehensive frontend testing using Jest, Vitest, React Testing
  Library, and Cypress. Use when building robust test suites for UI and
  integration tests.
---

# Frontend Testing

## When to Use

- Component testing
- Integration testing
- End-to-end testing
- Regression prevention
- Quality assurance
- Test-driven development

## Quick Start

Minimal working example:

```typescript
// Button.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { Button } from './Button';

describe('Button Component', () => {
  it('renders button with text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = jest.fn();
    render(<Button onClick={handleClick}>Click</Button>);

    fireEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('disables button when disabled prop is true', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('applies variant styles correctly', () => {
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Jest Unit Testing (React)](references/jest-unit-testing-react.md) | Jest Unit Testing (React) |
| [React Testing Library Integration Tests](references/react-testing-library-integration-tests.md) | React Testing Library Integration Tests |
| [Vitest for Vue Testing](references/vitest-for-vue-testing.md) | Vitest for Vue Testing |
| [Cypress E2E Testing](references/cypress-e2e-testing.md) | Cypress E2E Testing |
| [Test Coverage Configuration](references/test-coverage-configuration.md) | Test Coverage Configuration |
