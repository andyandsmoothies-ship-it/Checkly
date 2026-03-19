---
name: tdd
description: Load this skill whenever building features or fixing bugs using TDD, when the user mentions "red-green-refactor", wants integration tests, or explicitly asks for test-first development.
---

# Test-Driven Development

## Philosophy

**Core principle**: A TDD "test" is a **specification**, not a test. It's an example of how you expect to use the code you're about to write. You write the spec first (RED), kluge together just enough code to satisfy it (GREEN), then refactor until the code is high quality. The spec drives the design — hence "test-driven **design**."

**Wishful Amnesia**: When writing a spec, forget how the system works internally. Ask: "What does the consumer need?" — not "What can the system do?" This consumer-first perspective is what makes specs survive refactors.

**Good specs** exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good spec reads like a requirement — "user can checkout with valid cart" tells you exactly what capability exists. These survive refactors because they don't care about internal structure.

**Bad specs** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means. The warning sign: your spec breaks when you refactor, but behavior hasn't changed.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Spec-Tests vs Unit Tests

These are two different things that often happen at the same time. Don't confuse them.

| | Spec-Test (drives TDD) | Unit Test (guards regressions) |
|---|---|---|
| **Purpose** | Specifies new behavior, drives the design forward | Covers corner cases, failure modes, edge cases |
| **When written** | Before the code exists (RED phase) | After the code works (during or after REFACTOR) |
| **Who writes it** | Human defines intent; AI implements the code | AI can help write these |
| **Happy path?** | Usually yes — one clear usage example | No — boundary conditions, error paths |
| **If from /atdd** | The Gherkin scenarios ARE your spec-tests — don't re-spec them | Add these after the spec-tests pass |

> [!IMPORTANT]
> When specs arrive from the `/atdd` workflow, they ARE the RED starting point. Do not re-specify what ATDD already defined — go straight to GREEN.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" — treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes — they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

> [!IMPORTANT]
> **Don't write tests for what the type system already guarantees.** If TypeScript enforces a shape, a required field, or a return type — trust it. Testing that a function "returns a string" when the signature says `(): string` is a shit test. Reserve tests for *behavior* the compiler can't see: business rules, state transitions, conditional logic, and edge cases.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

Hacks are expected in GREEN: hardcoded values, duplication, everything in one file. The goal is feedback speed — prove the spec is correct before investing in structure.

This is your tracer bullet — proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Look for new abstractions — simplifying often means creating MORE things, not fewer
- [ ] Organize boundaries — separate files, directories, new interfaces
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```

## Project-Specific Rules

- **No Raw DOM** — All assertions go through Drivers (`app.form.submit()`), never raw `screen.getByText()` or `fireEvent.click()`
- **Driver Pattern** — Use `AppDriver` from `src/test/drivers/` to abstract test setup
- **Gherkin Naming** — Test names follow `Scenario N: [Given] → [Expected]` convention
