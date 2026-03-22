---
name: workflow-creator
description: Use this skill whenever the user asks you to create a new AI workflow, standardize a process, or organize a multi-step task into a reusable .md file. This skill guides you through drafting, formatting, and refining optimal workflow files (macros) that act as execution checklists for AI agents.
---

# Workflow Creator

A skill for designing and building highly reliable, modular AI workflows. 

At a high level, the process of creating a workflow goes like this:
- **Interview the User**: Understand the goal, the trigger (e.g., `/deploy`), and the specific concrete steps to achieve that goal.
- **Draft the Workflow**: Write a `.md` file in the `.agents/workflows/` directory.
- **Enforce Format Constraints**: Ensure the workflow is a sequential checklist, strictly bounded by the 500-line rule, using progressive disclosure for deep logic instead of bloating the workflow file itself.
- **Refine**: Review the draft with the user and optimize it based on AI attention-span best practices.

Your job when using this skill is to guide the user in translating a complex task into a lean, bulletproof AI execution macro.

---

## 1. Capture Intent (Interview Phase)
Start by understanding what the user's workflow needs to accomplish. If they just give you a rough idea, ask questions before writing the file.
1. What is the trigger command for this workflow? (e.g., `/audit-security`, `/ui-review`).
2. What are the major phases of the workflow?
3. What are the specific, executable constraints (e.g., terminal commands, target directories, exact frameworks)?
4. Are there existing Skills (`.agents/skills/`) that this workflow should load during execution?

## 2. Drafting the Workflow (The Format)

Because Large Language Models (LLMs) process text predictably and are prone to losing track of complex instructions, you MUST format the workflow using the following strict architectural rules. **Never generate a workflow as a wall of paragraphs.**

### The Sequential Checklist Format
Break the work down into clear, sequential steps using standard Markdown checkboxes (`- [ ]`). This acts as a roadmap. As the AI executes the plan, it can check off the boxes, preventing it from skipping steps or entering infinite loops during multi-step executions.

**Example:**
```markdown
## Phase 1: Preparation
- [ ] **Run Tests**: Execute `npm test` before making changes.
- [ ] **Dependency Check**: Trigger the `npm-auditor` skill to verify vulnerabilities.
```

### Explicit Constraints over Vague Descriptions
Prioritize strict, executable constraints.
- **Executable Commands**: Provide exact terminal commands with flags (e.g., `npm run lint -- --fix`) rather than "run the linter".
- **Concrete Styles**: Provide short, concrete code snippets instead of writing three paragraphs describing a preference.

### The 500-Line Rule & Progressive Disclosure
The core workflow file MUST be kept under 500 lines for optimal performance.
If instructions exceed this, the AI will likely skip steps or hallucinate. 
- **Rule**: If a step requires massive amounts of context (like the "Hostile Interrogation" protocol or deep formatting guidelines), **DO NOT put it in the workflow file**.
- **Action**: Extract that deep knowledge into a dedicated Skill (`.agents/skills/[skill-name]/SKILL.md`), and have the workflow simply point the AI to load that skill via a checklist item (`- [ ] Trigger the [skill-name] skill to perform the deep audit.`).

### Modular "Memory Bank" Structure
Instead of dumping all instructions into one file, separate concerns. A workflow can mandate the creation of specific artifacts to hold state across its lifetime: 
- `implementation_plan.md`: High-level overview and proposed changes.
- `task.md`: Ongoing task tracking (the checklist of execution).
- `walkthrough.md`: Final completion proof.

## 3. Workflow Header Structure
Every workflow must begin with a Frontmatter block and a Title block, defining its description. This description must be explicit about when the AI should use it.

```markdown
---
name: [Workflow Name]
description: [Explicitly state when the AI should trigger this workflow. Use precise keywords.]
---

# Workflow: /[slash-command]

> [!NOTE]
> [Brief summary of the workflow's purpose and output.]
```

## 4. Final Review
After drafting the `.agents/workflows/[filename].md`, present it to the user.
- Did we stay under 500 lines?
- Is it a checklist?
- Did we use progressive disclosure (pointing to Skills instead of bloating the workflow)?
- Are the commands explicit?

If yes, the workflow is ready to be used by any AI agent!
