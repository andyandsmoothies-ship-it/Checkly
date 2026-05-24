---

description: Execute a deterministic Python sweep on the Flutter UI codebase to flag hardcoded colors, missing Semantic tags, and rogue padding values.

---

# Workflow: /audit-design

> [!NOTE]

> This workflow acts as the Bouncer for the Design System. It ensures that developers are not hacking the UI with raw `Colors.xxx` or unscaled typography, enforcing absolute compliance.

## Pre-Flight Check

- [ ] Ensure `C:\Users\HP\Documents\GitHub\Checkly\.agents\scripts\scrape_a11y.py` exists.

- [ ] Load the `frontend-accessibility` skill (`view_file` from `.agents/skills/frontend-accessibility/SKILL.md`).

## Step 1: Discovery & Auto-Chunking

- [ ] Ask the user: *"Which module or router map are we checking today?"* If they don't know, ask for the main `router.dart` file.

- [ ] Analyze the routing map and divide the application into logical "Chunks" (e.g., (1) Login Flow, (2) Admin Flow).

- [ ] Present the Chunks to the user and ask them to confirm starting with Chunk 1. Do NOT proceed until they confirm.

## Step 2: Deterministic Extraction

// turbo

- [ ] Run the extraction script against the specific Chunk directory: `python .agents/scripts/scrape_a11y.py --dir [CHUNK_DIRECTORY] --out .agents/tmp/a11y_violations.json` (Run from project root).

- [ ] Verify `.agents/tmp/a11y_violations.json` exists.

## Step 3: Remediation Mapping

- [ ] Read the output JSON: `view_file` on `.agents/tmp/a11y_violations.json`.

- [ ] Map all violations (e.g., `Colors.red` used instead of `AppTheme.error`) into a prioritized checklist.

- [ ] Correlate with the `frontend-accessibility` rules to define exactly what the correct replacement code should be.

## Step 4: Reporting

- [ ] Generate an artifact named `a11y_compliance_report.md` in the `{App Data Directory}\brain\{Conversation ID}\` directory.

## Step 5: Guided Handoff (MANDATORY)

> [!IMPORTANT]

> After presenting the report, output this block verbatim:

**✅ Chunk [N] scan done. Next steps:**

1. **Fix** → Send `a11y_compliance_report.md` to the Builder Agent (`/implement`).

2. **Verify** → After the fix, run: `python .agents\scripts\scrape_a11y.py --dir [CHUNK_DIR] --out .agents\tmp\a11y_v2.json` → expect `Found 0 violations`.

3. **Visual check** → Screenshot changed screens → run `/check-visuals`.

4. **Next chunk?** → Reply *"yes, continue to Chunk [N+1]"*.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
