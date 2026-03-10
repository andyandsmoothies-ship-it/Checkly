---
name: bpmn-modeling
description: Create clear, visually balanced BPMN models using the "Process-bility" principles (Storytelling, Simplicity, Visual Balance). Use when the user asks to create or review a BPMN diagram, model a business process, or map a workflow.
---

# BPMN Modeling with Process-bility

This skill mandates that all Business Process Model and Notation (BPMN) diagrams conform to the "Process-bility" principles. This means prioritizing **Visual Balance**, **Simplicity**, and **Storytelling** over exhaustive technical correctness.

## The Core Mandate: Simplicity over Compliance
BPMN is often misused by modelers who treat it as a programming language to capture every single rule and data flow. **You must avoid this.** A process model is an X-ray of a business: its sole purpose is clear communication to humans.

- Ensure your models are visually balanced (no crossover spaghetti).
- Keep it simple: use the 5 key elements (Event, Activity, Gateway, Swimlane, Connecting Flow).
- Tell a clear story with a distinct beginning, middle, and end.

## The Strict Anti-Pattern: Exclusive Merging Gateways
**NEVER use an Exclusive Merging Gateway (an empty diamond or a diamond with an X used just to converge flows together).** 
In Process-bility, this is considered a critical error. Gateways do not make decisions; they route them. If you need to merge multiple paths back into the main flow, simply draw the incoming `Sequence Flow` lines directly into the next *Activity*. Do not clutter the diagram with a redundant merge gateway.

---

## Progressive Disclosure References

Before designing a complex process, you MUST invoke the relevant reference documents to ensure compliance with the methodology:

- To review the core 5 elements, the 3 principles of Process-bility, and the philosophy of avoiding visual clutter, run:
  > `view_file .agents/skills/bpmn-modeling/references/process-bility-principles.md`

- If your process involves branching logic, splitting paths, synchronizing parallel tasks, or handling events, you MUST review the strict Gateway guidelines (especially the rules around Parallel Merging and Inclusive Gateways):
  > `view_file .agents/skills/bpmn-modeling/references/bpmn-gateways-guide.md`

- **The Extreme Simplicity Rule (No Advanced Notations)**: If you are asked to model "complex" exceptions (like Boundary Events, Compensation, or global Call Activities), **you must reject the attempt to use those notations**. Explain that under the Process-bility standard, we intentionally flatten such logic into simple Activities, standard Gateways, or separate sub-story diagrams to preserve readability for non-technical stakeholders.
