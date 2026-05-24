---

description: Automated Static UX Audit for Semantic Tone and Accessibility

---

# The UX Static Audit Workflow

This workflow executes a deterministic, zero-hallucination UX audit on the Flutter UI codebase. It specifically targets Semantic Copywriting (Tone of Voice) and Tap-Depth metrics.

## Step 1: Discovery & Auto-Chunking

1. Ask the user: *"Which module or router map are we checking today?"* If they don't know, ask for the main `router.dart` file.

2. Analyze the routing map and divide the application into logical "Chunks" (e.g., (1) Login Flow, (2) Admin Flow).

3. Present the Chunks to the user and ask them to confirm starting with Chunk 1. Do NOT proceed until they confirm.

4. Load the UX Copywriting skill (`view_file` on `.agents/skills/ux-copywriting/SKILL.md`).

## Step 2: Deterministic Extraction

// turbo

1. **Script-First**: Run `python .agents/scripts/scrape_strings.py --dir [target_dir] --out .agents/tmp/strings.json` from the project root.

2. Verify the output file exists in your `.agents/tmp/` directory before proceeding.

## Step 3: AI Semantic Audit

1. Read the extracted output: `view_file` on `.agents/tmp/strings.json`.

2. Evaluate the extracted strings against the 3 rules in the `UX Copywriting` skill.

3. Identify instances of Blaming, Developer Jargon, and weak CTAs.

## Step 4: Reporting

1. Generate an artifact named `ux_copywriting_report.md` in the `{App Data Directory}\brain\{Conversation ID}\` directory.

2. Format the report grouping violations by Dart file, showcasing a clear tabular comparison between the current string and the recommended rewrite.

3. Present the report to the user.

## Step 5: Guided Handoff (MANDATORY)

> [!IMPORTANT]

> After presenting the report, output this block verbatim:

**✅ Chunk [N] tone audit done. Next steps:**

1. **Fix** → Send `ux_copywriting_report.md` to the Builder Agent (`/implement`).

2. **Next chunk?** → Reply *"yes, continue to Chunk [N+1]"*.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
