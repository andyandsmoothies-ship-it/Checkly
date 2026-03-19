---
name: mobile-app-testing
description: >
  Comprehensive mobile app testing strategies for iOS and Android. Covers unit
  tests, UI tests, integration tests, performance testing, and test automation
  with Detox, Appium, and XCTest.
---

# Mobile App Testing

## When to Use

- Creating reliable mobile applications with test coverage
- Automating UI testing across iOS and Android
- Performance testing and optimization
- Integration testing with backend services
- Regression testing before releases

## Quick Start

Minimal working example:

```javascript
// Unit test with Jest
import { calculate } from "../utils/math";

describe("Math utilities", () => {
  test("should add two numbers", () => {
    expect(calculate.add(2, 3)).toBe(5);
  });

  test("should handle negative numbers", () => {
    expect(calculate.add(-2, 3)).toBe(1);
  });
});

// Component unit test
import React from "react";
import { render, screen } from "@testing-library/react-native";
import { UserProfile } from "../components/UserProfile";

describe("UserProfile Component", () => {
  test("renders user name correctly", () => {
    const mockUser = { id: "1", name: "John Doe", email: "john@example.com" };
    render(<UserProfile user={mockUser} />);

    expect(screen.getByText("John Doe")).toBeTruthy();
  });
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [React Native Testing with Jest & Detox](references/react-native-testing-with-jest-detox.md) | React Native Testing with Jest & Detox |
| [iOS Testing with XCTest](references/ios-testing-with-xctest.md) | iOS Testing with XCTest |
| [Android Testing with Espresso](references/android-testing-with-espresso.md) | Android Testing with Espresso |
| [Performance Testing](references/performance-testing.md) | Performance Testing |
