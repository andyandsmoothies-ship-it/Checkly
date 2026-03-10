# BPMN Gateways Guide (Process-bility Standard)

Gateways do not make decisions; they are merely routing mechanisms that direct the flow based on conditions that have *already been determined* by a prior task.

## 1. Exclusive Branching Gateway
*Role*: Routes the flow to **only one** of several possible paths based on a decision made previously.
*Analogy*: Toilet Signage. The decision of which restroom to use was made by the person before approaching the door; the sign just routes them to the correct path.

## 2. Exclusive Merging Gateway (ANTI-PATTERN)
**CRITICAL RULE**: The use of an Exclusive Merging Gateway is **NOT RECOMMENDED** in the Process-bility methodology.
- *Redundant Notation*: BPMN allows multiple incoming flows to merge directly into an activity. The explicit merging diamond is completely redundant.
- *Visual Clutter*: It breaks the "Visual Balance" rule.
- *Misleading*: It confuses readers into thinking an additional decision is happening at the merge.
**Action**: Simply draw all the sequence flows directly into the next Activity to merge them.

## 3. Parallel Branching Gateway
*Role*: Splits the flow into multiple branches that *can* run in parallel.
*Myth*: It does NOT mean they must happen simultaneously or in sync. It just means both activities are triggered and can happen independently (e.g., HR reviewing a resume while a manager separately schedules an interview). 

## 4. Parallel Merging Gateway
*Role*: Synchronizes incoming parallel flows. It ensures that *all* incoming paths are completed before proceeding to the next activity.
*Note*: Unlike exclusive merging, parallel merging *is* required as a gateway to act as the "gatekeeper", waiting for all parallel tokens to arrive.

## 5. Inclusive Branching Gateway
*Role*: Evaluates conditions and activates *one or more* branches based on the results. Any combination of paths is possible.
*Example*: A standard background check is launched for everyone, but if the candidate is applying for a technical role, a technical test path is also launched at the same time.

## 6. Inclusive Merging Gateway
*Role*: Waits for all *activated* incoming flows to complete before proceeding. It does not wait for all potential flows, only the ones that were actually triggered by the Inclusive Branching Gateway.

## 7. Event-Based Gateway
*Role*: Used when the process flow is determined by waiting for one of several possible *events* (external messages, timers, signals). The path taken depends entirely on which event happens first.
*Valid Subsequent Events*:
- Message Intermediate Catch Event (e.g., Candidate confirms interview)
- Timer Intermediate Event (e.g., 5 days pass with no response)
- Signal / Conditional Intermediate Events.
