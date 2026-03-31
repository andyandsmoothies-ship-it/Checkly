---
name: systematic-debugging
description: 4-phase systematic debugging methodology with root cause analysis, UDAT-specific diagnostics (Schema, RLS, Ghost imports), and evidence-based verification. Use when debugging complex issues, investigating bugs, or when user asks to diagnose a problem.
allowed-tools: Read, Glob, Grep
---

# Systematic Debugging

> Combines generic debugging methodology with UDAT project-specific diagnostics.

## When to Use

- User reports a bug or error
- A test is failing unexpectedly
- User says "debug", "investigate", "diagnose", "why is this broken"
- After a refactor when behavior has changed unexpectedly

---

## Phase 0: Global Health Check (MANDATORY)

> Eliminate unrelated build errors before deep-diving into the symptom.

1. Run `npm run lint 2>&1` and `npx tsc --noEmit 2>&1`
2. If errors exist OUTSIDE the suspected files → fix those first (they're likely the root cause)
3. Re-test the symptom after fixing global errors

---

## Phase 1: Reproduce

Before fixing, reliably reproduce the issue.

```markdown
## Reproduction Steps
1. [Exact step to reproduce]
2. [Next step]
3. [Expected vs actual result]

## Reproduction Rate
- [ ] Always (100%)
- [ ] Often (50-90%)
- [ ] Sometimes (10-50%)
- [ ] Rare (<10%)
```

---

## Phase 2: Isolate & Investigate

Narrow down the source using structured questions + UDAT-specific audits.

### General Isolation
- When did this start happening?
- What changed recently? (`git log --oneline -10`)
- Does it happen in all environments?
- Can we reproduce with minimal code?

### UDAT-Specific Audits

**Schema Audit**: `cat src/integrations/supabase/types.ts` — verify that the tables/columns used in the erroring code actually exist.

**RLS & Permission Check**: Check `supabase/migrations/` for the RLS policies of the affected table. Does the current user role have the permissions required for the failing operation?

**Ghost Import Audit**: Use `grep` to check for missing or hallucinated imports in the failing file. Cross-reference with the `Zero Ghost Import Protocol` in `standards.md`.

**Network Audit**: Check browser DevTools for Supabase request payloads and responses (look for 403 RLS errors or empty arrays).

---

## Phase 3: Root Cause Analysis

Find the root cause, not just symptoms. You MUST use Semi-Formal Reasoning to prevent hallucinated fixes.

### Semi-Formal Reasoning Trace (MANDATORY)
Before formulating a conclusion, you must output a structured trace:
1. **Explicit Premises**: What is the known state and expected behavior based ONLY on the actual code you have read?
2. **Execution Trace**: A line-by-line trace of the execution path through the local files. You must prove you have read the files.
3. **Formal Conclusion**: The verified root cause based strictly on the evidence in the trace, not assumptions based on function names.

### The 5 Whys
1. Why: [First observation]
2. Why: [Deeper reason]
3. Why: [Still deeper]
4. Why: [Getting closer]
5. Why: [Root cause]

### Classification
Classify the root cause:
| Category | Examples |
|:---|:---|
| **Logic** | Wrong condition, missing edge case, stale closure |
| **Schema** | Column renamed/removed, wrong table join |
| **RLS** | Missing policy, wrong role check |
| **Race Condition** | Async ops completing out of order |
| **Ghost Import** | Using a variable/hook that was never imported |

---

## Phase 4: Fix & Verify

Fix and verify it's truly fixed.

```markdown
## Fix Verification
- [ ] Bug no longer reproduces
- [ ] Related functionality still works
- [ ] No new issues introduced
- [ ] Test added to prevent regression
- [ ] `npx tsc --noEmit` passes
```

---

## Failure Report (Handoff Artifact)

If this skill is invoked as part of a diagnostic workflow, generate a `failure_report_[topic].md` with:

- **Symptom**: What the user sees
- **Root Cause**: Why it's happening (Logic vs. Schema vs. RLS)
- **Fix Strategy**: High-level description of the required code changes
- **Regression Test**: What test should be written to prevent recurrence

---

## Anti-Patterns

❌ **Random changes** — "Maybe if I change this..."
❌ **Ignoring evidence** — "That can't be the cause"
❌ **Assuming** — "It must be X" without proof
❌ **Not reproducing first** — Fixing blindly
❌ **Stopping at symptoms** — Not finding root cause
