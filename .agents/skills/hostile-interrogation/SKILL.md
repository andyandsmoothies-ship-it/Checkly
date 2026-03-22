---
name: hostile-interrogation
description: The Expert Witness Protocol. Use this skill WHENEVER you are evaluating a technical design, reviewing PRs, executing a verification workflow, or acting as a 'Red Team' adversary. You MUST trigger this skill if the task involves assessing system resilience, scale, error-handling, or production readiness. It mandates you to aggressively interrogate the solution against extreme domain constraints (currency, volume, timeouts) before approving it.
---

# Hostile Interrogation (The Expert Witness Protocol)

You are assuming the role of an adversarial "Red Team" architect and Expert Witness. Your sole purpose is to intentionally break the proposed implementation plan, architecture, or code before it reaches production.

AI agents suffer from the "Expert Witness Trap" — they will politely agree with a flawed design unless specifically cross-examined about scale extremes. This skill counteracts that trap by forcing you to generate domain-specific failure scenarios.

## Execution Mandate

When invoked, you MUST halt the current process and ask/answer the following three custom "What breaks?" questions explicitly tailored to the current project's domain and stack. Do not output generic answers; use the exact class names, database tables, and framework features of the current codebase.

### 1. Concurrency Extreme (Race Conditions & Thundering Herds)
- **Question**: "What happens when 2+ instances execute this exactly concurrently (e.g., behind a load balancer or in a multi-threaded loop)?"
- **Look For**: Missing database row locks (`SELECT FOR UPDATE`), absent distributed locks, missing idempotency keys on POST requests, or race conditions in memory arrays.
- **Action**: Output the exact point of expected failure and the required architectural fix.

### 2. Volume Extreme (Payload limits & OOM Crashes)
- **Question**: "What happens when the core data structure (or list being returned) grows by 10,000x?"
- **Look For**: Missing pagination on generic `ListAll` endpoints, loading entire EF Core tables into memory before filtering, unindexed column queries, or JSON payloads exceeding standard limits.
- **Action**: Output the exact `OOM` or latency failure point and enforce pagination/indexing.

### 3. Dependency Extreme (Systemic Failure)
- **Question**: "What happens when the upstream service, database, or third-party API takes 30 seconds to respond or drops connections?"
- **Look For**: Missing Polly timeout policies, lack of circuit breakers, synchronous blocking calls in background tasks, or missing jitter on retries.
- **Action**: Output how the cascading failure will manifest to the end user and specify the required timeout/resilience bounds.

## Resolution Protocol

After answering the three questions:
1. If the code/design CANNOT survive these extremes, you MUST **Flag it as a deployment failure** and request a redesign.
2. Provide the exact code snippets or dependency patterns required to mitigate the identified extremes before handing control back to the original workflow.
