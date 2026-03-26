---
description: Mid-Session Context Compaction and Brain Dump
---

# Workflow: /brain-dump

> [!NOTE]
> This is a **Context Salvaging** workflow. Use it mid-session when the context window is degraded, the AI is looping, or you need to clear the chat history without losing your execution state.

## Core Principle (The SCAN "Pre-Compact" Hook)
When an AI context window fills up, cognitive degradation begins (forgetting rules, hallucinating files, looping). A forced context clearance is required. However, clearing the context destroys the immediate execution state. The `/brain-dump` workflow explicitly captures the delta of recent work so a new session can resume instantly.

## Phase 1: State the Recent Delta
1. **Uncommitted Changes**: Run `git status` to identify exactly what files are currently dirty.
2. **Current Micro-Goal**: Identify the exact micro-step the user was trying to accomplish right before triggering this workflow.
3. **Recent Learnings**: Identify any immediate gotchas or roadblocks encountered in the last 10 messages that aren't yet in `MEMORY.md`.

## Phase 2: Execute the Brain Dump
1. Overwrite `.claude/handoff.md` (or the project's designated handoff file) with a highly compressed summary of the immediate state.
2. Format the `handoff.md` identically to the `session-management` skill's required format.
3. **CRITICAL**: The `Pending` section must explicitly list the absolute next step the user should take, down to the file and line number if applicable.

## Phase 3: Handoff to User
Reply to the user with the following exact message:
> **Brain Dump Complete.** 
> Your execution state has been safely serialized to the handoff file. 
> You may now safely **clear this chat context** or open a new session. When you start the new session, simply say "resume" and the `session-management` skill will automatically load this state.
