---

description: Trigger this workflow when the user asks to design a BPMN diagram, document a business process, simplify a complex workflow, or map agile user stories to processes using the Kevin Tan Process-bility framework.

---

# Workflow: /create-process

> [!NOTE]

> This workflow guides the AI in designing a 10/10 business process diagram. It strictly enforces the "Process-bility" mindset (Less is More, Visual Balance, Storytelling) while correctly applying formal BPMN elements (Events, Activities, Gateways, Swimlanes, and Artifacts).

## Step 1: Discovery & Definition (The "Who" and "What")

- [ ] **Load Process-bility Skill**: Read `.agents/skills/bpmn-made-easy-kevintan/SKILL.md` to load the modeling constraints.

- [ ] **Validate BPMN Fit**: Ensure the request is actually a sequential business workflow. BPMN is not for data models, state machines, or UI maps. Do not force non-process ideas into a BPMN context.

- [ ] **Clarify Vague Inputs**: If the user's prompt is unclear or lacks step-by-step details, pause and propose a high-level text outline of the process before generating any diagrams. Do not guess complex logic blindly.

- [ ] **Define Swimlanes (Optional)**: Identify participants. *Only use Pools/Lanes if the process involves multiple distinct actors or handoffs. Single-actor processes do not need swimlanes.*

- [ ] **Define Events**: Identify the specific Trigger (Start Event) and all possible Outcomes (End Events).

## Step 2: Structural Drafting (The Happy Path)

- [ ] **Initialize Artifact**: Create or update a `process_design_plan.md` artifact to document the flow before rendering.

- [ ] **Draft the Happy Path (Activities)**: Model the primary value stream linearly from left to right.

- [ ] **Apply the Verb + Object Rule**: Ensure every Activity (task) is named with a clear, actionable Verb + Object (e.g., "Verify Payment", not "Payment Verification").

## Step 3: Routing & Exception Handling (Gateways)

- [ ] **Route with Intelligence**: Insert Gateways (Exclusive XOR, Parallel AND, Event-Based) to branch flow. *Remember: Gateways do not make decisions; they route based on the outcome of the previous Activity.*

- [ ] **Vertical Deviations**: Route all exceptions, fallbacks, or alternate paths vertically downwards from the main Happy Path.

- [ ] **Strict Connector Rules**: Use exact line styles. **Sequence Flows** (solid line, 1-way arrow) for task order. **Message Flows** (dashed line, arrow) for cross-pool communication. Use orthogonal lines with **rounded corners** for aesthetic balance.

- [ ] **T-Junction Merging**: Merge alternate paths back into the main flow using simple Sequence Flows (T-junctions). **Strictly prohibit "Exclusive Merging" diamonds.**

## Step 4: Encapsulation & Context (Artifacts)

- [ ] **Encapsulate Complexity**: If an activity is too complex (e.g., a massive If-Then logic tree), collapse it into a Sub-process (+) or extract it to a Business Rule Task.

- [ ] **Add Artifacts Sparingly**: Use Data Objects or Text Annotations only when crucial for understanding context, keeping the diagram uncluttered.

## Step 5: Diagram Generation & Handoff

- [ ] **Grid Alignment**: Mentally ensure all elements are visually balanced and aligned to a rigid grid to maintain the "Reading Without Reading" principle.

- [ ] **Generate Diagram**: Use the MCP Draw.io tool (`mcp_drawio_open_drawio_xml`) to generate the XML diagram. **Never use Mermaid or PlantUML.**

- [ ] **Deliver & Request Feedback**: Present the `process_design_plan.md` and the rendered diagram to the user.

<mandatory_constraints>

- NEVER execute `git` commands. Yield to the user.

- TESTS ALWAYS WIN over Markdown plans.

</mandatory_constraints>
