---
name: cross-platform-compatibility
description: >
  Handle cross-platform compatibility including file paths, environment
  detection, platform-specific dependencies, and testing across Windows, macOS,
  and Linux. Use when dealing with platform-specific code or OS compatibility.
---

# Cross-Platform Compatibility

## When to Use

- Building applications for multiple operating systems
- Handling file system operations
- Managing platform-specific dependencies
- Detecting operating system and architecture
- Working with environment variables
- Building cross-platform CLI tools
- Dealing with line endings and character encodings
- Managing platform-specific build processes

## Quick Start

Minimal working example:

```typescript
// ❌ BAD: Hardcoded paths with platform-specific separators
const configPath = "C:\\Users\\user\\config.json"; // Windows only
const dataPath = "/home/user/data.txt"; // Unix only

// ✅ GOOD: Use path module
import path from "path";
import os from "os";

// Platform-independent path construction
const configPath = path.join(os.homedir(), "config", "app.json");
const dataPath = path.join(process.cwd(), "data", "users.txt");

// Resolve relative paths
const absolutePath = path.resolve("./config/settings.json");

// Get path components
const dirname = path.dirname("/path/to/file.txt"); // '/path/to'
const basename = path.basename("/path/to/file.txt"); // 'file.txt'
const extname = path.extname("/path/to/file.txt"); // '.txt'

// Normalize paths (handle .. and .)
const normalized = path.normalize("/path/to/../file.txt"); // '/path/file.txt'
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [File Path Handling](references/file-path-handling.md) | File Path Handling |
| [Platform Detection](references/platform-detection.md) | Platform Detection |
| [Line Endings](references/line-endings.md) | Line Endings |
| [Environment Variables](references/environment-variables.md) | Environment Variables |
| [Shell Commands](references/shell-commands.md) | Shell Commands |
| [File Permissions](references/file-permissions.md) | File Permissions |
| [Process Management](references/process-management.md) | Process Management |
| [Platform-Specific Dependencies](references/platform-specific-dependencies.md) | Platform-Specific Dependencies |
| [Testing Across Platforms](references/testing-across-platforms.md) | Testing Across Platforms |
| [Character Encoding](references/character-encoding.md) | Character Encoding |
| [Build Configuration](references/build-configuration.md) | Build Configuration |
