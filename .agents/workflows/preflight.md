---
description: Pre-PR quality gate — dynamically enforces project gotchas and vertical-slice completeness before code leaves the developer's machine.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /preflight

> [!NOTE]
> This is a **Pre-PR Quality Gate** — run it before submitting code for review.
> It dynamically reads the project's `project-gotchas.md` and enforces automatable rules.
> This workflow is **project-agnostic**: it works for any project that follows the `.agents/rules/project-gotchas.md` convention.

## Phase 1: Scope Detection
- **Action**: Run `git diff --name-only` (or equivalent) to identify all files modified in the current working set.
- **Action**: Read `.agents/rules/project-gotchas.md` to load the project's known gotchas.
- **Output**: A list of modified files and a parsed gotcha inventory.

## Phase 2: Gotcha Classification
- **Action**: For each gotcha in `project-gotchas.md`, classify it into one of:

| Classification | Meaning | Example |
|----------------|---------|---------|
| `GREP_CHECKABLE` | Can be verified with a file/pattern search | "Bare `.get()` in DAO files without `limit()`" |
| `DIFF_CHECKABLE` | Can be verified by inspecting git diff for missing counterparts | "New DTO field must appear in 6 locations" |
| `MANUAL_REVIEW` | Requires human/AI judgment; cannot be automated | "Bottom nav label must be generic" |

- **Output**: A classified gotcha table.

## Phase 3: Automated Enforcement
For each `GREP_CHECKABLE` gotcha:
1. Derive the grep pattern and target file glob from the gotcha description.
2. Run `grep_search` against the modified files (from Phase 1).
3. Score each match as PASS or FAIL.

For each `DIFF_CHECKABLE` gotcha:
1. Identify the "trigger" pattern (e.g., new property added to an Entity class).
2. Search for the required counterpart patterns across the codebase.
3. If any counterpart is missing → FAIL.

> **@@SCAN** Before reporting, answer: (1) How many gotchas were GREP_CHECKABLE? (2) How many FAIL results?

## Phase 4: Vertical-Slice Completeness (Conditional)
- **Trigger**: Only runs if Phase 1 detected modifications to Entity, DTO, or Model files.
- **Action**: Load the `vertical-slice-completeness` skill. Run the Layer Propagation Checklist against each modified entity/field.
- **Output**: PASS/FAIL per entity-field pair.

## Phase 5: Report & Gate
- **Action**: Generate a `preflight_report_[date].md` artifact with the following structure:

```markdown
# Preflight Report — [date]

## Summary
- Total gotchas checked: [N]
- PASS: [N] | FAIL: [N] | MANUAL_REVIEW: [N]

## Automated Results
| # | Gotcha | Classification | Result | Details |
|---|--------|---------------|--------|---------|
| 1 | ... | GREP_CHECKABLE | ✅ PASS | ... |
| 2 | ... | DIFF_CHECKABLE | ❌ FAIL | Missing in: ... |

## Vertical-Slice Completeness
| Entity | Field | Layers Verified | Missing |
|--------|-------|----------------|---------|
| ... | ... | 5/6 | Flutter fromJson |

## Manual Review Checklist
- [ ] Gotcha #X: [description]
- [ ] Gotcha #Y: [description]
```

- **Gate Logic**:
  - If ANY `GREP_CHECKABLE` or `DIFF_CHECKABLE` gotcha is FAIL → **BLOCK**. Recommend specific fixes.
  - If only `MANUAL_REVIEW` items remain → **CONDITIONAL PASS**. Present checklist for human sign-off.
  - If all PASS → **CLEAR**. Recommend proceeding to `/verify` or PR submission.

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
