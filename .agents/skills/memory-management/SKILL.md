---
name: memory-management
description: >
  Detect and fix memory leaks, profile memory usage, and optimize application
  memory footprint. Covers heap snapshots, memory profiling tools, common leak
  patterns (event listeners, timers, circular references, caches), WeakMap/WeakRef
  for caches, production monitoring, and optimization techniques.
  Use when investigating memory growth, OOM errors, optimizing memory usage,
  container restarts, or performance degradation due to memory pressure.
  Supports Node.js (v8 heap snapshots), browser (Chrome DevTools), and .NET
  (dotnet-dump, dotnet-counters) profiling.
---

# Memory Management

Identify, diagnose, and fix memory issues to prevent out-of-memory crashes and optimize application performance.

## When to Use

- Memory usage growing over time
- Out of memory (OOM) errors or container restarts
- Performance degradation under load
- High memory consumption in production
- Suspected memory leaks in event listeners, timers, or caches

## Detection Patterns

### Common Leak Sources

| Pattern | Risk | Fix |
|---------|------|-----|
| Event listeners not removed | High | `removeEventListener` on cleanup |
| Timers/intervals not cleared | High | `clearInterval`/`clearTimeout` |
| Circular references | Medium | Break cycles, use `WeakRef` |
| Unbounded caches | High | Set max size, use `WeakMap` |
| Closures holding large objects | Medium | Nullify references after use |
| Detached DOM nodes | Medium | Remove references to detached elements |

### Profiling Tools

| Tool | Platform | Use Case |
|------|----------|----------|
| Chrome DevTools → Memory | Browser | Heap snapshots, allocation timeline |
| `v8.writeHeapSnapshot()` | Node.js | Server-side heap analysis |
| `process.memoryUsage()` | Node.js | Quick RSS/heap checks |
| `dotnet-dump` | .NET | Managed heap analysis |
| `dotnet-counters` | .NET | Real-time GC/memory metrics |

## Best Practices

### ✅ DO
- Remove event listeners when components unmount
- Clear timers and intervals on cleanup
- Use `WeakMap`/`WeakRef` for object caches
- Set explicit cache size limits with eviction
- Monitor memory in production with alerts
- Profile regularly during development
- Use `Span<T>` and `ArrayPool<T>` for .NET hot paths

### ❌ DON'T
- Hold references to large objects unnecessarily
- Create unbounded caches without eviction
- Ignore steady memory growth in production
- Use `byte[]` when `Span<byte>` suffices (.NET)
- Forget to clean up resources in `IDisposable`
