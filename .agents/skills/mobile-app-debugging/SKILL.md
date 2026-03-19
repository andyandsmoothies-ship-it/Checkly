---
name: mobile-app-debugging
description: >
  Debug issues specific to mobile applications including platform-specific
  problems, device constraints, and connectivity issues.
---

# Mobile App Debugging

## When to Use

- App crashes on mobile
- Performance issues on device
- Platform-specific bugs
- Network connectivity issues
- Device-specific problems

## Quick Start

Minimal working example:

```yaml
Xcode Debugging:

Attach Debugger:
  - Xcode → Run on device
  - Set breakpoints in code
  - Step through execution
  - View variables
  - Console logs

View Logs:
  - Xcode → Window → Devices & Simulators
  - Select device → View Device Logs
  - Filter by app name
  - Check system logs for crashes

Inspect Memory:
  - Xcode → Debug → View Memory Graph
  - Identify retain cycles
  - Check object count
  - Monitor allocation growth

---
Common iOS Issues:

App Crash (SIGABRT):
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [iOS Debugging](references/ios-debugging.md) | iOS Debugging |
| [Android Debugging](references/android-debugging.md) | Android Debugging |
| [Cross-Platform Issues](references/cross-platform-issues.md) | Cross-Platform Issues |
| [Mobile Testing & Debugging Checklist](references/mobile-testing-debugging-checklist.md) | Mobile Testing & Debugging Checklist |
