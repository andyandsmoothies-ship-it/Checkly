# Workflow: /lay-foundation

> [!NOTE]

> AI Execution Blueprint for Day 0 Extreme Ambiguity. Guides collaborative elicitation and prevents AI agents from hallucinating technical solutions before defining the core business problem. Based on Software Requirements Essentials (Chapter 2).

## Core Directive: Iterative Elicitation

- **Active Support**: Do not act like a passive form. If the user doesn't know an answer, *propose* 2-3 options or ask leading questions to draw out the requirement.

- **Iterative Loops**: Real life is not waterfall. Expect to loop through these steps multiple times as the user's understanding of their own problem evolves.

## Step 1: Problem Elicitation (The 5 Whys)

- [ ] **Halt Convergence**: If the prompt contains a technical solution (e.g., "build a React app"), gently pause technical discussions to focus on the business problem.

- [ ] **Collaborative Interrogation**: Guide the user using the "5 Whys" technique to drill past symptoms. If they are stuck, suggest potential root causes based on industry standards.

- [ ] **Format Problem**: Draft an initial Problem Statement: `[Situation]`, `[Problem]`, `[Implication]`, `[Benefit]`, `[Vision]`.

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. Did we collaboratively reach the root business problem? If uncertain, propose a hypothesis and ask for feedback before proceeding.

## Step 2: Success Metrics & Vision

- [ ] **Quantify Value**: Help the user define 1-3 quantitative, measurable Success Metrics. Provide examples if they give vague goals (e.g., convert "better UX" into "reduce cart drop-off by 15%").

- [ ] **Compile Vision**: Co-create the Product Vision using the strict template: `For [Target] Who [Need], The [Product] Is a [Category] That [Benefit]. Unlike [Alternative], Our Product [Differentiator]`.

## Step 3: System Boundaries

- [ ] **Text Context Diagram**: Draw a strict ASCII/text map representing the system boundaries (e.g., `[External User] <--> [Core System] <--> [3rd Party API]`).

- [ ] **Define the "Out"**: Actively brainstorm what is strictly OUT OF SCOPE (No-Gos). Suggest specific exclusions to protect the user from scope creep.

## Step 4: Authority Map

- [ ] **Stakeholder Array**: List all interacting user roles, departments, and external systems.

- [ ] **Decision Maker**: Identify the single Empowered Decision Maker. (If the user is a solo founder, explicitly assign them this role).

## Step 5: Iteration & Artifact Handoff

- [ ] **The Iteration Gate**: Present the drafted foundation to the user. Ask: *"Does this capture the true goal, or do we need to iterate on the problem statement and boundaries?"* Loop back to Step 1 if the user wants to refine.

- [ ] **Commit Artifact**: Once approved, use `write_to_file` to save all Step 1-4 data into `docs/architecture/foundation_[YYYYMMDD_HHMMSS]_[topic]_[ConversationID].md`.

- [ ] **Routing**: Output the final prompt: *"Foundation established. Run `/start-project` for Day-1 stack selection and scaffolding, or `/define-requirements` to begin slicing use cases."*

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
