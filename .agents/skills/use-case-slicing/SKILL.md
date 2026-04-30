---
name: use-case-slicing
description: Formally apply the Ivar Jacobson Use-Case 3.0 slicing methodology. Use this skill when asked to break down, slice, configure increments, or partition work (especially within the /analysis workflow), to guarantee slices are end-to-end, testable, independent, and vertically integrated.
---

# Use-Case 3.0 Slicing Methodology

This skill implements the formal Vertical Slicing strategy defined by Ivar Jacobson's Use-Case 3.0 framework. It prevents the "Waterfall Trap" (horizontal slicing) by ensuring every piece of work is a perfectly testable, end-to-end slice of value.

## The Slicing Mandate

A "Use-Case Slice" is a slice of a use case that provides clear value to stakeholders. When slicing features into "Micro-Specs", you must adhere strictly to these 4 Golden Rules:

### Rule 1: Slices MUST be Vertical (End-to-End)
- A slice is **more** than just requirements. It generally cuts completely through every tier of the architecture.
- **Exception for AI Context Limits (Maximum Thickness):** If a vertical slice is too heavy (e.g., requires touching >3 files or complex DB relationships), you MUST split it horizontally (e.g., "Data Layer Slice" first, then "API Endpoint Slice") to protect the AI's context window.
- Otherwise, for a standard slice to be valid, it MUST include:
  1. **Requirements** (The specific interaction being tested)
  2. **Design** (The architectural elements involved)
  3. **Implementation** (The actual code spanning Frontend UI, Backend API, and Database)
  4. **Test** (The test scripts and test results)
- **ANTI-PATTERN TO AVOID**: Do not create horizontal slices ("Build the DB layout") *unless* the full vertical slice exceeds the maximum thickness limit.

### Rule 2: Start with the Basic Scenario (Happy Path)
- To find the most central slice of a new feature, focus exclusively on the **Basic Scenario**. This is the core, most straightforward way for the user to achieve their goal without hitting errors.
- Extract the Basic Scenario as "Slice 1" (do not abbreviate as "S1").
- Once the Basic Scenario slice is defined, define subsequent slices representing the **Extensions** (alternative paths, edge cases, error handling). 
- Do not try to pack all extensions into the first slice.

### Rule 3: Slices MUST be Testable
- The most important part of a Use-Case Slice's description is its Test Cases. They make it a verifiable deliverable.
- A slice always starts with a user doing something the system can detect, and always ends at a specific stop condition (success or failure).

### Rule 4: Slices Must be Independent
- Slices should minimize cross-feature coupling. Later slices should not break earlier slices.
- If an epic is large, isolate the highest risk or core value in Slice 1.

### Rule 5: Slices MUST Enforce State Invariants (The Causal Chain)
- To prevent "myopic" local decisions that break the broader flow, every slice MUST explicitly define its **Entry State Required** (preconditions) and **Exit State Guaranteed** (postconditions).
- When implementing a slice, the first action must be to assert the Entry State. The final action must guarantee the Exit State.

---

### AI-First Development Constraint
**CRITICAL RULE:** Do NOT decompose Use Case Slices down into granular Agile "User Stories". 
- Human teams need tiny user stories because human working memory is small, and humans use ticketing systems (like Jira). 
- An AI Builder agent (`/implement`) does NOT suffer from these constraints. It is optimally designed to ingest an **entire Vertical Slice (Micro-Spec)** in one context window and build the UI, Backend, and DB concurrently.
- Therefore, your output MUST STOP at the Use-Case Slice (Micro-Spec) level. **Never generate a backlog of User Stories.**

---

## Output Format: How to Define Micro-Specs

When orchestrating work or handing off an analysis plan (e.g., in `analysis_[topic].md`), define your slices using the following format. 
**Crucial:** You must follow the `Accessible Communication Protocol`. Use simple, clear, everyday English so the user understands *why* we are doing this work.

**Slice [N]: [Name of the Slice]**
- **Plain English Summary**: [A friendly, simple explanation of what this slice actually builds and why the project needs it. Avoid heavy tech jargon.]
- **Why this step now?**: [Explain the logic of the ordering. Why must this slice happen *after* the previous one, and *before* the next one?]
- **Scenario Focus**: [Is this the Basic Scenario or an Extension?]
- **Value Delivered**: [What can the user actually click or achieve when this is done?]
- **Entry State Required**: [What MUST be true before this slice can begin?]
- **Exit State Guaranteed**: [What invariant MUST hold true after this slice completes?]
- **Architectural Scope**: [Explicitly mention the UI, Backend, and DB components this slice will touch]
- **Acceptance Criteria**: [Provide a strict Test Contract Matrix. **CRITICAL:** Every boundary constraint and edge case MUST be an explicit row in the matrix. Include raw JSON Request/Response payloads for APIs, and explicitly state required test fixture setup (e.g., 'Requires Seeded Admin').]
