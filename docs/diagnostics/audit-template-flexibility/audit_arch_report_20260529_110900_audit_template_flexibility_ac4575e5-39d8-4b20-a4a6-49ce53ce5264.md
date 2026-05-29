<latent_space_scratchpad>
- Reviewing the epic analysis for architectural flaws.
- The dual linter pattern uses a local Dart linter and a C# on-save linter.
- A split-brain issue is possible if the two linters drift in logic.
- A poison pill issue is possible if a massive template causes an OOM during linter parsing or tracking.
- An IDOR issue is possible if the endpoint does not properly verify tenant authorization.
</latent_space_scratchpad>

# Architecture Audit Report: Audit Template Flexibility
**Topic**: Audit Template Flexibility
**ConversationID**: ac4575e5-39d8-4b20-a4a6-49ce53ce5264
**Date**: 2026-05-29
**Pattern**: Advisory Rule Engine + Real-Time Simulator

## The Brutal Interrogation (The 4 Critics)

### Critic 1: The Zombie (Stateless Illusion)
- [x] **Long-Lived Connections**: PASS. The system uses standard stateless REST (`PUT /api/templates/{id}/tree`) and local Debounced timers (800ms) in Dart. No long-lived WebSockets or SSEs.
- [x] **Cache Rebuilds**: PASS. Saving a template tree replaces the JSON/tree representation in DB. There is no evidence of massive N+1 cache invalidations.

### Critic 2: The Split-Brain (State & Sync)
- [x] **Clock Drift**: PASS. No reliance on client-side timestamps for conflict resolution in this flow.
- [ ] **Transactional Fracture**: FAIL (🟡 Brittle). The **Dual Linter Pattern (Shape B2)** duplicates business rules across Dart and C#. This is a classic split-brain setup. If the Dart rule logic drifts from C# rule logic, the Admin will see "No Errors" in the UI, click Publish, and suddenly get slammed with an unexpected HTTP 422 from the server. This breaks trust.

### Critic 3: The 2 AM Landmine (Resilience & Observability)
- [ ] **The Poison Pill**: FAIL (🟡 Brittle). The Epic identifies Duplicate IDs and Nested > 2. But what about a payload with 50,000 criteria? A massive tree could cause high CPU/Memory during `TemplateLinter.Run(tree)` or `db.SaveChangesAsync()`, leading to a Thread Starvation or Out Of Memory (OOM) exception.
- [x] **The Thundering Herd**: PASS. This is an admin-only operation, low concurrency.

### Critic 4: The Brick (Boundary & Exploit Risk)
- [ ] **Contextual Illusion (IDOR)**: FAIL (🔴 Fatal Risk). The Epic states "TemplateBuilderPage is already gated by templates:update". But does the **Backend** `PUT /api/templates/{id}/tree` properly authorize the Admin's tenant/store access against the `id` being modified? A malicious user might craft a PUT request to corrupt another tenant's template.
- [x] **The "Root" Suicide**: PASS. Admin cannot brick their own access via this.

### Critic 5: Cognitive Debt (The Easy Button)
- [x] **Hasty Abstractions**: PASS. The proposed architecture correctly avoids new database tables and state machines, keeping it as a pure function / stateless rule processor.

---

## The Verdict Payload

**Verdict**: 🟡 BRITTLE (with Fatal IDOR risk if untested)

### Actionable Fixes & Trade-offs

1. **Fix 1: Linter Rule Drift Prevention (Split-Brain)**
   - **Fix**: The C# and Dart linters must have identical test matrices. Implement a `ScoringVerifier` cross-platform contract test, or strongly document that any new C# rule *must* have a matching Dart rule. If a 422 is returned, the UI must gracefully display the server's `lintResult.errors` to the user, acting as the ultimate fallback so the user is never stuck on a generic "Save Failed" toast.
   - **Complexity**: Low. Just ensure the `TemplateLinterPanel` can bind to the `lintResult` returned by the HTTP 422 response, not just the local Dart linter.
   - **Trade-offs / Pros & Cons**: Pro: Guarantees the user is never permanently blocked by a UI/Backend rule mismatch. Con: Slightly more UI state management for the HTTP response.

2. **Fix 2: Payload Size Limit (Poison Pill)**
   - **Fix**: The C# endpoint `PUT /api/templates/{id}/tree` MUST enforce a maximum criteria count (e.g., Max 500 nodes) BEFORE running the linter or DB tracking.
   - **Complexity**: Low. A simple `if (request.Groups.Sum(g => g.Criteria.Count) > 500) return BadRequest("Template too large");`
   - **Trade-offs / Pros & Cons**: Pro: Prevents 2AM OOM crashes from malicious/accidental massive payloads. Con: Hard cap on template size.

3. **Fix 3: Backend PBAC/IDOR Enforcement (Brick)**
   - **Fix**: Ensure `SaveTemplateTree.cs` explicitly verifies that the user executing the PUT request has `templates:update` AND belongs to the tenant that owns the `TemplateId`. Do not rely solely on UI routing.
   - **Complexity**: Low. Standard PBAC check in C# MediatR handler.
   - **Trade-offs / Pros & Cons**: Pro: Prevents Cross-Tenant Data Corruption. Con: None.

<forensic_evidence>
- Command Logs:
  - view_file: c:\Users\HP\Documents\GitHub\Checkly\.agents\persona\qa_persona.md
  - view_file: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-flexibility\analysis_epic_20260529_104152_audit_template_flexibility_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md
</forensic_evidence>

## Handoff Block
1. **SRE Verdict**: 🟡 BRITTLE (with Fatal IDOR risk). Persistent path: `C:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\audit-template-flexibility\audit_arch_report_20260529_110900_audit_template_flexibility_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`
2. **2AM Landmines**: 
   - Split-brain dual-linter logic causing unexpected 422s.
   - Poison Pill massive payload (50K criteria) causing OOM crash during DB tracking.
   - Fatal IDOR where admins could bypass UI and corrupt templates of other tenants.
3. **AI Agent Mission Brief**: Review the audit report findings and redesign the Epic to incorporate payload size limits, IDOR protection, and cross-platform linter drift mitigation before generating code.
4. **Next Command**: `/analyze-epic`
