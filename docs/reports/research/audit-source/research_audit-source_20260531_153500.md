---
conversation_id: dcbfac81-a3e9-4fad-af42-bc281b403b75
created_at: 2026-05-31T15:35:00+07:00
topic: audit-source-v2
type: research
status: VIABLE
---

# Research: Smart Audit & Template Source Engine V2 — Proactive Quality Safeguards

## [ORIGIN_IDEA]

> Improve the mobile Audit Execution interface with simple, high-value safeguards (running score HUD and strict/lax geofence validation) to prevent errors and record coordinates.

---

## 1. Strict vs. Lax Geofencing
This guard runs when the auditor tries to submit the completed audit.

*   **Strict Mode**: Blocks submission if the device is outside the designated radius (e.g. >100m from the store coordinates).
*   **Lax Mode**: Shows a warning banner to the auditor but lets them submit anyway, recording the coordinates and out-of-range flag in the database for boardroom audit logs.

```
               [Submit Audit]
                     │
             Is device in GPS range?
             ├─── Yes ───► [Submit Successfully]
             └─── No
                   │
            Which mode is set?
            ├─── Strict Mode ───► [Block submission] (Auditor must go closer)
            └─── Lax Mode ──────► [Show Warning] ──► [Submit Anyway] ──► [Write to DB: bypassed = true]
```

---

## 2. Technical System Design

### Strict vs. Lax Geofencing
We will extend the `Templates` configuration and the `Submissions` table.

#### Database Schema Extension
```sql
ALTER TABLE templates
ADD COLUMN geofence_mode VARCHAR(20) DEFAULT 'none', -- 'none', 'lax', 'strict'
ADD COLUMN geofence_radius_meters INT DEFAULT 100;

ALTER TABLE submissions
ADD COLUMN submit_latitude DECIMAL(9,6) NULL,
ADD COLUMN submit_longitude DECIMAL(9,6) NULL,
ADD COLUMN is_geofence_bypassed BOOLEAN DEFAULT false,
ADD COLUMN distance_meters_off INT DEFAULT 0;
```

#### Flutter Execution Rules
- The mobile app pulls the `geofence_mode` and `geofence_radius_meters` from the synced template payload.
- Upon clicking "Submit":
  1. The app calculates the distance to the store's GPS coordinates.
  2. **Strict Mode**: If the distance exceeds the radius, display a red blocking dialog.
  3. **Lax Mode**: If the distance exceeds the radius, display a warning dialog. If the auditor clicks "Submit Anyway", the app sets `is_geofence_bypassed = true` and `distance_meters_off = X`.

---

### Real-Time Auditor HUD
A simple, quiet header panel inside the mobile audit screen that recalculates the running score percentage as the auditor answers questions. No flashing alerts.

#### Widget Design
```
┌────────────────────────────────────────────────────────┐
│ HUD: RUNNING COMPLIANCE                                │
│ ┌────────────────────────────────────────────────────┐ │
│ │ Running Score: 84.50%                              │ │
│ └────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────┘
```
- **Live Scoring Calculation**: Recalculates the running score using a debounced 200ms timer to ensure heavy math does not cause UI stutters on older mobile devices.
