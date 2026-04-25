# Architectural Decision Record: Offline Conflict Resolution Synthesis
**Thunderdome: `/synthesize` - 2 competing offline-conflict researches**

- **Conversation ID**: `20260425_synthesize_offline_conflict`
- **Date**: 2026-04-25
- **Auditor Role**: Chief Architect / Offline Sync Red Team
- **Input Artifacts**:
  1. `C:\Users\HP\Documents\GitHub\Checkly\.agents\tmp\research\research_offline_conflict.md`
  2. `C:\Users\HP\Documents\GitHub\Checkly\.agents\tmp\research\research_conflict_resolution_c854cf46.md`

**[ORIGIN_IDEA]**
Tackle the "Last-Write-Wins" vs "Merge" conflict resolution logic for concurrent offline edits on action plans without breaking Checkly's offline-first sync pipeline.

<latent_space_scratchpad>
The first research treats the problem as generic concurrent editing and recommends strict optimistic concurrency with 409 responses. That is defensible in a vacuum but too abstract.

The second research inspects the actual product boundary and discovers the far more important fact: Checkly does not currently support true multi-actor offline collaboration on action plans. The offline queue is narrowly used by store managers submitting evidence, while auditors close or reject online. That means the real production anomaly is not "two people co-author text offline." It is "a stale offline evidence payload can resurrect a terminal plan state."

The mobile-offline-support skill breaks the tie. It says LWW with a mutation queue is the default for simple offline data, server-wins is appropriate for compliance scenarios, and merge/CRDTs are only justified for real collaborative editing. Checkly is a compliance product with Drift + mutation queue, not Google Docs.

That kills CRDT/manual merge immediately. It also weakens the blanket 409 strategy because 409 is only worth its queue complexity if we truly need per-edit conflict UX. The current app does not have that UX, and the current queue for action-plan evidence has no nuanced retry classification. A hard 409 path here risks turning one stale mutation into an outbox poison pill.

The winning shape is therefore: keep PATCH/LWW semantics for text fields, add a backend terminal-state guard so closed plans cannot be resurrected, and only add targeted sync handling for stale action-plan mutations if the backend returns a non-success result. Do not generalize beyond the real write surface.
</latent_space_scratchpad>

## Normalized Summary Of Options

### Option A: Strict Optimistic Concurrency
- **Source**: `research_offline_conflict.md`
- **Hypothesis**: Add `RowVersion/xmin` to `ActionPlan`, return `409 Conflict` on stale writes, and teach the Flutter sync engine/outbox to dequeue or surface conflicts safely.
- **Blast Radius**: Backend entity/model/configuration changes, API contract changes, mobile payload/token changes, sync-engine classification, new user conflict UX.
- **Strength**: Detects same-row races explicitly.
- **Weakness**: Solves a broader problem than the product currently has and introduces queue-fragility risk.

### Option B: Semantic Merge + Backend State Guard
- **Source**: `research_conflict_resolution_c854cf46.md`
- **Hypothesis**: Preserve existing PATCH semantics and LWW for text fields, but hard-block illegal state regression such as `closed -> pending_verify`.
- **Blast Radius**: Primarily `server/Features/ActionPlans/UpdateActionPlan.cs`; optional narrow sync-engine handling for stale action-plan failures.
- **Strength**: Fixes the observed "zombie resurrection" anomaly without inventing generic conflict infrastructure.
- **Weakness**: Same-field text collisions remain LWW rather than explicitly surfaced.

## Hostile Interrogation

### Option A Attack Vector: Outbox Poison Pill
One store manager syncs after an auditor already closed the plan. The server returns `409 Conflict`. The action-plan outbox currently has only coarse error handling: mark exhausted and stop the cycle. In production, a single stale evidence record becomes a permanent failure badge, blocks trust in sync, and forces support to explain why the user's evidence "vanished" after looking successfully queued offline. If the team forgets to add precise dequeue/recovery UX, the queue becomes hostile infrastructure.

**Mitigation check**: This option is only safe if the implementation includes mobile payload/version plumbing, action-plan-specific 409 classification, dequeue rules, and visible user recovery messaging. None of that exists today.

