---

description: Concise, high-density analysis workflow for standard features and bugs.

---

# Workflow: /analyze-feature

> Use to quickly and safely plan small to medium features and bug fixes.

## Step 1: Start & Task Tracking

- **Task Tracking**: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` before coding:

  ```markdown

  # Task: [Name] | Workflow: /analyze-feature | Track: [A/B1/B2]

  - **Source Input**: [Path]

  - [ ] Step 2: Search & Scope | [ ] Step 3: Impacts & States | [ ] Step 4: Plan | [ ] Step 5: Route

  - **Artifact Inventory**: docs/architecture/[topic]/implementation_plan_[ShortID]_[topic]_[ConversationID].md

  ```

- **Epic Rules**: If task is part of an Epic, match DB schemas and file paths without changing main rules.

## Step 2: Search & Understand

- **Interrogation Gate**: MANDATORY. Cross-reference request against codebase. If sloppy or contradictory, STOP and ask user.

- **Constraint Extraction**: MANDATORY. Read input lineage for rules/decisions. Save constraints in latent scratchpad.

- **Search First**: Use `grep_search` to find exact lines, then `view_file` to read specific chunks. Do not read full files.

- **Check Setup**: Check project configuration files (e.g., config, dependencies) to understand environmental limits.

- **Learn Code**: Study existing patterns and classes before planning the solution.

- **Label Pattern**: Label the architecture pattern (e.g., State Machine, Caching, Event-Driven, Queue).

- **Check Ideas**: Test all user ideas or docs against code patterns first. Reject incompatible concepts.

- **Out of Scope (YAGNI)**: Explicitly identify and write down what you will NOT build.

- **Spot Check**: Search codebase to verify at least one core plan concept before writing the plan.

- **Mandatory Scan**: Print checklist in response: (1) Main goal known? (2) Out-of-scope defined? (3) Code verified?

## Step 3: Check Impacts & States

- **Risk & ROI**: Evaluate if change is worth the architectural cost. If blast radius is high or ROI negative, include a prominent "Risk Warning" at the top of the plan and in your chat response.

- **Find Connections**: Search 6 areas: UI, Routes, Database, Mocks, Events, and Dependency Injection to map all dependencies before modifying code.

- **Dual-Stack Impact**: Do not change existing tests or mocks to pass. Adapt code to existing contract. If changing database/API, update both backend and frontend.

- **Trust the Source**: Do not trust UI state alone. Verify the database/API contract actually sends that state or status.

- **File Limit**: If any target file exceeds 250 lines, your plan must include a step to split the file or extract logic first.

- **System Context**: Define constraints (e.g. offline-first, sync logic, RBAC capabilities).

- **Lifecycle Context**: Define the 4-State Matrix: how presentation layer handles Success, Loading, Error, and Empty states.

- **Safety & Stability Checks**: MANDATORY. (1) **DI Safety**: Ensure all newly required services are planned for registration in `locator.dart`. (2) **Layout Safety**: Ensure UI components with infinite width (like `ElevatedButton`) used inside horizontal layouts (like `Row`) are explicitly bounded (e.g., using `Expanded` or `minimumSize`).

- **Mandatory Scan**: Print checklist in response: (1) Is Risk/ROI acceptable? (2) Did you search everywhere for connections? (3) Did you map both backend and frontend? (4) Are System and Lifecycle Contexts defined? (5) Are DI and Layout Safety verified?

## Step 4: Create Plan

- **Constraint Traceability**: Review scratchpad. Map EVERY constraint from the input document to an Acceptance Criteria or Test Contract.

- **Acceptance Criteria & Contract**: Write clear Acceptance Criteria and a Test Contract matrix. All boundary constraints and edge cases must be explicit rows. Define exact JSON Request/Response payloads and the Required Test Fixture State.

- **Tools & Commands**: Specify exact skills the Builder needs and target execution/test commands (e.g. `flutter test`, `dotnet test`).

- **Slicing Strategy**: Apply the **Thin Vertical Slicing Strategy** (highly focused slices of <= 4 files each). Sequence slices vertically: Happy Path first (Slice 1), Edge Cases & Validation (Slice 2), then Offline/Visual Resiliency (Slice 3). Each slice must define 'Entry State Required' and 'Exit State Guaranteed'.

- **Write the Plan**: Use `write_to_file` to create `implementation_plan_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` in the `docs/architecture/[topic]/` folder.

- **Mandatory Scan**: Print checklist in response: (1) Did you explicitly extract all constraints from the input document into your scratchpad? (2) Is every constraint mapped to a Test Contract?

## Step 5: Pick Next Route

- **Too Big Warning**: If task has unknown rules, complex states, or > 1 new DB table, STOP and recommend Epic Analysis.

- **Logic Bypass Warning**: If slice creates/modifies Business Logic (e.g. Services, state math), you MUST require tests before coding.

- **Route Selection Strategy**: Match each slice to a Route:

  - **Route 1: Direct Build**: UI-Only, no network/auth, very clear, uses existing pattern, low testing risk.

  - **Route 2: Unit Tests First**: Internal Logic / Data Math, known pattern, medium testing risk.

  - **Route 3: Acceptance Tests First**: Uses Network/Auth/Database, new/complex pattern, high testing risk.

## 🚦 Handoff

- **Handoff Target**: State the exact next Step for the user.

- **Step-by-Step Execution**: Explicitly direct the user to execute steps/slices **ONE AT A TIME**. Do not run them all at once.

- **Route Mapping**:

  - **Route 1 (Direct Build)**: Next Step: **Build Step** for [Slice N]. Input: `{Absolute_Path_to_plan}`

  - **Route 2 (Unit Tests First)**: Next Step: **Write Unit Tests**, then **Build Step** for [Slice N]. Input: `{Absolute_Path_to_plan}`

  - **Route 3 (Acceptance Tests First)**: Next Step: **Write Acceptance Tests**, then **Build Step** for [Slice N]. Input: `{Absolute_Path_to_plan}`

- **Concurrency & Dependency**: Clearly state which slices must wait for others to finish.

### Final Output Rules

<output_schema>

- **File Format**: `implementation_plan_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` in `docs/architecture/[topic]/` must contain:

  - `<latent_space_scratchpad>`: Hidden thoughts on edge cases, limits, and risks.

  - `## Input Lineage`: Absolute path of source requirement/lineage document.

  - `## Executive Summary & Out of Scope`: High-level goal and explicit out-of-scope boundaries.

  - `## System Context`: Offline/online behavior, APIs, RBAC capabilities, and telemetry.

  - `## Lifecycle Context`: 4-State Matrix (Success, Error, Empty, Loading).

  - `## Constraint Traceability`: Table mapping each input constraint to its Test Contract ID.

  - `## Test Contracts`: ID, description, state matrix, and fail-first explanation. Boundary rules must be explicit rows.

  - `## Test Fixture & Payloads`: Setup requirements (e.g. Seeded Admin) and raw JSON Request/Response payloads.

  - `## Tools & Commands`: Necessary skills and execution commands.

  - `## Proposed Changes`: List `[NEW]/[MOD]/[DEL]` files in sequential build order (e.g. Schema -> Logic -> API -> UI). For UI components, include a table mapping: Component -> Truncation Limit -> Overflow Action -> Required New Route.

  - `## Concept Diagram`: Simple text flowchart showing data flow and UI routing transitions.

  - `## Execution Slices` (Micro-Specs): Slice vertically and keep thin.

    - **4-File Rule**: Each slice must create/modify <= 4 files. If > 4 or files > 400 lines, split into smaller sub-slices.

    - **Slice 1 (Happy Path)**: Basic positive flow.

    - **Slice 2 (Edge Cases & Validation)**: Boundary rules, error states, and exceptions.

    - **Slice 3 (Visual Resiliency & UX)**: Caching, offline retry, layout edge cases, visual polish.

    - **Format per Slice**: Micro-Spec (Summary, Value, Entry/Exit State, Scope, Acceptance Criteria). No code. Complexity rating.

  - `<command_logs>`: List of commands run during planning.

  - `## Handoff Block`: Absolute plan path, and generic action sequence per slice (e.g. `- **Slice 1**: Plan -> Write Acceptance Tests -> Build`). Tell user to execute them ONE AT A TIME.

- **Task Tracking Update**: Update `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic]_[ConversationID].md` (change `[ ]` to `[x]`, append absolute file paths).

- **Script Verification**: Run verification script using `run_command` tool before concluding:

  `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to task tracker}"`

  - Code 0: Handoff complete.

  - Code 1: Fix errors and retry.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
