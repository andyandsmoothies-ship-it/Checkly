# Task: Secure Storage Architectural Fix
Workflow: /implement | Track: B1

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260509_100912_secure-storage-arch.md`

## Decision Log
- **Proposed**: Add `shared_preferences`, rewrite `ThemeManager` to use it, and strip the theme-backup logic out of `SecureStorageService.clearAll()`.
- **Implemented**: 
  - Added `shared_preferences` dependency to `pubspec.yaml`.
  - Refactored `ThemeManager` to use `SharedPreferencesAsync` to independently manage standard preferences.
  - Simplified `SecureStorageService.clearAll()` to a single `await _storage.deleteAll();` call without any logic to back up the theme, avoiding the `PathAccessException` caused by file locks sequentially backing up data during the logout action.
- **Status**: Implemented successfully.

## Verification Handoff
1. The app compiles.
2. The theme will reset to its default state for existing users, but new changes will persist across app boots cleanly.
3. Logout logic will no longer throw `PathAccessException` (errno 32) on Windows due to file locks on the secure storage files.

## Gotcha Protocol
- None identified.

<test_trace>
All tests passed! (467 tests)
Exit code: 0
</test_trace>

<forensic_evidence>
cmd /c "rtk flutter analyze"
cmd /c "rtk flutter test"
</forensic_evidence>
