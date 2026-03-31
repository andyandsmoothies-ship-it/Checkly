# Process-bility Principles for BPMN

BPMN is a powerful notation standard, but it is often misused and overcomplicated. The "Process-bility" methodology strips away the complexity of BPMN and focuses on using it as a true storytelling tool to foster clarity, growth, and collaboration.

## The 3 Core Principles

1. **Visual Balance**: Ensure the model is easy on the eyes. Use proper alignment, consistent spacing, and clear organization. Avoid messy cross-over lines and cluttered activities. 
2. **Simplicity**: "Less is more." Do not model every single exception or nuance if it breaks the narrative flow. Include only the elements that tell the story clearly without overwhelming the reader.
3. **Storytelling**: Every model tells a story with a beginning, middle, and end. The goal is to ensure the process flow is easy to follow and that each task, event, and decision fits within a coherent narrative that anyone (from a CEO to a frontline employee) can understand.

## The 5 Key Elements of BPMN
By mastering these five building blocks, you can navigate BPMN without being overwhelmed by its many notation variations:

1. **Event**: Something that occurs during a process (Start Event, Message Start Event, End Event, Intermediate Timer Event).
2. **Activity**: Work that is being performed (Tasks, Sub-processes, Call Activities). *Use Sub-processes to group related tasks and declutter the top-level diagram.*
3. **Gateway**: Controls the flow of a process by splitting into paths or converging back. (See `bpmn-gateways-guide.md` for strict usage rules).
4. **Swimlane**: Represents roles, teams, or systems. Visually organizes who does what (Pools for participants, Lanes for roles within a Pool).
5. **Connecting Flow**: The lines linking objects (Sequence Flow for order of activities, Message Flow for communication between Pools, Association Flow for linking notes/data).

## Common Mistakes to Avoid
- **Overcomplicating**: Do not map every single rule. BPMN is for communication, not just technical execution.
- **Misuse of Gateways**: See the Gateways guide to avoid improper merging/branching.
- **Lack of Sub-Processes**: Failing to group activities leads to overwhelming "spaghetti" models. Use Sub-processes to cater to audiences who need high-level overviews safely before diving into technical specifics.
