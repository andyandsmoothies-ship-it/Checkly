---
name: Analysis Workflow
description: Precision Analysis Workflow for System Architecture.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analysis

## Step 0: Context Initialization (CRITICAL FAIL-SAFE)
> [!IMPORTANT]
> Before you draft any plans, you MUST verify you fully understand the global governance rules.
> **Rule**: If you do not currently have the exact contents of `.agents/rules/governance-rules.md` in your active memory, you MUST use the `view_file` tool to read it right now. Do not proceed to Phase 1 until confirming adherence.

> [!NOTE]
> This is the **System & Business Analysis** workflow — used to evaluate solutions, analyze business logic, verify architecture feasibility, and identify edge cases before implementation. It is designed to produce production-grade Software Engineering Tech Specs.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You MUST immediately create a `thinking_log_[topic].md` artifact using `write_to_file` BEFORE starting your analysis. All internal reasoning, hypothesis generation, and rejected ideas must go there. Do NOT pollute structured artifacts with internal monologue.

## Phase 1: Technical Discovery & Reuse Audit
- **Instruction**: Assume the role of a Principal Software Engineer. Your first job is to determine if we should build this at all or if it can be achieved by reusing/configuring existing code.
- **Consume Research (MANDATORY)**: Check if the user provided a `concept_brief_[topic].md` or `research_[topic].md` in the chat context (via a file path, link, or attachment). If one is provided, you MUST read it to consume the E2E Workflow Map before beginning your analysis. Do NOT start from scratch if research exists.
- **Skill Discovery**: Derive 2-3 technical keywords from the feature scope (e.g., "first-principles", "think from scratch"). Use `grep_search` on `.agents/skills/` to find matches. Load ONLY the top 1-2 most relevant `SKILL.md` files. Declare which skills were loaded.
- **Reuse vs. Build (CRITICAL)**: Use `grep_search` and `codebase_search` to determine if the requirement can be met by configuring or deleting existing components. If it can, skip to Phase 4 and recommend reuse/refactoring.

> **@@SCAN** Before proceeding, answer: (1) Which skills did you load and why? (2) Can this requirement be met by reusing existing code? (3) What are the 2-3 core entities/tables this feature touches?

## Phase 2: Feasibility & System Impact Audit
- **Instruction**: Evaluate the business logic and system impact against all workspace rules in `.agents/rules/`.
- **System Impact Audit**: You MUST actively search for cross-feature conflicts. **Action**: Identify the core database tables, shared services, or global states this new feature touches. **You must use file-search tools (`grep_search`, `codebase_search`) to find all existing usages of those components in the workspace.** Only after reading the existing usages can you answer: "What existing feature will break if we implement this?"
- **Action**: Identify logical flaws, unhandled edge cases, security risks, side-effects, and deviations from established project standards. Do not just look at code; physically execute analysis tools to verify the *entire system behavior*.

> **@@SCAN** Before proceeding, answer: (1) What existing features could break? (2) Which workspace rules from `.agents/rules/` constrain this feature? (3) Did you use file-search tools to find ALL existing usages of the affected components?

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to a "Red Team Adversary" persona. Your goal is to destroy the proposed implementation plan before it is coded. Be aware of the "Expert Witness Trap" — AI models will pass flawed logic unless explicitly asked about scaling extremes.
- **Skill Refresh**: The concern has shifted to failure modes. Re-scan `.agents/skills/` for skills related to error handling, concurrency, or debugging patterns. Load 1-2 if relevant.
- [ ] **Hostile Interrogation**: Trigger the `hostile-interrogation` skill to evaluate the design against domain scale extremes. Do not proceed until the 3 failure questions are answered.
- [ ] **Resolution**: Refine the solution to mitigate the identified failures. If the failures cannot be mitigated, reject the feature and request a redesign.

> **@@SCAN** Before proceeding, answer: (1) Did you run the hostile-interrogation skill? (2) What are the 3 failure scenarios you identified? (3) Were any failures unmitigable?

