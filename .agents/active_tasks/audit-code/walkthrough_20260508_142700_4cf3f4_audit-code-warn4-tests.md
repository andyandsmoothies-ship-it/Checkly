# Walkthrough: TDD TemplateManager and AnalyticsManager
## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\audit-code\task_20260508_191800_4cf3f41a_audit-code-verify.md`

## Overview
This walkthrough covers the completion of WARN-4 (Manager Test Coverage) from the dynamic UI audit. Two major manager classes that previously had zero test coverage now have robust unit test suites.

### 1. TemplateManager
- **File**: `test/features/templates/manager/template_manager_test.dart`
- **Focus**: Evaluates cache-first reading logic, offline graceful fallback strategies, API connectivity fallback, and atomic UI updates following API mutations.
- **Setup**: Mocks the `TemplateApiService`, `TemplateDao`, and registers a mock `DatabaseService` into the `GetIt` container. Uses `TestWidgetsFlutterBinding.ensureInitialized()` to allow the manager to use the `SchedulerBinding` without crashing.

### 2. AnalyticsManager
- **File**: `test/features/analytics/manager/analytics_manager_test.dart`
- **Focus**: Tests complex KPI computations, dataset filters, and correct logic based on queried Drift objects.
- **Setup**: Mocks the real SQL schema by initializing `AppDatabase.forTesting(NativeDatabase.memory())`. Seeds data into `cachedTemplates`, `cachedStores`, `cachedSubmissions`, and `cachedActionPlans`.

## Decision Log
- Decided to use `GetIt` inside tests for `TemplateManager` instead of rewriting constructor to properly inject.
- Decided to use an in-memory Drift instance `NativeDatabase.memory()` for `AnalyticsManager` to avoid complex DAO mocking.

## Verification Handoff
Tests have been executed and verified locally. Ready for Builder.

<test_trace>
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/analytics/manager/analytics_manager_test.dart
00:00 +0: AnalyticsManager computes basic KPIs from empty DB
00:00 +1: AnalyticsManager computes KPIs accurately from populated DB
00:00 +2: AnalyticsManager applies filters correctly
00:00 +3: All tests passed!
</test_trace>

<forensic_evidence>
Ran `flutter test` for both manager classes successfully.
</forensic_evidence>

## Commands for the Builder
To execute the tests:
```bash
flutter test test/features/templates/manager/template_manager_test.dart
flutter test test/features/analytics/manager/analytics_manager_test.dart
```
