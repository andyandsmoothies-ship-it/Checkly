---
description: Easy-to-read analysis workflow for standard features and bugs.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /analyze-feature

> [!NOTE]
> Use this workflow to plan small to medium tasks. The goal is to quickly and safely create an Implementation Plan.

## Phase 0: Start

| Step | Instructions |
|---|---|
| **Task Tracking** | Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` using the template below before doing anything else. List only the implementation plan in the Artifact Inventory. |
| **Check Epic Rules** | If this task is part of a larger Epic, read the Epic's plan first. Your job is to create exact database schemas, file paths, and code changes that match the Epic, without changing the main rules. |

```markdown
# Task: [Feature / Bug / Topic Name]
Workflow: /analyze-feature | Track: [A / B1 / B2]

## Input Lineage
- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

## Phases
- [ ] Phase 1: Search & Understand
- [ ] Phase 2: Check Impacts & States
- [ ] Phase 3: Create Plan
- [ ] Phase 4: Pick Next Route
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/architecture/implementation_plan_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md | Plan |
```

## Phase 1: Search & Understand

| Step | Instructions |
|---|---|
| **Interrogation Gate**| **MANDATORY**: Before writing a plan, cross-reference the user's request against the codebase. If terminology is sloppy or contradicts existing code, **STOP** and ask the user to clarify. |
| **Search First** | Always use `grep_search` to find the exact line numbers needed, then use `view_file` to read only those specific chunks. Do not read full files blindly to save memory. |
| **Check Setup** | Read config files (like `.csproj` or `pubspec.yaml`) to understand the project setup. |
| **Learn the Code** | Search the current code to learn how it works before you start planning. |
| **Check Ideas** | If the user provides an idea or document, check if it works by searching the code. Do not use ideas that do not fit the current code. |
| **Out of Scope (YAGNI)**| Write down what you will NOT build. If a step breaks a main rule, stop and ask the user. Do not silently skip it. |
| **Spot Check**| Search the code to double-check at least one main idea in your plan before finishing. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Do you know the main goal? (2) Did you write down what is out of scope? (3) Did you double-check the code?

## Phase 2: Check Impacts & States

| Step | Instructions |
|---|---|
| **Risk & ROI Evaluation** | **MANDATORY**: Evaluate if the proposed change is worth the architectural cost. If the blast radius is high, it introduces tech debt, or the ROI is negative, **do not stop**, but you MUST include a prominent **Risk Warning** at the top of your implementation plan and in your chat response so the user understands the current situation and tradeoffs. |
| **Find Connections** | Before changing any class or API, use `grep_search` to find it everywhere in the project (`/server` and `/lib`). Check 6 areas: 1) UI, 2) Routes, 3) Database, 4) Mocks, 5) Events, 6) Dependency Injection. |
| **Impact Check** | Do not change existing tests or mocks just to make your new code pass. Make your code fit the current rules. If you change a database or API, make sure you update both the backend and frontend. |
| **Trust the Source** | Do not trust UI state alone. If your plan depends on a status (like `if status == 'x'`), search the database or API to prove it can actually send that status. |
| **File Size Limit** | If the file you want to edit has more than 250 lines, your plan must include a step to split the file before adding new features. |
| **System Context** | Define environmental constraints: Is this offline-first, live API, or hybrid? What exact RBAC permissions gate this feature? |
| **Lifecycle Context** | Define the 4-State Matrix: How does the UI look in `Loading`, `Empty`, `Error`, and `Success` situations? |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Is the Risk/ROI acceptable? (2) Did you search everywhere for connections? (3) Did you map both backend and frontend? (4) Are System and Lifecycle Contexts defined?

## Phase 3: Create Plan

| Step | Instructions |
|---|---|
| **Acceptance Criteria** | You must write clear Acceptance Criteria. Your plan must include a Test Contract matrix. **CRITICAL:** ALL boundary constraints and edge cases MUST be explicit rows in the matrix, not loose bullet points. If applicable, define exact JSON Request/Response payloads and explicitly list the Required Test Fixture State (e.g., 'Requires Admin Client, 3 Seeded Stores'). |
| **Tools Needed** | Write down which skills the Builder will need. Write down the commands to test the code (like `flutter test` or `dotnet test`). |
| **Slicing Strategy** | **MANDATORY**: You MUST load and apply the `use-case-slicing` skill. Use the 'Maximum Thickness' exception to split heavy slices horizontally. Every slice must define an 'Entry State Required' and 'Exit State Guaranteed'. Output slices as 'Micro-Specs'. |
| **Write the Plan** | Use `write_to_file` to create `implementation_plan_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` in the `docs/architecture/` folder. Do not print the whole plan in the chat. Make it easy for a human to read. |
| **Clear Goals** | The plan must have clear steps (like 'Write X test -> Check it fails -> Write Y code -> Check it passes'). |

## Phase 4: Pick Next Route

> [!CAUTION]
> **Too Big?** If the task has unknown rules, new complex states, or needs more than 1 new database table, STOP. Tell the user to use `/analyze-epic` instead.
> **Logic Bypass?** If a slice creates or modifies Business Logic (e.g., Managers, Services, state math), You MUST route to `/tdd` first.

| Signal Check | Route 2: Direct Build (`/implement`) | Route 1: Logic/Standard (`/tdd`) | Route 3: Integration/High-Risk (`/atdd`) |
|---|---|---|---|
| **Type** | UI-Only (No network/auth) | Internal Logic / Data Math | Uses Network/Auth/Database |
| **Clarity** | Very clear | Needs math or algorithms | Unclear or tricky |
| **Pattern** | Uses existing pattern | Known code pattern | New pattern |
| **Testing Risk**| Low (Visual changes) | Medium (Needs Unit Tests) | High (Needs Integration Tests) |

## 🚦 Handoff

> [!IMPORTANT]
> **Action:** Print the exact routing commands below for the user. Match each step to its correct route.
> 
> **Step-by-Step Rule:** Tell the user to run these commands **ONE AT A TIME**. Do not run them all at once.
>
> **Route 1: Logic/Standard (Unit Tests First)**
> @[/tdd] Execute tests for [Slice N / The Feature]: {Absolute_Path_to_plan}
>
> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for [Slice N / The Feature]: {Absolute_Path_to_plan}
>
> **Route 3: Network/Auth/DB (Acceptance Tests First)**
> @[/atdd] Execute specs for [Slice N / The Feature]: {Absolute_Path_to_plan}
>
> **Concurrency:** State which slices must wait for others to finish.

### Final Output Rules
> [!IMPORTANT]
<output_schema>
> **File Format:** Your `implementation_plan_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` MUST have these exact sections. Keep it short and simple.
> - `<latent_space_scratchpad>`: Your hidden thoughts about edge cases.
> - `## Input Lineage`: Absolute path of the source Epic Plan, Bug Report, or idea document.
> - `## Executive Summary & Out of Scope`
> - `## System Context` (Offline/Online, APIs, RBAC, Logs)
> - `## Lifecycle Context` (4-State Matrix: Success, Error, Empty, Loading)
> - `## Test Contracts` (ID, Exact Text, State Matrix, Why it fails first). **CRITICAL:** Every boundary constraint MUST be an explicit row.
> - `## Test Fixture & Payloads` (Explicit setup requirements like "Seeded Admin" and raw JSON Request/Response examples for API slices).
> - `## Tools & Commands` (Skills and test commands)
> - `## Proposed Changes`: List `[NEW]/[MOD]/[DEL]` files.
> - `## Concept Diagram`: A simple text flowchart (like `[User] --> [Click] --> [Save]`) to explain the idea.
> - `## Execution Slices` (Micro-Specs): Group the work using the `use-case-slicing` skill methodology. **CRITICAL:** Apply the 'Maximum Thickness' rule. To prevent AI context overflow, if a plan spans both backend APIs and new frontend UI, YOU MUST split it horizontally (e.g., `Phase A: Backend API`, `Phase B: Frontend UI`). Keep the blast radius under 200 lines per phase. For each slice, you MUST output the Micro-Spec format (Plain English Summary, Value Delivered, Entry/Exit State, Scope, Acceptance Criteria). Explain the plan but **DO NOT write exact code**.<br><br>For each phase, rate the **Complexity** (Low/Medium/High) with a reason.<br><br>For each major choice, write the **Pros & Cons**. Ask the user to decide before starting to code. **If there is only 1 phase, call it "Execution Phase", NOT "Slice 1".**
> - `<command_logs>`: A list of terminal commands you ran.
> - `## Handoff Block`: A short summary for the next AI agent. You MUST include the exact `@[/...]` routing command (like `@[/tdd]`) for EVERY step, with the absolute file path.
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