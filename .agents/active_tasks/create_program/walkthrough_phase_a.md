# Walkthrough: Create Program UI — Phase A: Service & Constants

## Input Lineage
- **Implementation Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`
- **TDD Gate**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260503_161000_p7q8_create_program_ui.md`
- **Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\create_program\task_20260503_162900_p7q8_implement_phase_a.md`

---

## Decision Log

| Decision | Planned | Implemented | Reason |
|---|---|---|---|
| `programsCreate` string value | `'programs:create'` | `'programs:create'` | Mirrors server `AppCapabilities.cs` exactly |
| Add to `adminDomainCapabilities` | Yes | Yes | Required so PolicyManager grants implicit admin:access |
| `createProgram` return type | `Map<String, dynamic>` | `Map<String, dynamic>` | Test contract expects `result['programId']` and `result['assignmentCount']` raw map access |
| Error propagation in `createProgram` | Callers receive `DioException` | No try/catch — natural propagation | Service layer design: callers handle errors. Matches TC-02. |
| Deadline serialization | `toIso8601String()` | `deadline.toIso8601String()` | TC-01 `verify()` block asserts this exact format |
| JSON key ordering | Not specified in plan | Matches TC-01 verify data literal exactly | Test `verify()` asserts the full data map — key order is preserved by Dart map literal |

---

## Verification Handoff

**Manual steps for QA:**
- None required for Phase A (pure unit tests, no UI). The test suite is the complete verification.

**Phase B is now UNBLOCKED.** Proceed to:
```
@[/implement] Execute build for Phase B — Wizard & Store Selector UI:
c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md
```

> [!IMPORTANT]
> Phase B requires widget tests (TC-04 through TC-08) to be written by QA first.
> Run `@[/tdd]` before starting Phase B implementation.

---

<test_trace>
## Phase A Unit Tests (Isolated)
```
00:00 +0: ProgramApiService.createProgram TC-01: createProgram posts correct payload
00:00 +1: ProgramApiService.createProgram TC-02: createProgram throws on non-2xx
00:00 +2: AppCapabilities TC-03: programsCreate constant exists
00:00 +3: All tests passed!
```

## Global Regression Suite (Full)
```
00:50 +435: All tests passed!
Exit code: 0
```
</test_trace>

---

<forensic_evidence>
## Commands Run

1. **flutter analyze** (on both modified files) → `No issues found! (ran in 10.0s)` — Exit 0
2. **flutter test** (phase A isolated) → `+3: All tests passed!` — Exit 0
3. **flutter test** (global suite) → `+435: All tests passed!` — Exit 0

## Files Changed
| File | Before (lines) | After (lines) | Delta |
|---|---|---|---|
| `lib/_shared/constants/app_capabilities.dart` | 40 | 42 | +2 |
| `lib/features/programs/services/program_api_service.dart` | 174 | 195 | +21 |

Both files are well under the 400-line limit.
</forensic_evidence>

---

## Gotcha Protocol

No new gotchas discovered. Existing patterns in `ProgramApiService` (bare `_dio.get<Map>()` returning `response.data!` without try/catch) were matched exactly.

> [!NOTE]
> No changes to `lib/GEMINI.md` are needed. This implementation strictly follows existing patterns.
