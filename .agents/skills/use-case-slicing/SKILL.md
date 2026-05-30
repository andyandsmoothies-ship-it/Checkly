---
name: use-case-slicing
description: Formally apply the Vertical Slicing methodology. Use this skill when asked to break down, slice, or partition work to guarantee slices are end-to-end, testable, and vertically integrated.
---

# Universal Vertical Slicing Methodology

This skill implements the formal Vertical Slicing strategy. It prevents "horizontal slicing" (e.g., building databases before APIs) by ensuring every piece of work is a testable, end-to-end slice of value.

## The 5 Golden Rules of Slicing

### Rule 1: Slices MUST be Vertical (End-to-End)
- A slice cuts through all architectural layers (UI, API, DB) to deliver observable value.
- **Sizing**: Limit slices by **Test Contracts**, not strict file counts. A healthy slice fulfills a single behavioral goal (e.g., 1-5 test contracts).
- **Wiring vs. Core**: Group trivial "wiring" files (like passing a boolean flag through mappers) with the core logic. Do not split them horizontally.

### Rule 2: Start with the Happy Path
- Slice 1 must ALWAYS be the **Basic Scenario** (the core, error-free path).
- Define subsequent slices for **Extensions** (alternative paths, edge cases, error handling).

### Rule 3: Slices MUST be Testable
- A slice is defined by its Test Contracts. 
- It must start with a detectable trigger and end at a verifiable stop condition.

### Rule 4: Slices Must be Independent
- Minimize cross-feature coupling. Later slices should not break earlier ones.
- Isolate the highest technical risk or core value in Slice 1.

### Rule 5: State Invariants (The Causal Chain)
- Every slice MUST define its **Entry State Required** (preconditions) and **Exit State Guaranteed** (postconditions).

---

## Output Format: How to Define Micro-Specs

When orchestrating work, define your slices using this concise format:

**Slice [N]: [Name of the Slice]**
- **Plain English Summary**: Simple explanation of what this slice builds and why.
- **Scenario Focus**: Basic Scenario or Extension?
- **Value Delivered**: What can the user actually achieve when this is done?
- **Entry State Required**: What MUST be true before starting?
- **Exit State Guaranteed**: What invariant holds true after completion?
- **Architectural Scope**: The UI, API, and DB components touched.
- **Acceptance Criteria**: Strict Test Contract Matrix (including edge cases).
