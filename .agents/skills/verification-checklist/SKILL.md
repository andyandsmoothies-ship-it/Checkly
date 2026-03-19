---
name: verification-checklist
description: Post-implementation verification checklist covering blast radius, structural integrity, logic audit, automated test generation, and manual testing handoff. Use after coding to verify changes are safe before merge.
allowed-tools: Read, Glob, Grep, Write, Edit, Terminal
---

# Verification Checklist

> [!NOTE]
> **Related skills:** For a full 7-phase automated .NET verification pipeline (build, diagnostics, anti-patterns, tests, security, format, diff), see `verification-loop`. This skill covers post-implementation blast radius analysis and manual testing handoff.

> Invoke this skill after implementing code changes to validate correctness and safety.

## When to Use

- After completing code changes (invoked by `/implement` Phase 5)
- After fixing a bug to verify the fix + blast radius
- When user asks "verify changes", "is this safe to merge", "run checks"
- After `/atdd` revision loops

---

## Phase 1: Blast Radius Check

**Goal**: Identify "Consumer" components that might break.

1. For every modified file, run `grep -r "[exportedName]" src/` to find other files that import it
2. Document the consumer chain:

| Modified File | Consumer | What it imports | Risk |
|:---|:---|:---|:---|
| `serviceX.ts` | `useHookY.ts` | `fetchItems()` | Breaks if return type changes |

---

## Phase 2: Structural Integrity (The Shield)

**Goal**: Ensure global type safety and build compatibility.

// turbo
1. **TypeScript Check**: Run `npx tsc --noEmit` — MANDATORY
// turbo
2. **Build Check**: Run `npm run build` — catches bundler-specific issues (Vite, PWA)
3. **Ghost Audit**: Verify all `useState`, `useEffect`, custom hooks, and Lucide icons are explicitly imported (Zero Ghost Import Protocol)
4. **Zombie Check**: If any variables or exports were deleted, verify no references to them remain across the project

---

## Phase 3: Logic & Integration Audit

**Goal**: Verify the "invisible" connections between features.

1. **Prop Alignment**: If a component's interface changed, verify parent components pass correct data
2. **State Mapping**: Compare implemented logic against "Edge Cases" from the spec
3. **Contract Verification**: Every scenario in the "Logic Validation Plan" has a passing test or verified logic block
4. **Schema Sync**: Cross-reference changed code with `src/integrations/supabase/types.ts` — column names must match perfectly

---

## Phase 4: Automated Test Generation (The Net)

**Goal**: Capture automatable scenarios as permanent regression tests.

### Triage
| Category | Automate? | Examples |
|:---|:---|:---|
| **Pure logic** (hooks, utils, schemas) | ✅ Vitest | State transitions, validation rules, scoring |
| **Component behavior** (show/hide, disabled) | ✅ Vitest + RTL | Button visibility, conditional rendering |
| **DB triggers / RPC** | ❌ Manual or pgTAP | Trigger sequencing, snapshot writes |
| **Auth / Session** | ❌ Manual or E2E | Login flows, role-based access |

### Write Tests
For each ✅ scenario:
- **Location**: `src/test/hooks/` for hooks, `src/test/schemas/` for validation, co-located `__tests__/` for services
- **Style**: Gherkin-style scenario names (`Scenario N: [Given] → [Expected]`)
- **Fixtures**: Use `makeDraft()`-style factory helpers, not raw object literals
- **No mocking overkill**: Mock only what's necessary (Logger, Supabase client)
- **No type-checking tests**: Don't write tests for what the type system already guarantees (shapes, required fields, return types). Test *behavior*, not *types*.

// turbo
3. **Run**: `npx vitest run [new test files]` — ALL tests must pass

---

## Phase 5: Manual Testing Handoff

**Goal**: Provide a high-precision guide for scenarios requiring a live environment.

- **Scope**: Only scenarios that failed Phase 4 triage (DB triggers, auth, visual UI)
- Generate steps covering:
  - **Critical Paths**: Steps to test the primary logic
  - **Regression Checklist**: Existing features near the "Blast Radius"
  - **Edge Case Triggers**: How to manually trigger error paths

---

## Phase 6: Final Verdict

1. **Impact Statement**: "Modified [X] and verified that [Y] remains intact."
2. **Test Coverage Delta**: Report before/after test counts (e.g., "42 → 63 tests")
3. **Verdict**: **PASS** or **PENDING HUMAN VERIFICATION**
