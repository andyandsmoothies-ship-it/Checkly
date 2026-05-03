---
description: Easy-to-read analysis workflow for large features and epics.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /analyze-epic

> [!NOTE]
> Use this workflow for large, complex features (Epics). Use it when the task has unknown rules, new complex states, or needs more than 1 new database table. It helps you review risks and break the work into smaller slices.

> [!CAUTION]
> **No Exact Code:** Do not generate exact code, SQL schemas, or line-by-line diffs here. Keep the plan high-level (Architecture Flow, APIs, Risks, and Slices). Leave the exact code for the Builder workflow.

## Phase 0: Start

| Step | Instructions |
|---|---|
| **Check Rules** | If `.agents/rules/governance-rules.md` is not in memory, view it first. |
| **Task Tracking** | Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` using the template below before doing anything else. List only the Epic Plan in the Artifact Inventory. |

```markdown
# Task: [Epic Name]
Workflow: /analyze-epic | Track: C

## Input Lineage
- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Phases
- [ ] Phase 1: Discover & Plan
- [ ] Phase 2: Review Risks
- [ ] Phase 3: Create Plan
- [ ] Phase 4: Break Down Work
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/architecture/analysis_epic_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md | Epic Plan |
```

## Phase 1: Discover & Plan

| Step | Instructions |
|---|---|
| **Interrogation Gate**| **MANDATORY**: Before writing a plan, cross-reference the user's request against the codebase. If terminology is sloppy or contradicts existing code, **STOP** and ask the user to clarify. |
| **Check the Goal** | Before proposing a technical plan, ask: Does this actually solve the user's original problem? If the plan is too complex and forgets the main goal, stop and fix it. |
| **Check Ideas** | If the user provides a document or idea, check if it works with the current code. Check if it breaks Clean Architecture or causes bad side effects. Reject impossible or dangerous ideas. |
| **Load Skills & Shaping** | Load the `shaping` skill and architecture skills (like `clean-architecture`). Use the Fit Check matrix from the shaping skill to map requirements against possible shapes (options) before committing to a plan. |
| **Traceability Check** | MANDATORY: Does every backend/API capability have a frontend UI mapped to it? (Visual Context). Do not propose APIs without UIs. |
| **System & Lifecycle Context** | Explicitly list constraints (e.g., offline-first, sync logic, RBAC) and edge states (Empty/Error). Ensure all proposed options optimize for them. |
| **Build vs Buy** | Search the code to see if you can reuse existing components instead of building new ones. |
| **Core vs Leaf** | Clearly list which parts are Core (needs strong design) and which are Leaf (can be simple, repetitive code). |
| **Keep It Simple**| If you suggest a complex design (like a Factory or EventBus), you must explain why a simple flat structure or basic function would not work. |
| **Backend Only?** | Check if this is a "Backend-Only" task (like a background job). If yes, skip the UI and Frontend API steps. |
| **Find Connections**| Before proposing changes, use `grep_search` to find exact names across the project. Map out the Database, Dependency Injection, and APIs. |
| **Demand Options**| You MUST generate at least 2 distinct architectural options (Shapes) in the Decision Matrix. For each choice, write the Pros, Cons, and Impacts. Vigorously defend why your final choice is the best. |
| **Assess Risks** | Write down the technical and operational risks for each choice, and explain how to fix or avoid them. |
| **Set Limits** | Define limits for Performance, Security, and Logging before you start. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Did you check the main goal? (2) Did you search for connections? (3) Did you compare at least 2 options? (4) Are limits defined?

## Phase 2: Review Risks

| Step | Instructions |
|---|---|
| **Swap Skills** | Load `dotnet-resilience` or concurrency skills to help review risks. |
| **Review Personas**| Review your plan from 3 points of view: 1) DB Architect, 2) Security Auditor, 3) Junior Dev (maintenance). Score each out of 10. If any score is under 7, the plan fails. |
| **Check Rules** | Check your proposed architecture against the project's strict rules. If a rule makes your plan impossible, fix the plan before finishing. |
| **Fix Flaws** | Create solutions for every low score or risk, or reject the plan completely. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Did you review the plan from 3 points of view? (2) Are solutions clear? (3) Does the plan follow all rules?

## Phase 3: Create Plan

| Step | Instructions |
|---|---|
| **Write the Plan** | Use `write_to_file` to save `analysis_epic_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` to the `docs/architecture/` folder. Do not print the whole plan in the chat. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. Does the document have all required sections?

## Phase 4: Break Down Work

> [!CAUTION]
> **Too Big:** Do not send an Epic directly to `/implement`. You must break it into smaller slices first.

| Step | Instructions |
|---|---|
| **Slice Work** | Load the `use-case-slicing` skill. Break the Epic into smaller slices (like UI to Database). If it is Backend-Only, slice by technical steps. Add these slices to the end of your Epic Plan. |
| **Plan Routes** | Create a list of routes for each slice (e.g., `Slice N | Track A/B | Route Path`). |

### Routing Guide
Send each slice to the right workflow:
- **Visuals/Simple UI:** Route to -> `[/analyze-feature]` -> `[/implement]`
- **Logic/State/API:** Route to -> `[/analyze-feature]` -> `[/tdd]` -> `[/implement]`

- **Order of Work**: For each slice, explain when it should run:
    - `[BLOCKING]`: Must run FIRST and ALONE (other slices need it).
    - `[PARALLEL]`: Can run at the same time as other slices to save time.
    - `[SEQUENTIAL]`: Must run strictly after a specific slice.

### Final Output Rules
> [!IMPORTANT]
<output_schema>
> **File Format:** Your `analysis_epic_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` MUST have these exact sections. Keep it short and simple.
> 1. `<latent_space_scratchpad>`: Your hidden thoughts and tradeoffs.
> 2. `## Input Lineage`: Absolute path to the original requirements document or idea.
> 3. `## Executive Summary`
> 3. `## Decision Matrix`
> 4. `## Risk Assessment`
> 5. `## Visual & Functional Context`: (Mapped UI Screens and Use Cases)
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
> 2. List of Slices and when they run. (If there is only 1 phase, do not name it "Slice 1").
> 3. **Next Steps**: A 1-2 sentence summary for the next agent.
> 4. Exact next workflow command using the `{Absolute_Path}`.
>
> **Update .agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md**: Change `[/]` to `[x]` and add absolute file paths.
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
