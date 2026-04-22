---
description: SRE Hostile Architecture Review — Hunts for distributed systems failure, Poison Pills, Zombie nodes, Fake-Smart Complexity, and 2 AM landmines.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /audit-arch

> [!CAUTION]
> **Hostile Red-Team Mode Authorized**. Role: **Chief Architect / SRE**. 
> Do not be polite. Do not assume good intent. Your job is to find the catastrophic edge cases that will trigger a 2:00 AM PagerDuty alert. Strip away "fake-smart" complexity and attack the raw system mechanics.

## Phase 1: Scope & Threat Modeling

| Step | Execution Contract |
|---|---|
| **Trigger** | Execute when a new feature implies concurrency, sync, caching, background workers, or complex state across microservices/clients. |
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. List ONLY the audit artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation phase. |
| **System Boundary** | Extract the target system (e.g., "Offline Sync", "Auth Cache", "Message Queue"). Identify exactly what fails if the network drops by 50% or latency spikes to 5000ms. |

## Phase 2: The Brutal Interrogation (The 4 Critics)

You must subject the proposed architecture to these 4 hostile critics. If it survives, it ships.

### Critic 1: The Zombie (Stateless Illusion)
- [ ] **Long-Lived Connections**: Does this design require holding an open connection (WebSocket, DB Listen, SSE) on a web node? What happens when the cloud load balancer randomly kills it? Does the node silently become a "Zombie"?
- [ ] **Cache Rebuilds**: When invalidating cache, do we rebuild the entire universe (O(N) DB query) or surgically update one key? Will a bulk update trigger a massive Garbage Collection (GC) pause or memory spike that locks the server?

### Critic 2: The Split-Brain (State & Sync)
- [ ] **Clock Drift**: Does resolution rely on client-side timestamps? If a user's device is 3 minutes in the future, does the server silently drop or corrupt their data?
- [ ] **Transactional Fracture**: Are logically bound items (e.g., an Order and its Payment) pushed in completely separate asynchronous REST/RPC calls? If the network drops between them, is the business state permanently corrupted?

### Critic 3: The 2 AM Landmine (Resilience & Observability)
- [ ] **The Poison Pill**: If the first item in an asynchronous queue or batch throws a 400 Bad Request, does the script `catch` and retry forever? Are all valid items behind it permanently blocked? Where is the Dead Letter Queue (DLQ)?
- [ ] **The Thundering Herd**: If 50 events happen simultaneously, do all load-balanced backend nodes wake up and execute intensive identical operations, effectively DDoS-ing your own primary database or downstream APIs?

### Critic 4: The Brick (Boundary & Exploit Risk)
- [ ] **The "Root" Suicide**: Can an administrator accidentally revoke their own root access? Is there a hard-coded superuser guard, or can the system permanently brick its own control plane?
- [ ] **Contextual Illusion (IDOR)**: Does the authorization check just verify a string (e.g., `can_write`), but forget to verify the *target* ID (e.g., `Resource == User.Resource`)? Is it relying on a generic role check to do a job Attribute-Based Access Control (ABAC) should be doing?

> **@@SCAN**: Execute the interrogation. Record exact failure scenarios for each critic.

## Phase 3: The Verdict Payload

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `audit_arch_report_[date-time]_[ConversationID].md` in `brain/` folder. Format as a stark, unappeasing teardown. |
| **Severity Matrix**| `🔴 Fatal` (Bricks the system / Data Corruption / DDoS) | `🟡 Brittle` (Fake-Smart. Will scale poorly or fail silently) | `🟢 Resilient` (Actually viable). |
| **Actionable Fix & Trade-offs** | MANDATORY: Do not just complain. Provide the exact system design fix (e.g., "Implement Exponential Backoff Retry").<br><br>**CRITICAL:** When proposing a fix, you MUST present the **Trade-offs / Pros & Cons** of the solution (e.g., "Pro: Solves OOM. Con: Adds 200ms latency."). Yield for the user to make the final executive decision before writing code. |

## Phase 4: Deliverable Handoff

| Step | Execution Contract |
|---|---|
| **Verification** | Execute `list_dir` on brain directory -> Confirm report written securely. |
| **Routing Map** | All findings mandate a shift to the `/research` or `/analyze-epic` workflow to formally redesign the component before any code is written. |

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:
> 1. Final SRE Verdict (Fatal/Brittle/Resilient) & Persistent path.
> 2. Summary of 2AM Landmines found.
> 3. **AI Agent Mission Brief** (A short, concise 1-2 sentence TL;DR so the next AI agent instantly knows exactly what to do).
> 4. The exact next workflow command the user should run (e.g. `/analyze-epic`).
>
> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}rain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