## Phase 4: The Deliverable (Production-Grade Architecture Document)
- **Requirement**: You MUST create a rigorous, structured `analysis_[topic].md` artifact. This is NOT a code diff; it is a Software Engineering Design Document.
- **The artifact MUST include the following mandatory sections**:
  1. **Executive Summary & Goals**: What are we building and why?
  2. **System Architecture & Data Flow**: Clear description of how the system will interact across the UI, Backend (API), and Database. Use a Mermaid diagram if complex.
  3. **Database & Schema Changes**: (If applicable) Table modifications, migrations, and index strategies.
  4. **API Contracts**: (If applicable) Request/Response payloads and endpoint designs.
  5. **System Impact & Blast Radius**: Explicit list of existing features/components that could break and how they are protected.
  6. **Adversarial Review & Edge Cases**: The 3 Red Team failures and their mitigations. Error handling strategies (offline, timeouts, invalid data).
  7. **Security & Permissions**: RLS, Auth, or authorization checks required.
  8. **Behavioral Expectations (EDD)**: You MUST generate 3-5 clear, plain-text expectations for the feature. Write them not as code, but as behavioral rules (e.g., "If the cart is empty, return 0, not an error"). Incorporate the "Hostile Expectations" generated by the Red Team in Phase 3 (e.g., concurrency, rate limits, corrupt state). The human will review and approve these expectations before implementation.
  9. **Complexity Assessment**: State whether this task is Small (single concern), Medium (multiple concerns), or Large (crosses all layers). This drives Track classification in Phase 5.

> **@@SCAN** Before proceeding, answer: (1) Does your artifact include ALL 9 mandatory sections? List any you skipped and why. (2) What is the complexity assessment (Small/Medium/Large)?

## Phase 5: Task Routing & Handoff
- **Action**: Read the `analysis_[topic].md` produced in Phase 4. Based on its findings (blast radius, complexity, layer count), categorize the task into one of the tracks below.

  - **Track A — Small Tasks (Single concern, low blast radius)**:
    Generate a single `implementation_plan_[topic].md`. To cross the Builder's quality gate seamlessly, it MUST contain: Executive Summary, Proposed Changes (grouped by file with [NEW]/[MODIFY]/[DELETE]), Database/Schema Changes (or N/A), Concurrency/Idempotency Strategy (or N/A), System Impact & Blast Radius (or N/A), and Verification Plan.
    **Handoff**: `/implement` → (optionally) `/verify`.

  - **Track B — Medium Tasks (Multiple concerns, moderate blast radius)**:
    Generate a single `implementation_plan_[topic].md`. It MUST contain: Executive Summary, Proposed Changes (grouped by file with [NEW]/[MODIFY]/[DELETE]), Database/Schema Changes, API Contracts, Concurrency/Idempotency Strategy, System Impact & Blast Radius, Behavioral Expectations (EDD), and Verification Plan with explicit scenarios.

    Then apply the **ATDD Decision Gate** to determine the pipeline:

    | Signal | Skip ATDD (B1) | Require ATDD (B2) |
    |--------|----------------|---------------------|
    | Correctness | Obvious from the spec | Ambiguous — multiple valid interpretations |
    | Pattern | Extends existing, well-understood pattern | New pattern or algorithm |
    | State | Simple flag/branch | Complex state machine or multi-step transitions |
    | Edge cases | Few, easily enumerated in verification table | Many, easy to miss without formal test writing |
    | Risk | Low — failure is visible and recoverable | High — silent corruption or data loss |

    **B1 Handoff**: `/implement` → `/verify`.
    **B2 Handoff**: `/atdd` → `/implement` → `/verify`.

  - **Track C — Large Tasks (Crosses all layers, high complexity, new epic)**:
    This track requires vertical slicing FIRST, then per-slice classification.
    1. **Step 1 — Slice**: Search `.agents/skills/` for the `use-case-slicing` skill and invoke it. List the slices in the `analysis_[topic].md` artifact.
    2. **Step 2 — Per-Slice Classification**: For EACH slice, classify it as **Track A**, **Track B1**, or **Track B2** using the same decision gate above. Generate the appropriate artifact for each:
       - **Track A slices** → `implementation_plan_[slice].md` → `/implement`
       - **Track B1 slices** → `implementation_plan_[slice].md` → `/implement` → `/verify`
       - **Track B2 slices** → `implementation_plan_[slice].md` → `/atdd` → `/implement` → `/verify`
    3. **Handoff**: Present the slice list with each slice's track. Execute in dependency order.

---

## Final Phase: Self-Correction Gate (CRITICAL)
<strict-instruction>
Before concluding this workflow and replying to the user, you MUST self-audit your output against the global rules of this specific project. You are required to literally type out the following checklist in your final message:

1. **Thinking Process Check**: Did I isolate my internal reasoning into a dedicated thinking log file as dictated by this project's artifact rules? (Yes/No)
2. **Template Check**: Did I include the mandatory header sections (e.g., `# Requirement Summary`) required by this project? (Yes/No)
3. **Tracking Update**: Did I update the primary task tracking document with an inventory of my generated artifacts? (Yes/No)
4. **Integrity Audit**: Did I include the mandatory attribution/compliance block in my final response? (Yes/No)

You are strictly FORBIDDEN from handing off this task to the user until you have achieved 'Yes' on all 4 checks. If any answer is 'No', use your file tools to correct the mistake immediately.
</strict-instruction>