---
name: profiling-optimization
description: >
  Profile application performance, identify bottlenecks, and optimize hot paths
  using CPU profiling, flame graphs, and benchmarking. Use when investigating
  performance issues or optimizing critical code paths.
---

# Profiling & Optimization

## When to Use

- Performance optimization
- Identifying CPU bottlenecks
- Optimizing hot paths
- Investigating slow requests
- Reducing latency
- Improving throughput

## Quick Start

Minimal working example:

```typescript
import { performance, PerformanceObserver } from "perf_hooks";

class Profiler {
  private marks = new Map<string, number>();

  mark(name: string): void {
    this.marks.set(name, performance.now());
  }

  measure(name: string, startMark: string): number {
    const start = this.marks.get(startMark);
    if (!start) throw new Error(`Mark ${startMark} not found`);

    const duration = performance.now() - start;
    console.log(`${name}: ${duration.toFixed(2)}ms`);

    return duration;
  }

  async profile<T>(name: string, fn: () => Promise<T>): Promise<T> {
    const start = performance.now();

    try {
      return await fn();
    } finally {
// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Node.js Profiling](references/nodejs-profiling.md) | Node.js Profiling |
| [Chrome DevTools CPU Profile](references/chrome-devtools-cpu-profile.md) | Chrome DevTools CPU Profile |
| [Python cProfile](references/python-cprofile.md) | Python cProfile |
| [Benchmarking](references/benchmarking.md) | Benchmarking |
| [Database Query Profiling](references/database-query-profiling.md) | Database Query Profiling |
| [Flame Graph Generation](references/flame-graph-generation.md) | Flame Graph Generation |
