---
name: api-error-handling
description: >
  Implement comprehensive API error handling with standardized error responses,
  logging, monitoring, retry logic, and validation patterns. Use when building
  resilient APIs, debugging issues, improving error reporting, implementing
  retry logic, handling HTTP error codes, managing API timeouts, designing
  error response handling, or adding circuit breaker patterns.
---

# API Error Handling

> [!NOTE]
> **Related skills:** For .NET Result pattern + ProblemDetails (RFC 9457), see `error-handling`. This skill covers language-agnostic API error strategies.

## Overview

Build robust error handling systems with standardized error responses, detailed
logging, error categorization, and user-friendly error messages. This skill
covers the full lifecycle from throwing typed errors through logging, monitoring,
and client-facing response formatting.

## When to Use

- Handling API errors consistently across endpoints
- Debugging production issues with request tracing
- Implementing error recovery strategies (retry, circuit breaker)
- Monitoring and alerting on error rates
- Providing meaningful, actionable error messages to clients
- Validating request inputs before processing
- Tracking error patterns over time

## Quick Start

Minimal standardized error response format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input validation failed",
    "statusCode": 422,
    "requestId": "req_abc123xyz789",
    "timestamp": "2025-01-15T10:30:00Z",
    "details": [
      { "field": "email", "message": "Invalid email format", "code": "INVALID_EMAIL" }
    ]
  }
}
```

Custom error class (Node.js):

```javascript
class ApiError extends Error {
  constructor(code, message, statusCode = null, details = null) {
    super(message);
    this.code = code;
    this.statusCode = statusCode || ERROR_CODES[code]?.status || 500;
    this.details = details;
    this.timestamp = new Date().toISOString();
  }
}

// Usage
throw new ApiError("NOT_FOUND", "User not found", 404);
throw new ApiError("VALIDATION_ERROR", "Missing fields", 422, fieldErrors);
```

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Error Codes & Response Format](references/error-codes-reference.md) | Complete `ERROR_CODES` map, response formatter, global middleware (Node.js + Python) |
| [Retry Strategies & Circuit Breaker](references/retry-strategies.md) | Exponential backoff, jitter, circuit breaker pattern |
| [Monitoring & Tracking](references/monitoring-patterns.md) | Sentry integration, error rate metrics, `/metrics/errors` endpoint |
| [Validation Patterns](references/validation-examples.md) | Input validation, schema guards, detecting bad responses before errors occur |
