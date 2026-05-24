---

description: Business Analysis Workflow. Define User Stories, Use Cases, and Business Rules before technical architecture.

---

# Workflow: /define-requirements

> [!NOTE]

> Used to bridge the gap between a raw idea and technical implementation. Establishes the "Who, What, and Rules" using the shaping methodology.

## Step 1: Intake & Context Alignment

- [ ] **Task Tracking**: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` using the standard schema. Include an `## Input Lineage` section tracking the origin idea or link.

- [ ] **Skill Load**: Load the `shaping` skill, the `use-case-creator` skill, and the `use-case-slicing` skill from `.agents/skills/`.

- [ ] **Intake Gate**:

  - If the user provides a raw idea: Extract the `[ORIGIN_IDEA]`.

  - If the user provides an ADR (`decision_record.md`): Read the file, extract the chosen architecture, and use it as a strict constraint.

- [ ] **Interrogation Gate (Grilling)**: **MANDATORY.** Before writing any plan, cross-reference the user's idea against the codebase and `GEMINI.md`. If terminology is sloppy (e.g., mixing "Account" and "User"), or if the idea contradicts existing code logic, **STOP**. Ask the user to clarify. Do not proceed until terminology is precise.

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Shaping skill loaded? (2) Input source identified (Raw vs ADR)? (3) Did you cross-reference terminology with the code and push back on vague terms?

## Step 2: The 3 Core Contexts (Functional, Visual, Data)

- [ ] **1. Functional Context (Use Cases)**: Write the Main Success Scenario and all Alternate Flows (extensions/error states) strictly using the formal structure defined in the `use-case-creator` skill. Explicitly list Actors & RBAC permissions.

- [ ] **2. Visual Context (UI Flow & Screens)**: Map the exact UI screens, modals, or CLI commands required to fulfill those Use Cases. Use ASCII wireframes or Mermaid diagrams to visualize the flow. Do not leave the UI to guesswork.

- [ ] **3. Data Context (Schema)**: Map the rough data model, entities, and mock JSON needed to populate the visual context.

- [ ] **Traceability Check**: MANDATORY: Does every Use Case have a mapped UI screen? Does every UI screen have a data schema? If no, fix it before slicing.

- [ ] **Use-Case Slicing**: Apply Use-Case 3.0 slicing. Break the large use case into smaller, logical, deliverable slices. Each slice must include its Functional, Visual, and Data context.

- [ ] **Testability Check (EARS Notation & Bug Hunt)**: For each slice, define plain-English Acceptance Criteria.

  - MANDATORY: Use **EARS notation** (e.g., "WHEN [nominal trigger], THE System SHALL [response]" or "IF [error condition], THEN THE System SHALL [response]").

  - **Audit for the 4 Requirement Bugs**:

    1. **Wrong Level of Detail**: Are these observable behaviors, or just thesis statements/implementation recipes?

    2. **Ambiguity**: Are there words that could be interpreted in multiple ways?

    3. **Inconsistency**: Do any two rules clash in a specific scenario?

    4. **Incompleteness**: Are there input combinations (or missing error paths) where the system's behavior is unspecified?

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Are all 3 Contexts mapped and traced? (2) Are Use Cases sliced?

## Step 3: The Fit Check

- [ ] **Apply Shaping**: Propose 1-3 high-level UX/Feature "Shapes" (mechanisms, not code). MANDATORY: To prevent Cognitive Debt, you MUST include a "Dumb Shape" (the absolute simplest flat/procedural solution) alongside any complex patterns. **MANDATORY Guardrail**: Do not select deep technical architectures (e.g., Database types, specific Push protocols) at this stage. Keep shapes strictly focused on Business Logic, UX, and Process flows.

- [ ] **Anti-Flop Stress Test**: For every proposed Shape, explicitly state how it handles:

  - (1) **Scale over time** (e.g., what happens when there are 100 items instead of 5?).

  - (2) **Role Isolation** (e.g., does this pollute the UI of users who don't need it?).

  - (3) **Empty/Error States** (e.g., what does it look like on Day 1 with 0 items? What if an item is deleted?).

  - (4) **Offline Viability** (e.g., does this require a live connection, or can it be cached for offline use?).

- [ ] **Fit Matrix**: Create a Markdown table comparing the proposed Shapes against the Requirements.

- [ ] **Identify Unknowns**: Flag any unresolved business logic with ⚠️.

## Step 4: Deliverable Generation

- [ ] **Artifact Gen**: Use `write_to_file` to save `requirements_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` to the `docs/product/[topic]/` directory.

- [ ] **Payload Schema**:

    1. `## Input Lineage`: Absolute path to the original request or idea document.

    2. `[ORIGIN_IDEA]` or `[ADR_REFERENCE]`.

    3. **Functional Context**: Defined Actors, RBAC, and Use Case Narrative.

    4. **Visual Context**: UI Flow mapping and Wireframes.

    5. **Data Context**: Rough schema and mock data.

    6. Use-Case Slices and their associated Test Cases (Acceptance Criteria).

    7. Selected Shape & Fit Check.

    8. **Handoff Block**: Brief for the next Agent, and the next command.

- [ ] **Workspace Copy**: Copy the artifact to `.agents/tmp/research/` so the user can review it.

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
