# ADR-001: Device-Bound Draft Scope (The "Trash Can" Strategy)

**Date:** 2026-04-06
**Status:** Accepted
**Context:** Offline-First Data Entry Resilience

## Context
The Checkly mobile app requires robust offline capability for auditors inspecting deep basements, freezers, and construction sites with zero connectivity. We achieved "crash immunity" by committing a serialized JSON blob to local SQLite every 3 seconds. 

However, we face a critical NFR boundary regarding cross-device "Enterprise" disaster recovery (e.g., uploading the unvalidated partial JSON draft to the cloud so an auditor can resume an audit on another device if their phone breaks). Submitting unvalidated data breaks our backend Minimal API transactional logic, requiring a huge "Hybrid Blob Sync" Epic.

## Decision
Drafts are **permanently device-scoped**. 
Cloud sync for partial drafts is explicitly deferred until post-Series A. 
We officially accept the risk of device-bound data loss if a phone is physically destroyed.

## Consequences
1. **The 14-Day Limit:** Drafts physically expire after 14 days and are garbage-collected via local background routines (`DraftService`). We accept the anger of users who forget about 3-week-old drafts, as the alternative (Schema Drift crashes) is unacceptable.
2. **UX Transparency:** To mitigate the lack of cloud sync, we rely purely on UI copy. The `AuditFormPage`'s Resume Dialog MUST explicitly state: *"This draft is saved only on this device. It will expire in 14 days."* Communicating the constraint acts as the feature.
3. **Firm Boundary:** Future engineers are prohibited from "quickly building" a `/api/drafts` backend route without initiating a complete architectural review of the distributed schema versioning requirements.
