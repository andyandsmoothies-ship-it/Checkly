# PBAC UI - Phase B TDD Test Execution Report

**Execution Date:** 2026-05-16
**Phase:** Phase B - Flutter DTO, Drift Cache, and Offline Transition State
**Status:** 🔴 **RED** (Expected - Pre-implementation)
**Author:** Sentinel (QA)

## Summary
The TDD test suite for Phase B has been written and executed. As expected, all tests fail because the production code (DTOs, Domain models, Drift tables) does not yet implement the PBAC `allowedActions` contract.

## Test Files Added
1. `test/unit/models/action_plan_dto_test.dart`
2. `test/_shared/database/drift_migration_action_plan_allowed_actions_test.dart`

## Contract Requirements Verified (Failing)

### B1: ActionPlanDto JSON Parsing
- 🔴 **FAIL**: `ActionPlanDto` does not have an `allowedActions` field.
- 🔴 **FAIL**: Constructor `ActionPlanDto({ ... })` does not accept `allowedActions`.
- **Requirement**: Add `final List<String>? allowedActions;` to `ActionPlanDto` and map it in `fromJson` / `toJson`.

### B2: Drift Schema `cached_allowed_actions`
- 🔴 **FAIL**: `CachedActionPlans` table lacks `cachedAllowedActions` column.
- **Requirement**: Add `TextColumn get cachedAllowedActions => text().nullable()();` to `CachedActionPlans` in `lib/_shared/database/tables.dart`.

### B3: Schema v28 Migration
- 🔴 **FAIL**: Schema version is currently 27.
- **Requirement**: Bump `schemaVersion => 28` in `lib/_shared/database/app_database.dart` and add `onUpgrade` logic for `cached_allowed_actions`.

### B4: Offline Cache Rehydration
- 🔴 **FAIL**: Manager does not map `cachedAllowedActions` back to `allowedActions` when reading from the database.
- **Requirement**: Update `ActionPlanManager.loadActionPlans()` offline read path.

### B5: Domain Optimistic Transitions
- 🔴 **FAIL**: `ActionPlan` domain methods (`submitEvidence`, `closePlan`, `rejectEvidence`) currently instantiate a new `ActionPlanDto` without an `allowedActions` parameter.
- **Requirement**: Update domain transition methods to explicitly compute and set `allowedActions` for the optimistically returned DTO.

### B6: Offline Pending Entity
- 🔴 **FAIL**: `ActionPlanDto` lacks an `offline()` named constructor.
- 🔴 **FAIL**: `ActionPlanDto` lacks a `syncStatus` field.
- **Requirement**: Implement `ActionPlanDto.offline()` injecting `['view', 'edit', 'delete']` as default `allowedActions`, and add `syncStatus`.

## Next Steps for Builder
The testing suite is locked in. The Builder should now execute Phase B implementation to turn these tests **GREEN**. Do not modify the test assertions; update the production code to satisfy the contracts.
