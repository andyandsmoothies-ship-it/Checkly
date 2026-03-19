---
name: flutter-development
description: >
  Build beautiful cross-platform mobile apps with Flutter and Dart. Covers
  widgets, state management with Provider/BLoC, navigation, API integration, and
  material design.
---

# Flutter Development

> [!NOTE]
> **Related skills:** For the Flutter widget API reference, see `flutter-api`. For PFA architecture (Services/Managers/Views with get_it), see `flutter-architecture`. This skill covers general Flutter development patterns (Provider/BLoC, navigation, material design).

## When to Use

- Building iOS and Android apps with native performance
- Designing custom UIs with Flutter's widget system
- Implementing complex animations and visual effects
- Rapid app development with hot reload
- Creating consistent UX across platforms

## Quick Start

Minimal working example:

```dart
// pubspec.yaml
name: my_flutter_app
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  http: ^1.1.0
  go_router: ^12.0.0

// main.dart with GoRouter navigation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Project Structure & Navigation](references/project-structure-navigation.md) | Project Structure & Navigation |
| [State Management with Provider](references/state-management-with-provider.md) | State Management with Provider |
| [Screens with Provider Integration](references/screens-with-provider-integration.md) | Screens with Provider Integration |
