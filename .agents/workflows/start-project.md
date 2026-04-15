---
description: Guided workflow to initialize a brand new project, pick a tech stack, and define MVP scope.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /start-project

> [!NOTE]
> Run this workflow on Day 1 when you have a general idea but haven't written any code or picked a framework. This guides you through ecosystem selection, scope shaping, and project scaffolding.

## Phase 1: The Interrogation (Stack Selection)

| Step | Execution Contract |
|---|---|
| **Skill Load** | MANDATORY: Load `.agents/skills/ecosystem-advisor/SKILL.md`. |
| **Interrogation** | Ask the user the 6 strict business priority questions (Budget, Audience, Maintenance, Scale, Laws, Team Skill). Do NOT proceed until answered. |
| **Selection** | Output the recommended Tech Stack (Frontend, Backend, DB, Infra) along with Tradeoffs and Risks. |
| **Approval** | Yield to the user. Do they accept this stack, or want to pivot? |

> **@@SCAN**: (1) Were all 6 questions answered? (2) Is the Stack explicitly agreed upon?

## Phase 2: Project Shaping (Scope Lockdown)

| Step | Execution Contract |
|---|---|
| **Skill Load** | MANDATORY: Load `.agents/skills/shaping/SKILL.md`. |
| **Appetite** | Ask the user for their strict time-constraint (e.g., 6 weeks). |
| **Boundaries** | Discuss what the MVP *is* and explicitly what it *is not* (No-Gos). Cut features aggressively to fit the appetite constraint. |
| **Approval** | Yield to the user to confirm the final MVP boundary. |

> **@@SCAN**: (1) Is the MVP boundary strictly defined? (2) Are No-Go features explicitly documented?

## Phase 3: The Charter

| Step | Execution Contract |
|---|---|
| **Documentation**| Create `project_charter.md` to permanently capture the foundation. |
| **Charter Content**| Must include: `1. Exec Summary`, `2. The Stack`, `3. Feature In-Scope`, `4. Feature Out-of-Scope (No-Gos)`, `5. Target Audience & Constraints`. |

## Phase 4: Scaffolding

> [!CAUTION]
> **[SYSTEM_GUARD: Anti-Terminal-Bloat]**: DO NOT automatically run `dotnet new`, `flutter create`, or heavy CLI generators on behalf of the user. Terminal hangs will break the session.

| Step | Execution Contract |
|---|---|
| **Instructions** | Provide the exact copy-paste terminal commands needed to build the base folders for the chosen stack (e.g., `npx create-next-app`, `flutter create`, etc). |
| **Execution** | MANDATORY: Prompt the user: *"Please run these commands in your IDE terminal. Reply 'Done' when the folders exist."* |
| **Yield** | YIELD execution until user confirms scaffolding is complete. |

## Phase 5: Handoff & Routing

| Step | Execution Contract |
|---|---|
| **Routing** | Output message: *"Project Inception Complete. Now that the raw folders exist and the Charter is locked, run `/analyze-epic` so I can physically map out the database patterns and folder structures before we start coding."* |

### Script Verification Gate
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
