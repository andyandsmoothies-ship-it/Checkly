---
name: performance-testing
description: >
  Design and execute performance tests to measure response times, throughput,
  and resource utilization. Use for performance test, load test, JMeter, k6,
  benchmark, latency testing, and scalability analysis.
---

# Performance Testing

## When to Use

- Validating response time requirements
- Measuring API throughput and latency
- Testing database query performance
- Identifying performance bottlenecks
- Comparing algorithm efficiency
- Benchmarking before/after optimizations
- Validating caching effectiveness
- Testing concurrent user capacity

## Quick Start

Minimal working example:

```javascript
// load-test.js
import http from "k6/http";
import { check, sleep } from "k6";
import { Rate, Trend } from "k6/metrics";

// Custom metrics
const errorRate = new Rate("errors");
const orderDuration = new Trend("order_duration");

// Test configuration
export const options = {
  stages: [
    { duration: "2m", target: 10 }, // Ramp up to 10 users
    { duration: "5m", target: 10 }, // Stay at 10 users
    { duration: "2m", target: 50 }, // Ramp up to 50 users
    { duration: "5m", target: 50 }, // Stay at 50 users
    { duration: "2m", target: 0 }, // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests under 500ms
    http_req_failed: ["rate<0.01"], // Error rate under 1%
    errors: ["rate<0.1"], // Custom error rate under 10%
  },
};

// ... (see reference guides for full implementation)
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [k6 for API Load Testing](references/k6-for-api-load-testing.md) | k6 for API Load Testing |
| [Apache JMeter](references/apache-jmeter.md) | Apache JMeter |
| [pytest-benchmark for Python](references/pytest-benchmark-for-python.md) | pytest-benchmark for Python |
| [JMH for Java Benchmarking](references/jmh-for-java-benchmarking.md) | JMH for Java Benchmarking |
| [Database Query Performance](references/database-query-performance.md) | Database Query Performance |
| [Real-Time Monitoring](references/real-time-monitoring.md) | Real-Time Monitoring |
