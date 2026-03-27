---
name: Thinking & Logic Audit Workflow
description: Systematic evaluation of AI reasoning logs (thinking, planning, and diagnostics) to ensure architectural compliance, YAGNI adherence, and logical soundness before code execution.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/project-gotchas.md]

# /audit-thinking Workflow

## Step 0: Target Acquisition
- The user will provide the absolute path to a `.md` reasoning artifact AND state which workflow generated it (e.g., "From the `/implement` workflow"). 
- **Wait for Input**: Do not proceed until the exact log path and parent workflow are supplied.
- Load the core workspace constraints (`project-gotchas.md` and `governance-rules.md`).
- Use `view_file` to explicitly load the `.md` file of the parent workflow (e.g., `.agents/workflows/implement.md`) into your active context so you know what structural outputs the Builder AI was supposed to produce.

## Phase 1: Context Ingestion & Evaluation
- Use `view_file` to read the target logic document from top to bottom.
- Immediately evaluate the document against the **6-Point Quality Rubric**:
  1. **Context Adherence:** Did the Builder AI explicitly reference relevant `project-gotchas.md` rules as constraints for its solution?
  2. **YAGNI Gate (You Aren't Gonna Need It):** Does the proposed solution introduce unnecessary architectural complexity (e.g., global state managers for local state, complex abstractions instead of simple functions)?
  3. **Scientific Method (For Diagnostics):** Does the log jump straight to a fix, or does it follow a `Hypothesis → Evidence → Root Cause` loop? Did it prove its assumptions?
  4. **Blast Radius Awareness:** Did the Builder anticipate what else its changes will break (frontend/backend sync, migrations, test suites)?
  5. **Protocol Compliance:** Did the reasoning log satisfy ALL explicit, mandatory structural requirements defined in its parent workflow (e.g., outputting the `@@SCAN` blocks, building the 4-phase diagnostic layout, generating the decision log)?
  6. **Analytical Depth (First Principles):** Did the Builder identify the true root cause, or did it propose a superficial band-aid (like adding a loading spinner)? Did it weigh the trade-offs of its solution (Performance vs. Complexity), or blindly present "one true way"?

## Phase 2: Grading Structure
- Extract the core logic flaws based on the Rubric.
- Assign an overarching **Grade (A to F)** to the logic quality.
  - **A (Pass - Great)**: Strong First Principles analysis with trade-offs; actively cites rules; avoids YAGNI violations; covers edge cases; pristine Protocol Compliance.
  - **B (Pass - Good)**: Strong logic, but implicitly handles rules without stating them; minor edge case omissions; mostly protocol-compliant.
  - **C (Fail - Rework Required)**: Ignores `project-gotchas.md`; patches a symptom instead of the root cause; jumps to conclusions; introduces mild over-engineering; skipped mandatory workflow protocols.
  - **F (Fail - High Risk)**: Unacceptably lazy analysis (band-aids); dangerous architectural drift; massive over-engineering; blind to the blast radius; ignored parent workflow entirely.

## Phase 3: Deliverable (The Audit Report)
- Generate an artifact named `thinking_audit_[topic].md`. 
- **Mandatory Output Structure**:
  - `## Overall Grade: [A-F]`
  - `## 6-Point Evaluation Breakdown` (A bulleted list for each dimension)
  - `## Workflow Violations` (Did the log explicitly fail its Protocol Compliance check by ignoring parent structural rules? Name them!)
  - `## Weakest Logic Link` (Identify the specific edge case or rule the Builder AI missed).
  - `## Recommended Injection Prompt` (Provide a 1-sentence prompt the user can copy/paste back to the Builder AI to force it to fix the flawed logic or missing protocols).
- **Handoff**: State clearly whether the user should proceed to execution or reject the reasoning log.
