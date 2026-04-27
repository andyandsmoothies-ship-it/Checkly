---
description: Business Analysis Workflow. Define User Stories, Use Cases, and Business Rules before technical architecture.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /define-requirements

> [!NOTE]
> Used to bridge the gap between a raw idea and technical implementation. Establishes the "Who, What, and Rules" using the shaping methodology.

## Phase 1: Intake & Context Alignment
- [ ] **Task Tracking**: Create `task_[YYYYMMDD]_[ConversationID]_[topic].md` using the standard schema.
- [ ] **Skill Load**: Load the `shaping` skill from `.agents/skills/`.
- [ ] **Intake Gate**:
  - If the user provides a raw idea: Extract the `[ORIGIN_IDEA]`.
  - If the user provides an ADR (`decision_record.md`): Read the file, extract the chosen architecture, and use it as a strict constraint.

> **@@SCAN**: (1) Shaping skill loaded? (2) Input source identified (Raw vs ADR)?

## Phase 2: Use Cases & Slicing (The "What" and "Who")
- [ ] **Actors & RBAC**: Explicitly list every user role (e.g., Admin, Auditor) and their strict permissions.
- [ ] **Use Case Narrative**: Write the Main Success Scenario and all Alternate Flows (extensions/error states).
- [ ] **Use-Case Slicing**: Apply Use-Case 3.0 slicing. Break the large use case into smaller, logical, deliverable slices.
- [ ] **Testability Check (Binary Truth)**: For each slice, define plain-English Test Cases (Rules). MANDATORY: Acceptance criteria must be strictly binary (e.g. "Score returns 0", not "Score works well"). If a requirement is vague, push back and force a binary test contract.

> **@@SCAN**: (1) Are Use Cases sliced? (2) Do slices have plain-English Test Cases?

## Phase 3: The Fit Check
- [ ] **Apply Shaping**: Propose 1-3 high-level UX/Feature "Shapes" (mechanisms, not code). MANDATORY: To prevent Cognitive Debt, you MUST include a "Dumb Shape" (the absolute simplest flat/procedural solution) alongside any complex patterns. **MANDATORY Guardrail**: Do not select deep technical architectures (e.g., Database types, specific Push protocols) at this stage. Keep shapes strictly focused on Business Logic, UX, and Process flows.
- [ ] **Fit Matrix**: Create a Markdown table comparing the proposed Shapes against the Requirements.
- [ ] **Identify Unknowns**: Flag any unresolved business logic with ⚠️.

## Phase 4: Deliverable Generation
- [ ] **Artifact Gen**: Use `write_to_file` to save `requirements_[YYYYMMDD]_[ConversationID]_[topic].md` to the `brain/` directory.
- [ ] **Payload Schema**:
    1. `[ORIGIN_IDEA]` or `[ADR_REFERENCE]`.
    2. Defined Actors & RBAC Rules.
    3. The Use Case Narrative (Basic Scenario + Extensions).
    4. Use-Case Slices and their associated Test Cases (Acceptance Criteria).
    5. Selected Shape & Fit Check.
    6. **Concept Diagram**: A short, concise text-based flowchart (e.g., `[Actor] --> [Action] --> [System]`) explaining the core logic of the chosen shape.
    7. **Handoff Block**: Brief for the next Agent, and the next command (usually `[/analyze-feature]`, `[/atdd]`, or `[/research]`).
- [ ] **Workspace Copy**: Copy the artifact to `.agents/tmp/research/` so the user can review it.

> **Script Verification Gate (MANDATORY)**:
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
