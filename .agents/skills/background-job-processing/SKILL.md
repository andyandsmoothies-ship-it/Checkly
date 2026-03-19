---
name: background-job-processing
description: >
---
name: background-job-processing
description: >
  Implement background job processing systems with task queues, workers,
  scheduling, and retry mechanisms. Use when handling long-running tasks,
  sending emails, generating reports, and processing large datasets
  asynchronously.
---

# Background Job Processing

## When to Use

- Long-running operations (report generation, data exports)
- Email/notification sending
- Scheduled recurring tasks (cron-style)
- Processing large datasets in batches
- Distributing compute-intensive work across workers

## Decision Guide

| Stack | Library | Best For |
|-------|---------|----------|
| Python | **Celery + Redis** | Full-featured: scheduling, retries, monitoring, result backend |
| Python | **Dramatiq + Redis** | Simpler API than Celery, better defaults |
| Python | **RQ (Redis Queue)** | Simple jobs, lightweight, no Celery complexity |
| Node.js | **BullMQ + Redis** | Production-grade: priority, rate limiting, repeatable jobs |
| Node.js | **Agenda + MongoDB** | If you're already on MongoDB, avoid adding Redis |
| .NET | **Hangfire** | Dashboard included, SQL Server or Redis backend |
| .NET | **Wolverine** | If already using it for messaging (see `dotnet-messaging`) |
| Ruby | **Sidekiq + Redis** | Industry standard for Rails, thread-based concurrency |

### Key Design Decisions

| Question | Recommendation |
|----------|---------------|
| Retry on failure? | Yes — exponential backoff with max retries and dead-letter queue |
| Need result of job? | Use result backend (Redis) only if needed — adds overhead |
| Priority queues? | Use separate queues per priority, not a single queue with weights |
| Job deduplication? | Use idempotency keys for non-idempotent operations |
| Monitoring? | Flower (Celery), BullMQ Dashboard, Hangfire Dashboard |

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Python with Celery and Redis](references/python-with-celery-and-redis.md) | Python with Celery and Redis |
| [Node.js with Bull Queue](references/nodejs-with-bull-queue.md) | Node.js with Bull Queue |
| [Ruby with Sidekiq](references/ruby-with-sidekiq.md) | Ruby with Sidekiq |
| [Job Retry and Error Handling](references/job-retry-and-error-handling.md) | Job Retry and Error Handling |
| [Monitoring and Observability](references/monitoring-and-observability.md) | Monitoring and Observability |
