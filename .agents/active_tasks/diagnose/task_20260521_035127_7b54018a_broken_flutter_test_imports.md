# Task: Broken Flutter Test Imports after File Splits
Workflow: /diagnose | Track: A

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\verification_20260521_034746_7b54018a_verify_global_audit_remediation.md`

## Phases
- [x] Phase 1: Symptom Isolation
- [x] Phase 2: Skill & Rule Discovery
- [x] Phase 3: Resolution Plan
- [x] Phase 4: Deliverable Handoff

## Phase 1: Formal Reasoning
**Hypothesis 1:** If the function `shellActiveIndexFromLocation` was moved to `shell_tab.dart` during SC-4 split, then adding `import 'shell_tab.dart';` to `app_router_test.dart` will resolve the compiler error.
**Hypothesis 2:** If the function `authRedirect` was moved to `auth_redirect.dart` during SC-3 split, then adding `import 'auth_redirect.dart';` to `app_router_rbac_test.dart` will resolve the compiler error.
**Hypothesis 3:** If the methods are private or renamed in the new files, then importing them won't be enough and we will need to update the test to use the new names or make them public.

## Artifact Inventory
| Status | File Path | Type |
|---|---|---|
| [NEW]  | c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260521_035127_7b54018a_broken_flutter_test_imports.md | Report |
