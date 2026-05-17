# Master UX/UI Evaluation Report: Action Plan Detail (Store Manager)

## 1. Executive Summary
A comprehensive visual, heuristic, and cognitive evaluation was conducted on the Action Plan Detail flow for the Store Manager persona. The baseline implementation provides excellent offline resilience and structure. However, there are notable gaps in **system transparency** (what happens when offline) and **user control** (fixing mistakes). 

This document consolidates all visual bugs, UX friction points, and architectural feature recommendations into a single decision matrix.

---

## 2. Visual & Aesthetic Findings
*These items require minor styling adjustments in Flutter.*

| Issue | Severity | Location | Remediation |
| :--- | :--- | :--- | :--- |
| **Typography System Mismatch** | Minor | `SectionHeader` | The word "Evidence" uses a Serif font (`AppFonts.serifStyle`), breaking the app's sans-serif Material consistency. Switch to `textTheme.titleLarge`. |
| **Low Contrast Labels (Accessibility)** | Major | `InfoRow` | Metadata labels (Criteria, Section, etc.) use `onSurfaceVariant` on a `surfaceContainer` background. This fails WCAG AA standards. Increase opacity or font weight. |
| **Floating Hierarchy** | Minor | `ActionPlanActionBar` | The "Awaiting Auditor Verification" fallback sits in a flat grey box. Add a subtle icon (e.g., hourglass) or a semantic border for a premium feel. |

---

## 3. UX & Interaction Friction
*These items require widget logic or state management updates.*

| Issue | Severity | Location | Remediation |
| :--- | :--- | :--- | :--- |
| **Unsafe Modal Dismissal (Data Loss)** | Critical | `SubmitEvidenceSheet` | The 'Close' button remains enabled while `_isSubmitting` is true. If the background API call fails after closing, typed evidence is lost. **Lock the close button during submission.** |
| **Inability to Remove Photo** | Medium | `SubmitEvidenceSheet` | Once a photo is selected, it cannot be cleared (only replaced). Add an "X" button to allow reverting to a text-only submission. |
| **Unhelpful Validation Message** | Low | `SubmitEvidenceSheet` | The empty note validation simply says "Required". Change to "Please describe the action taken." |

---

## 4. Feature & Architectural Proposals (Filling Mental Gaps)
*These items address deep user confusion and require backend DTO or PBAC logic enhancements.*

### Proposal A: Solving "The Offline Illusion"
- **The Gap:** When submitting offline, the timeline instantly says "Evidence Submitted". The user falsely assumes the auditor has received it.
- **The Solution:** Add a "Syncing..." banner or a dashed-outline/cloud-off icon to the timeline when `plan.syncStatus == 'pending'`. 

### Proposal B: PBAC "Recall Evidence" Capability
- **The Gap:** Once evidence is submitted, it is locked forever. Store Managers cannot fix typos or replace photos if they realize a mistake immediately.
- **The Solution:** Add `ActionPlanActions.recallEvidence` to the backend PBAC logic. If the status is `pending_verify`, project this capability so the UI shows a "Recall Submission" secondary button, returning the plan to `open`.

### Proposal C: Auditor Identity Projection
- **The Gap:** The UI generically states "Awaiting Auditor Verification." It feels robotic and lacks accountability.
- **The Solution:** Project the parent audit's `AuditorName` onto the `ActionPlanDto` from the backend. Update the UI text to: *"Awaiting Verification from [Auditor Name]."*

### Proposal D: Empty State Clarity
- **The Gap:** If the Auditor did not write a Correction Plan, the entire section is hidden. The user doesn't know if the system lost data or if it was intentionally left blank.
- **The Solution:** Never hide the section. If empty, show a muted text block: *"No specific steps prescribed. Please fix the criteria."* 
