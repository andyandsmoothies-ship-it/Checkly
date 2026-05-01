---
name: verification-loop
description: >
  7-phase .NET verification pipeline with structured PASS/FAIL reporting, post-implementation
  blast radius analysis, hostile interrogation, and manual testing handoff.
  Ensures every change is build-verified, diagnostics-clean, anti-pattern-free,
  test-passing, security-scanned, format-compliant, and diff-reviewed before
  marking work as complete. Load this skill when: "verify", "check everything",
  "run verification", "pre-PR check", "is this ready", "validate changes",
  "build and test", "quality gate", "pipeline check", "ready to merge",
  "blast radius", "is this safe", "hostile review", "red team", "what breaks".
---

# Verification Loop

## Core Principles

1. **Build is the minimum bar** — Never mark a task complete without a green `dotnet build`. If it doesn't compile, nothing else matters. A broken build wastes every subsequent phase's time.

2. **Automated checks before manual review** — Tools catch what humans miss. `get_diagnostics` finds nullability issues, `detect_antipatterns` catches `DateTime.Now` usage, and `dotnet test` proves behavior. Run all of these before eyeballing code.

3. **Short-circuit on critical failures** — If the build fails, don't run tests. If tests fail, don't run formatting checks. Failing fast saves time and keeps the feedback loop tight. Fix the most fundamental issue first.

4. **Structured reporting** — Every phase gets an explicit PASS, FAIL, or WARN status with details. No ambiguity. "It looks fine" is not a verification result. A table with statuses is.

5. **Verification is iterative** — A single pass rarely produces all-green. Fix the first failure, re-run from that phase, repeat until clean. The loop is the point.

---

## Part A: 7-Phase Automated Pipeline

Execute phases in order. Short-circuit on CRITICAL failures (Phase 1 and Phase 4).

**Phase 1: Build (CRITICAL)**
```
dotnet build --no-restore
```
Status: PASS (0 errors) / FAIL (N errors)
Short-circuit: If FAIL, stop all subsequent phases. Fix build errors first.
Note: Capture warning count even on PASS — new warnings are tracked in Phase 2.

**Phase 2: Diagnostics**
```
MCP: get_diagnostics(scope: "file", path: each changed file)
MCP: get_diagnostics(scope: "project", path: changed project)
```
Status: PASS (0 new warnings) / WARN (N new warnings) / FAIL (new errors)
Check: Compare against baseline — only flag NEW warnings introduced by the current changes.
Common findings: CS8600 (null reference), CS8602 (dereference of nullable), CS0219 (unused variable).

**Phase 3: Anti-pattern Scan**
```
MCP: detect_antipatterns(file: each changed file)
```
Status: PASS (0 anti-patterns) / WARN (N anti-patterns found)
Catches: async void, sync-over-async, `new HttpClient()`, `DateTime.Now`, broad catch,
logging string interpolation, missing CancellationToken, EF queries without AsNoTracking.

**Phase 4: Tests (CRITICAL)**
```
dotnet test --no-build
```
Status: PASS (all green) / FAIL (N failures)
Short-circuit: If FAIL, stop remaining phases. Fix failing tests before proceeding.
Note: If no test project exists, status is SKIP with a recommendation to add tests.

**Phase 5: Security Scan**
```
dotnet list package --vulnerable --include-transitive
```
Scan changed files for: hardcoded secrets, connection strings, API keys.
Check: OWASP patterns in new code (SQL injection, XSS, missing auth attributes).
Status: PASS / WARN (medium/low findings) / FAIL (critical/high vulnerabilities)

**Phase 6: Format Compliance**
```
dotnet format --verify-no-changes
```
Status: PASS (no changes needed) / FAIL (formatting violations found)
Fix: Run `dotnet format` and include formatting changes in the commit.

**Phase 7: Diff Review**
```
git diff --stat
git diff
```
Status: PASS (changes match intent) / WARN (unexpected files changed)
Check:
- No accidental files (`.vs/`, `bin/`, `obj/`, `.env`, secrets)
- No unrelated changes mixed in
- Commit scope matches the task description
- No debug code (`Console.WriteLine`, `#if DEBUG` blocks in production paths)

### Structured Report Format

After running all phases, produce a verification report:

```markdown
## Verification Report

| Phase | Status | Details |
|-------|--------|---------|
| 1. Build | PASS | 0 errors, 2 warnings (pre-existing) |
| 2. Diagnostics | WARN | CS8600 in OrderService.cs:47 — possible null reference |
| 3. Anti-patterns | PASS | 0 anti-patterns in changed files |
| 4. Tests | PASS | 42 passed, 0 failed, 0 skipped |
| 5. Security | PASS | No vulnerable packages, no secrets detected |
| 6. Format | PASS | No formatting violations |
| 7. Diff Review | PASS | 3 files changed, all match task scope |

**Overall: PASS (with warnings)**

### Action Items
- [ ] Fix CS8600 in OrderService.cs:47 — add null check or use null-forgiving operator with justification
```

---

## Part B: Post-Implementation Blast Radius & Handoff

Use this section after completing code changes, after fixing a bug, or when the user asks "is this safe to merge".

### Blast Radius Check

For every modified file, find all consumers:

| Modified File | Consumer | What it imports | Risk |
|:---|:---|:---|:---|
| `CreateArea.cs` | `AreaTests.cs` | `POST /api/areas` | Breaks if route or DTO changes |

**Actions:**
1. For server changes: `grep -r "ClassName" server/` to find references
2. For Flutter changes: `grep -r "ClassName" lib/` to find widget/service consumers
3. Document the chain and assess risk per consumer

### Structural Integrity