### Option B Attack Vector: Silent Partial Loss
The backend blocks `closed -> pending_verify`, but the stale payload also contains valid evidence text that the business wanted preserved. If the endpoint returns a generic 400 and the sync engine simply exhausts the record without any product signal, the user believes their offline evidence synced while the server ignored it. That is quieter than a 409 but still operationally ugly.

**Mitigation check**: This option is only safe if the backend returns a clearly classifiable stale-state error and the mobile queue handles that path deliberately, not as an opaque generic failure. The mitigation is much narrower than Option A because it does not require row-version propagation or conflict diff UI.

## Pugh Decision Matrix

**Baseline**: Option A = `0`

| Criterion | Weight | Option A: Strict 409 / RowVersion | Option B: Semantic Merge + State Guard | Rationale |
|---|---:|---:|---:|---|
| **Origin Idea Alignment** | 5 | 0 | +1 | The real business problem is stale offline evidence resurrecting terminal plans, not full collaborative editing. |
| Offline Sync Capability | 4 | 0 | +1 | Option B preserves the existing Drift queue model; Option A requires new version-token plumbing everywhere. |
| Outbox Reliability | 4 | 0 | +1 | Option A introduces a new poison-pill class (`409`) into a queue that does not yet classify it safely. |
| Data Integrity On Real Failure Mode | 4 | 0 | +1 | Option B directly blocks `closed -> pending_verify`, the concrete integrity bug surfaced by the deeper research. |
| Same-Field Collision Detection | 2 | 0 | -1 | Option A is better at explicit conflict detection when two actors edit the same field concurrently. |
| Blast Radius | 3 | 0 | +1 | Option B is mostly backend-local; Option A spans backend schema, DTOs, queue, and UX. |
| Operational Complexity | 3 | 0 | +1 | Option B is tactical; Option A requires new cross-stack conflict handling policy. |
| UX Recovery Burden | 2 | 0 | +1 | Option B can stay mostly invisible if stale-state failures are classified; Option A requires explicit conflict recovery UX. |
| Performance / Payload Cost | 1 | 0 | +1 | Option B adds no row-version payloads or extra comparison logic on every mutation. |

### Weighted Totals
- **Option A**: `0` (baseline)
- **Option B**: `+22`

**Mathematical winner**: **Option B - Semantic Merge + Backend State Guard**

## Final Verdict
Choose **Option B**, hardened with an explicit stale-state rejection flow.

The first research is directionally correct that silent overwrites are dangerous, but it jumps to a generic concurrency architecture before proving the app actually needs it. The second research does the harder work: it maps the real offline write surface, finds the actual integrity failure (`closed -> pending_verify` resurrection), and recommends the smallest architecture that fixes that failure without destabilizing the queue.

The best-practice-first implementation is:
- Keep LWW/PATCH semantics for simple text fields in normal allowed transitions.
- Add a server-side terminal-state guard in `UpdateActionPlan.cs` so `closed -> pending_verify` is rejected.
- Return an explicit machine-readable stale-state response, not a generic `400` and not a silent `200` partial accept.
- Audit-log the rejected stale attempt for forensics.
- Teach the mobile sync path to classify this specific stale-state response as non-retryable so the queue item is dequeued instead of becoming a poison pill.
- Do **not** silently save evidence text against a closed plan through the same update path. That changes the meaning of `closed` and is not a safe default without explicit product approval.
- Do **not** add CRDTs, manual merge UI, or broad `RowVersion` plumbing for `ActionPlan` now.
- Re-open the 409/row-version design only if Checkly later enables true multi-actor offline editing on the same action-plan fields.

## Executive Business Summary
In real life, this means Checkly should stop stale offline evidence from reopening already-verified action plans, and it should do so with explicit server semantics rather than hidden partial success. The winning approach is cheaper and safer than full optimistic concurrency, but it also avoids the compliance ambiguity of silently mutating closed plans. Users keep the current offline workflow, engineering fixes the real integrity hole, and the sync queue stays healthy because stale mutations are deliberately classified as non-retryable.

## Final Solution To Implement

