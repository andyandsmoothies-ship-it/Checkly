---
name: bpmn-made-easy-kevintan
description: Use this skill to create, simplify, or review BPMN process models and workflows using the "Process-bility" framework by Kevin Tan. Trigger this whenever a user asks to design a BPMN diagram, document a business process, simplify a complex workflow, map agile user stories to processes, or perform business analysis. Make sure to use this to ensure processes are readable, visually balanced, and narrative-driven instead of overly technical.
---

# BPMN Made Easy with Process-bility

This skill guides you in applying Kevin Tan's "Process-bility" methodology to business process modeling. Process-bility reclaims BPMN for the human brain by shifting from a "Scribbler" (technical, overly complex, cluttered) to a "Storyteller" (clear, narrative-driven, visually balanced).

When assisting users with process mapping, documentation, or diagramming, you must adhere to the following principles:

## 1. The 5 Core Building Blocks
You don't need 100 symbols. Rely on these five to represent 90% of business logic:
- **Event:** The heartbeat (Start, Intermediate, End).
- **Activity:** The work performed. **MANDATORY**: Always use "Verb + Object" naming (e.g., "Approve Invoice", NOT "Invoice Approval Process").
- **Gateway:** The routing intelligence.
- **Swimlane:** The context of responsibility (Pools and Lanes).
- **Connecting Flow:** Chronological and communicative links.

## 2. The Gateway Rule (The Toilet Signage Analogy)
**Gateways do not make decisions; they only route flow.** The decision was made in a preceding task.
- Use Exclusive (XOR), Parallel (AND), Inclusive (OR), and Event-Based gateways.
- **Prohibit "Exclusive Merging" Gateways**: If multiple lines naturally converge at a task, an extra merging diamond is visual noise and implies a false decision point. Just point the flows directly to the task using a **T-junction** merge.

## 3. Visual Balance ("Reading Without Reading")
Models must be read effortlessly.
- **The Linear Flow Rule:** The primary value stream (Happy Path) must travel from left to right in a straight line. Deviations/exceptions flow vertically.
- **The Proximity Principle:** Group related tasks spatially. Keep tasks involving the same system/role close to imply logical association.
- **Grid Alignment:** Everything must align to a grid to eliminate visual noise.

## 4. Simplicity ("Less is More")
- **Externalize Business Rules:** Do not clutter diagrams with massive "If-Then" gateway explosions. Instead, use a "Business Rule Task" that points to external logic (like a DMN table). Keep the flow in BPMN, logic outside.
- **Encapsulate Complexity:** Use sub-processes `(+)` to collapse detailed routines, allowing high-level stakeholders (e.g., a CEO) to see the main story and operators to drill down.

## 5. Storytelling
Treat the process like a Hollywood movie with a narrative arc.
- An end-to-end process is a "Book"; departmental workflows are "Chapters".
- Example: Don't start a warehouse process with "Receiving". Start with "Truck Arrives", climax at "Quality Check", resolve at "Goods Slotted". Everyone must understand their role in the story's success.

## 6. Agile Mapping (For Developers & BAs)
Bridge the gap between Business and IT:
- **Activity** = Agile User Story.
- **Sub-process** = Agile Epic.
- **Gateway Outgoing Paths** = Acceptance Criteria / Testing Scripts (ensures developers understand the context of the feature).

## 7. Real-World Architecture
- **Avoid BPMN Monoliths:** Do not mix details from different departments into one giant model. Slice processes according to strict "Domain Boundaries".
- **The "Why Button":** Design for transparency so workers have business knowledge at their fingertips to understand *why* automated decisions were made.
- **Unstructured Work:** Use the **Ad Hoc Sub-process (~)** for creative/flexible tasks that cannot be mapped linearly, providing a "white spot" for human flexibility.

## Output Formatting
When outputting process models, **strictly use the `mcp_drawio_open_drawio_xml` tool to generate Draw.io XML**. Never use Mermaid or PlantUML, as their auto-layout engines often tangle paths and violate the Linear Flow Rule. Ensure you apply the "Verb + Object" rule, clearly delineate the "Happy Path" horizontally, drop exceptions vertically using T-junctions, and narrate the process as a cohesive story before diving into the technical nodes.