1. **Build Check**: `dotnet build` (server) and/or `flutter analyze` (mobile) — MANDATORY
2. **Ghost Audit**: Verify all usings/imports actually resolve. Remove dead imports.
3. **Zombie Check**: If any classes, methods, or exports were deleted, verify no references remain

### Logic & Integration Audit

1. **Contract Verification**: Every scenario in the spec has a passing test or verified logic block
2. **Schema Sync**: Cross-reference changed entities with `AppDbContext` — all `HasColumnName` mappings must be present
3. **Snapshot Check**: If the feature touches denormalized fields, verify dual writes (see `project-gotchas.md` #7)

### Manual Testing Handoff

Scope: Only scenarios that can't be automated (auth flows, visual UI, device-specific behavior).
Generate steps covering:
- **Critical Paths**: Steps to test the primary logic
- **Regression Checklist**: Existing features near the blast radius
- **Edge Case Triggers**: How to manually trigger error paths

### Supportability & Idiomatic Sweep (Crickett's Rule)

Before declaring the feature ready for human review, explicitly answer the following questions in your Walkthrough report:
- **What does this code do?**
- **Why is it done this way?**
- **What are the tradeoffs being made?**
If a junior engineer reading the walkthrough would not understand the tradeoffs, the verification FAILS. You must rewrite the documentation to be explicitly clear.

### Final Verdict

1. **Impact Statement**: "Modified [X] and verified that [Y] remains intact."
2. **Test Coverage Delta**: Report before/after test counts
3. **Verdict**: **PASS** or **PENDING HUMAN VERIFICATION**

---

## Part C: Hostile Interrogation (Red Team Gate)

When invoked during design review, verification, or PR review, you MUST halt and answer these three domain-specific "What breaks?" questions using the exact class names, database tables, and framework features of the current codebase.

AI agents suffer from the "Expert Witness Trap" — they will politely agree with a flawed design unless specifically cross-examined about scale extremes. This section counteracts that trap.

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

### 4. Trust Assumption Audit (Zero Trust)
- **Question**: "What happens if the caller (user, external API, or internal service) is compromised or malicious?"
- **Look For**: Implicit trust, lack of strict Policy-Based Access Control (PBAC), relying purely on client-side state for security, or missing signature/token validation.
- **Action**: Output where explicit verification is missing and enforce the principle of least privilege.

### Resolution Protocol

After answering the three questions:
1. If the code/design CANNOT survive these extremes → **Flag as deployment failure** and request a redesign.
2. Provide the exact code snippets or dependency patterns required to mitigate the identified extremes before handing control back to the original workflow.

---

## Fix-and-Retry Loop

When a phase fails, follow this exact sequence:

```
1. IDENTIFY — Which phase failed? What's the specific error?
2. FIX — Make the minimal change to resolve the issue
3. RE-RUN — Start from the failed phase (not from Phase 1, unless the fix changed code)
   Exception: If the fix involved code changes, re-run from Phase 1 (build)
4. REPEAT — Until all phases pass or you've identified an issue that needs user input

EXAMPLE:
Phase 4 fails: OrderServiceTests.CreateOrder_ReturnsCreated fails with 404
  → Fix: Route was "/orders" but test expected "/api/orders"
  → Re-run from Phase 1 (code changed) → Build PASS → Phase 4 PASS
  → Continue Phase 5, 6, 7
```

## Decision Guide

| Scenario | Phases | Notes |
|----------|--------|-------|
| Feature complete | All 7 + Part B + Part C | Full pipeline, no shortcuts |
| Bug fix (with test) | 1, 2, 4 | Build, diagnostics, tests |
| Bug fix (no test) | 1, 2, 3, 4 | Add a test, then verify |
| Formatting only | 6 | Format check is sufficient |
| Dependency update | 1, 4, 5 | Build, tests, security |
| Pre-PR | All 7 + Part B | Non-negotiable full pipeline |
| After refactor | 1, 2, 3, 4 | Focus on correctness |
| Config change | 1, 4 | Build and test |
| New endpoint added | All 7 + Part C | Full pipeline including hostile review |
| Test-only changes | 1, 4 | Build and run the new tests |
| Design review | Part C only | Hostile interrogation before coding |

## Anti-patterns

### Skipping Verification Entirely

```
# BAD — "it compiles in my head"
"I've made the changes. The code looks correct. Let me create the PR."
# No build run, no tests, no diagnostics — hope-driven development

# GOOD — verify before declaring done
"Let me run the verification pipeline before we create the PR."
→ Phase 1: Build PASS → Phase 2: Diagnostics PASS → ... → Phase 7: PASS
"All 7 phases passed. Creating the PR now."
```

### Running All Phases When Build Fails

```
# BAD — wasting time on downstream checks
Phase 1: Build FAIL (3 errors)
Phase 2: Running diagnostics anyway...

# GOOD — short-circuit and fix
Phase 1: Build FAIL (3 errors)
→ STOP. Fix the 3 build errors first.
→ Re-run from Phase 1.
```

### Ignoring Warnings

```
# BAD — "warnings are just suggestions"
Phase 2: 12 new CS8600 warnings introduced
"These are just warnings, not errors. Moving on."

# GOOD — treat new warnings as failures
Phase 2: 12 new CS8600 warnings introduced
"12 new nullability warnings detected. Fixing before proceeding."
→ Add null checks or non-nullable assertions with justification
→ Re-run Phase 2: 0 new warnings. PASS.
```

### Cherry-Picking Phases

```
# BAD — only running the phases you think are relevant
"It's just a service change, I'll skip the security scan."
# The service change added a raw SQL query with string concatenation

# GOOD — full pipeline for non-trivial changes
When in doubt, run all 7 phases. The cost of running extra phases is minutes.
The cost of missing a security issue is days of incident response.
```