### Phase 1: Safe Best-Practice Fix
1. In `server/Features/ActionPlans/UpdateActionPlan.cs`, detect stale offline evidence submissions where the current persisted plan is `closed` and the incoming request tries to move it back to `pending_verify`.
2. Reject that transition with a specific RFC 9457 `ProblemDetails` response, for example `409 Conflict` with a stable code such as `action_plan_already_closed`.
3. Write an `AuditLogger` entry for the rejected attempt so support and compliance have a forensic trail.
4. In the mobile sync path, treat that specific error code as non-retryable and dequeue the outbox item so it cannot block unrelated sync work.

### Phase 2: Optional UX Recovery
- Only if product explicitly wants local recovery, add a small local failed-mutation store and user messaging.
- Do not include this in the first implementation unless preserving rejected offline text is a confirmed requirement.

## Strict Implementation Constraints & Human Reminders
- Do not broaden the scope into generic "offline collaboration."
- Do not add CRDTs, OT, or manual conflict-resolution screens.
- Do not add `RowVersion/xmin` to `ActionPlan` unless product requirements change to true concurrent editing support.
- Preserve PATCH semantics for non-overlapping text-field updates.
- Block illegal terminal-state regression on the server, especially `closed -> pending_verify`.
- If the server rejects stale action-plan evidence, the mobile queue must classify that path intentionally as non-retryable. Do not let one stale record silently halt unrelated sync work.
- Do not implement "safe partial acceptance" on the existing update path unless product explicitly approves closed plans remaining content-mutable after closure.
- Add tests that prove the chosen guard works and that stale action-plan sync failures do not become invisible data loss.

<forensic_evidence>
[x] `view_file` equivalent via `Get-Content` on `C:\Users\HP\Documents\GitHub\Checkly\.agents\tmp\research\research_offline_conflict.md`
[x] `view_file` equivalent via `Get-Content` on `C:\Users\HP\Documents\GitHub\Checkly\.agents\tmp\research\research_conflict_resolution_c854cf46.md`
[x] `grep_search` equivalent via `rg` for `PendingActionPlanUpdates|updateActionPlan|sync_engine|RowVersion|xmin|closed|pending_verify`
[x] Verified current server behavior in `C:\Users\HP\Documents\GitHub\Checkly\server\Features\ActionPlans\UpdateActionPlan.cs`
[x] Verified current mobile queue behavior in `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\sync_engine.dart`
[x] Verified current mobile action-plan offline enqueue path in `C:\Users\HP\Documents\GitHub\Checkly\lib\features\action_plans\manager\action_plan_manager.dart`
[x] Verified `ActionPlan` currently lacks a concurrency token in `C:\Users\HP\Documents\GitHub\Checkly\server\Common\Persistence\Entities\ActionPlan.cs` and `C:\Users\HP\Documents\GitHub\Checkly\server\Common\Persistence\Configurations\ActionPlanConfiguration.cs`
</forensic_evidence>

## Handoff Block
- **Final Verdict**: Implement semantic merge + backend terminal-state guard, with explicit stale-state rejection and non-retryable mobile handling. Reject broad `ActionPlan` optimistic-concurrency plumbing for now.
- **Strict Constraints**: Fix the real zombie-state anomaly first. Do not invent generic collaboration infrastructure. Do not silently mutate closed plans through partial acceptance. Any mobile follow-up must prevent stale action-plan failures from poisoning the queue.
- **Execution Slices**:
  1. Backend: guard illegal `closed -> pending_verify` transition, emit specific `ProblemDetails`, and audit-log the rejection.
  2. Tests: prove the guard blocks resurrection while preserving allowed transitions and correct error semantics.
  3. Mobile: classify the specific stale-state error as non-retryable and dequeue it.
  4. Optional later: local failed-mutation retention if product wants user recovery of rejected text.
- **Requirements Alignment Check**: No `requirements.md` specific to offline conflict was located, and the winning design preserves the current user flow. No requirements update is mandatory at this stage. If product later wants explicit conflict prompts or true multi-user offline co-editing, a requirements update becomes mandatory before implementation.
- **AI Agent Mission Brief**: Treat offline action-plan conflict as a terminal-state integrity problem, not a generic collaborative editing problem. Implement the narrow server guard, explicit stale-state response, audit logging, and non-retryable queue handling first.
- **Next Workflow Command**:
  `[/analyze-feature] C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_synthesize_offline_conflict\decision_record_offline_conflict_20260425_synthesize_offline_conflict.md`
