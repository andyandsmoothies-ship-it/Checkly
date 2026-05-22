# Task: Registration failed (Forbidden) in dotnet tests
Workflow: /diagnose | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\store_address_required\task_20260521_162700_f3a1b800_qa_verify_slice1.md`
- **Error**: `System.Exception: Registration failed (Forbidden)` in `TestWebApplicationFactory.RegisterUserAsync` line 211

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Artifact Inventory
| Status | File Path | Type |
|--------|-----------|------|
| [DONE] | `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260521_163200_f3a1b800_registration_forbidden.md` | Report |

## Hypotheses
- H1: Bootstrap admin user lost its `users:create` capability after the migration.
- H2: The `RegisterUserAsync` endpoint requires a capability/role that was re-seeded incorrectly.
- H3: The migration backfill set `address_province = 'Unknown'` on the bootstrap admin's store, breaking a related FK constraint used during registration.
- H4: A new migration changed a capability or role seed in `Program.cs` that the test factory depends on.
- H5: The `checkly_test` database did not apply the new migration, so the schema is mismatched.
