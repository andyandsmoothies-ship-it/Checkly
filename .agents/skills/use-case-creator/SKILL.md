---
name: use-case-creator
description: Create comprehensive, high-quality Use Cases following the Use-Case 3.0 Authoring and Storytelling practices. Use this skill whenever a user asks to write, draft, define, or create a Use Case, or when defining requirements before slicing into user stories or features. Make sure to use this skill to ensure Use Cases properly capture the primary actor, basic scenario (happy path), extensions (alternate/error flows), and preconditions to perfectly prepare them for the slicing workflow.
---

# Use Case Creator

A skill for writing comprehensive, rigorous Use Cases according to the **Use-Case 3.0** (Storytelling and Authoring) framework.

At a high level, the process of creating a Use Case follows these steps:
- **Understand the Goal**: Identify the primary actor and what they want to achieve.
- **Define the Foundation**: Establish the System of Interest, Pre-conditions, and Post-conditions.
- **Write the Basic Scenario**: Outline the "Happy Path" step-by-step.
- **Develop Extensions**: Identify all alternative paths, special cases, and error conditions.
- **Add Supporting Info**: Define system-wide (non-functional) requirements and test variables.

Your job when using this skill is to guide the user through capturing the full story of a requirement, ensuring no edge cases or critical failure paths are missed, so that the output can be perfectly consumed by the `use-case-slicing` skill.

---

## Communicating with the user

When gathering requirements for a Use Case:
- Ask clarifying questions about alternate paths (e.g., "What happens if the payment fails here?").
- Don't overwhelm the user by asking for everything at once. Progressive disclosure is key: get the basic scenario right first, then brainstorm extensions.
- Use simple flow diagrams (like `[User] -> [System]`) in text to confirm complex logic before formalizing it.

---

## Creating the Use Case

### Step 1: Capture the Core Intent

Determine the boundaries of the Use Case. If the user hasn't provided enough context, ask:
1. What is the main goal the user is trying to achieve?
2. Who is the Primary Actor initiating this? Are there any Supporting Actors (like external APIs or admin systems)?
3. What is the System of Interest? (What are we building/modifying?)

### Step 2: Establish the Foundation

Define the state of the world before and after the Use Case executes.
- **Pre-conditions**: What must be true for this Use Case to begin? (e.g., "User is logged in", "Cart has items").
- **Post-conditions**: What is the state of the system when the Use Case succeeds? What is the state if it fails?

### Step 3: Write the Basic Scenario (The Happy Path)

Describe the optimal, straight-line path from the trigger to the successful achievement of the goal.
- Write this as a numbered list of steps.
- Each step should be simple and clear, describing who is doing what (e.g., "1. The Customer enters their shipping address.", "2. The System validates the address.").
- Do not include `if/else` logic here. Keep it strictly focused on success.

### Step 4: Identify and Write Extensions

This is the most critical part of Use-Case Authoring. Look at each step in the Basic Scenario and ask: "What could go wrong? What alternative choices does the actor have?"

*Mandatory Checks:*
- **Functional Errors**: Invalid input, declined actions.
- **Edge & Boundary Cases**: Extreme data limits, zero/null values, timezone boundaries.
- **Systemic & Concurrency**: Network timeouts, double-clicks/duplicate requests, race conditions.

For each extension:
- Reference the step it diverges from (e.g., `3a. Address validation fails`).
- List the steps taken within the extension.
- Specify how the extension ends (e.g., "Returns to step 3", "Use Case ends in failure").

### Step 5: Variables and Non-Functional Requirements

To make the Use Case ready for testing and slicing:
- **Variables**: Identify the data variables that would drive test cases (e.g., "Valid Payment Token", "Expired Credit Card").
- **System-Wide Requirements**: Any non-functional requirements specific to this use case (e.g., "Address validation must complete in < 500ms").

---

## Output Format

ALWAYS output the final Use Case using the following structured Markdown template. This exact structure is required so that downstream skills (like `use-case-slicing`) can parse it easily.

```markdown
# Use Case: [Name of the Use Case]

**Goal:** [A brief sentence describing the value achieved by the actor]
**Primary Actor:** [Actor Name]
**Supporting Actors:** [List any external systems or secondary actors]
**System of Interest:** [What system are we interacting with]

## 1. Conditions
- **Pre-conditions:** [What must be true before this starts]
- **Post-conditions (Success):** [State of the system on success]
- **Post-conditions (Failure):** [State of the system on failure]

## 2. Basic Scenario (Happy Path)
1. [The Primary Actor does X]
2. [The System does Y]
3. [The Primary Actor does Z]
4. [The System does A]
*(Goal is achieved)*

## 3. Extensions
**[Step#]a. [Name of Alternative or Error Path]**
1. [Description of what happens]
2. [Description of system response]
*(Ends: Returns to step X | Use Case ends in failure)*

**[Step#]b. [Another Alternative Path]**
1. [Description of what happens]
*(Ends: Returns to step X)*

## 4. Supporting Information
- **Test Variables:** [List of inputs to vary for testing, e.g., Invalid Email, Expired Token]
- **Non-Functional Requirements:** [Performance, security, or compliance constraints]
```

### Writing Patterns & Tips
- **Be Imperative and Active**: Use active voice. "The System verifies the token", not "The token is verified."
- **Use EARS Notation for Rules**: When writing business rules or acceptance criteria, use EARS notation: `WHEN [trigger] THE System SHALL [action]` for nominal paths, and `IF [error condition] THEN THE System SHALL [action]` for error paths.
- **Audit for the 4 Requirement Bugs**: Before finalizing, review for:
  1. **Wrong Level of Detail**: Avoid thesis statements ("The system shall have auth") or implementation recipes ("The system shall use JWT").
  2. **Ambiguity**: Ensure observable outcomes are pinned down.
  3. **Inconsistency**: Ensure no two rules clash under the same conditions.
  4. **Incompleteness**: Verify all input combinations and edge cases are covered.
- **Avoid Implementation Details**: Say "The System authenticates the user", not "The System checks the JWT in the Postgres database." Use Cases should survive database migrations.
- **Tell the Whole Story**: Ensure every extension explicitly states how it resolves (success, failure, or resuming the basic scenario).
