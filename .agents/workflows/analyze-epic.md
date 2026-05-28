---

description: Easy-to-read analysis workflow for large features and epics.

---

# Workflow: /analyze-epic

> [!NOTE]

> Use this workflow for large, complex features (Epics). Use it when the task has unknown rules, new complex states, or needs more than 1 new database table. It helps you review risks and break the work into smaller slices.

> [!CAUTION]

> **No Exact Code:** Do not generate exact code, SQL schemas, or line-by-line diffs here. Keep the plan high-level (Architecture Flow, APIs, Risks, and Slices).

## Step 1: Start

- **Task Tracking**: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md` before doing anything else. List only the Epic Plan in the Artifact Inventory.

```markdown

# Task: [Epic Name]

Workflow: /analyze-epic | Track: C

## Input Lineage

- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Steps

- [ ] Step 2: Discover & Plan

- [ ] Step 3: Review Risks

- [ ] Step 4: Create Plan

- [ ] Step 5: Break Down Work

## Artifact Inventory

| Status | File Path | Type |

| [NEW]  | docs/architecture/[topic]/analysis_epic_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md | Epic Plan |

```

## Step 2: Discover & Plan

- **Interrogation Gate**: MANDATORY: Before writing a plan, cross-reference request against codebase. If terminology is sloppy or contradicts code, STOP and ask user to clarify.

- **Check the Goal**: Ensure the technical plan directly solves the user's original problem. If too complex, stop and simplify.

- **Label the Pattern**: Explicitly label the System Design Pattern (e.g. Ledger, State Machine, Pub/Sub, News Feed) before designing to sharpen tradeoffs.

- **Check Ideas**: Verify if the proposed idea aligns with current code and clean architecture. Reject impossible or dangerous ideas.

- **Load Skills & Shaping**: Load `shaping` and `clean-architecture` skills. Use the Fit Check matrix to map requirements against options before committing.

- **Traceability Check**: MANDATORY: Ensure every backend/API capability has a corresponding UI screen. Do not propose APIs without UIs.

- **System & Lifecycle Context**: Define constraints (offline-first, sync, RBAC) and edge states (Empty/Error) to optimize options.

- **Build vs Buy**: Scan code to reuse existing components instead of building new ones.

- **Core vs Leaf**: Clearly distinguish Core components (needs strong design) from Leaf components (simple, repetitive).

- **Keep It Simple**: Defend complex designs (Factory/EventBus) and explain why a simple flat structure or function would fail.

- **Backend Only?**: If this is a backend-only task (e.g. background job), skip UI and Frontend API steps.

- **Find Connections**: Run `grep_search` to map Database, Dependency Injection, and APIs across the project.

- **Demand Options**: Generate at least 2 distinct architectural options (Shapes) in a Decision Matrix with explicit Pros/Cons/Impacts.

- **Assess Risks**: Define technical and operational risks for each option along with mitigation paths.

- **Set Limits**: Define strict Performance, Security, and Logging limits upfront.

- **@@SCAN**: Print checklist in response: (1) Goal verified? (2) Connections found? (3) 2 options compared? (4) Limits defined?

## Step 3: Review Risks

- **Resilience Skills**: Load `dotnet-resilience` or concurrency skills to review risks.

- **Review Personas**: Grade the plan from 3 points of view (DB Architect, Security Auditor, Junior Dev) out of 10. If any score < 7, the plan fails.

- **Check Rules**: Verify architecture complies with strict project rules. Fix plan if it violates any rules.

- **Fix Flaws**: Mitigate low scores/risks or reject the plan entirely.

- **@@SCAN**: Print checklist in response: (1) 3 points of view reviewed? (2) Solutions clear? (3) Strict rules followed?

## Step 4: Create Plan

- **Write the Plan**: Save `analysis_epic_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md` to `docs/architecture/[topic]/`. Do not dump the plan in chat.

- **@@SCAN**: Print checklist in response: Does the document contain all required sections?

## Step 5: Break Down Work

> [!CAUTION]

> **Too Big:** Do not send an Epic directly to be built. You must break it into smaller slices first.

- **Slice Work**: Load `use-case-slicing` skill. Break the Epic into thin vertical slices (UI to DB). If backend-only, slice by technical steps. Append to Epic Plan.

- **Plan Routes**: Define a route and track (Track A/B/C) for each slice.

- **Handoff Guide**: Sequence each slice based on its risk:

  - **Visuals/Simple UI**: Plan -> Build

  - **Internal Logic/Algorithms**: Plan -> Write Unit Tests -> Build

  - **Network/Auth/Database**: Plan -> Write Acceptance Tests -> Build

- **Order of Work**: Mark slices as `[BLOCKING]`, `[PARALLEL]`, or `[SEQUENTIAL]`.

- **@@SCAN**: Print checklist in response: Have you classified each slice's risk to set the testing sequence?

### Final Output Rules

> [!IMPORTANT]

<output_schema>

> **File Format:** Your `analysis_epic_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md` MUST have these exact sections. Keep it short and simple.

> 1. `<latent_space_scratchpad>`: Your hidden thoughts and tradeoffs.

> 2. `## Input Lineage`: Absolute path to the original requirements document or idea.

> 3. `## Executive Summary`

> 3. `## Decision Matrix`

> 4. `## Risk Assessment`

> 5. `## Visual & Functional Context`: (Mapped UI Screens, Use Cases, and explicit Truncation/Overflow Routing tables for lists)

> 6. `## System Context`: (Offline/Online, RBAC, API Contracts)

> 7. `## Lifecycle Context`: (Edge cases, Error states, Rollback Plan)

> 8. `## Data Context`: (Database Migrations, Schema)

> 9. `## Architecture Flow`: (Clear text summary of how data moves)

> 10. `## Risk Review & Security`

> 11. `## Logs & Audits`

> 13. `## Testing Expectations`

> 14. `<command_logs>`: A list of terminal commands you ran.

>

> **Handoff Block:** Add `## Handoff Block` at the end containing:

> 1. Final Epic decision and file path.

> 2. List of Slices and when they run. (If there is only 1 step, do not name it "Slice 1").

> 3. **Next Steps**: A short summary for the next agent.

> 4. **Handoff Roadmap**: You MUST explicitly state the Risk Classification (Visuals, Internal Logic, or Network/Database) for **EVERY slice**, and then provide the matching sequence of actions. Example: `- **Slice 1**: [Risk: Network/Database] Plan -> Write Acceptance Tests -> Build` or `- **Slice 2**: [Risk: Visuals] Plan -> Build`. Do not use project-specific workflow names (like `/tdd` or `/implement`), just generic actions. Tell the user to execute them ONE AT A TIME. Include the absolute file path to the epic plan.

>

> **Update .agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md**: Change `[/]` to `[x]` and add absolute file paths.

>

> **Script Verification (Required)**:

> Use the `run_command` tool to run this script before finishing.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Handoff complete."*

> - `Code 1`: Fix errors and try again.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>

</output_schema>
