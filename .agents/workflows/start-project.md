---

description: Guided workflow to initialize a brand new project, pick a tech stack, and define MVP scope.

---

# Workflow: /start-project

> [!NOTE]

> Run this workflow on Day 1 when you have a general idea but haven't written any code or picked a framework. This guides you through ecosystem selection, scope shaping, and project scaffolding.

## Step 1: The Interrogation (Stack Selection)

| Step | Execution Contract |

|---|---|

| **Skill Load** | MANDATORY: Load `.agents/skills/ecosystem-advisor/SKILL.md`. |

| **Interrogation** | Ask the user the 6 strict business priority questions (Budget, Audience, Maintenance, Scale, Laws, Team Skill). Do NOT proceed until answered. |

| **Pattern Recognition**| MANDATORY: Before recommending any tools, explicitly label the System Design Pattern (e.g., Ledger, State Machine, Pub/Sub, Feed). The pattern dictates the required tools. |

| **Selection** | Output the recommended Tech Stack (Frontend, Backend, DB, Infra) along with Tradeoffs and Risks. **Rule:** When listing trade-offs or pros/cons, you MUST include a short and concise example of the **Best Context (When to use)** and **Worst Context (When to avoid)**. |

| **Approval** | Yield to the user. Do they accept this stack, or want to pivot? |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Were all 6 questions answered? (2) Is the Stack explicitly agreed upon?

## Step 2: Project Shaping (Scope Lockdown)

| Step | Execution Contract |

|---|---|

| **Skill Load** | MANDATORY: Load `.agents/skills/shaping/SKILL.md`. |

| **Appetite** | Ask the user for their strict time-constraint (e.g., 6 weeks). |

| **Boundaries** | Discuss what the MVP *is* and explicitly what it *is not* (No-Gos). Cut features aggressively to fit the appetite constraint. |

| **Approval** | Yield to the user to confirm the final MVP boundary. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Is the MVP boundary strictly defined? (2) Are No-Go features explicitly documented?

## Step 3: The Charter

| Step | Execution Contract |

|---|---|

| **Documentation**| Create `project_charter.md` to permanently capture the foundation. |

| **Domain Glossary**| MANDATORY: Establish a "Ubiquitous Language" defining strict names for core entities (e.g., "Auditor" vs "User") to prevent future AI hallucination. |

| **Charter Content**| Must include: `1. Exec Summary`, `2. The Stack`, `3. Domain Glossary`, `4. Feature In-Scope`, `5. Feature Out-of-Scope (No-Gos)`. |

## Step 4: Scaffolding & Governance

> [!CAUTION]

> **[SYSTEM_GUARD: Anti-Terminal-Bloat]**: DO NOT automatically run `dotnet new`, `flutter create`, or heavy CLI generators on behalf of the user. Terminal hangs will break the session.

| Step | Execution Contract |

|---|---|

| **Instructions** | Provide the exact copy-paste terminal commands needed to build the base folders for the chosen stack (e.g., `npx create-next-app`, `flutter create`, etc). |

| **Execution** | MANDATORY: Prompt the user: *"Please run these commands in your IDE terminal. Reply 'Done' when the folders exist."* |

| **The Constitution**| Ask the user: *"What are the strict Don'ts or specific quirks for this project?"* Generate a local `GEMINI.md` file in the project root to prevent Context Rot. |

| **Yield** | YIELD execution until user confirms scaffolding is complete. |

## Step 5: Handoff & Routing

| Step | Execution Contract |

|---|---|

| **Routing** | Output message: *"Project Inception Complete. Now that the raw folders exist and the Charter is locked, run `/analyze-epic` so I can physically map out the database patterns and folder structures before we start coding."* |

### Script Verification Gate

> **Script Verification Gate (MANDATORY)**:

> You MUST use the `run_command` tool to execute this script before considering the task complete.

> // turbo

> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

> - `Code 0`: *"Handoff complete."*

> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
