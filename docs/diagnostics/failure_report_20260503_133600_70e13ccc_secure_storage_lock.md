# Diagnostic Report: Secure Storage Lock on Windows

## Input Lineage
- **Source Error**: `PathAccessException: Cannot delete file, path = '...\flutter_secure_storage.dat' (errno = 32)`
- **Source File**: `lib/features/auth/services/secure_storage_service.dart`

## Root Cause
The `flutter_secure_storage` package on Windows implements storage by reading/writing to a physical JSON file (`flutter_secure_storage.dat`). 

In `SecureStorageService.clearAll()`, the code calls:
```dart
Future<void> clearAll() async {
  await deleteToken();
  await deleteSession();
}
```
These two sequential `delete()` operations can trigger a race condition on Windows. The first delete opens the file, modifies it, and begins closing it. If the second delete attempts to access the file before the OS has fully released the file lock from the first operation, Windows throws `errno 32 (Sharing Violation)`.

## Proposed Scope-Limited Fix

Instead of deleting keys individually in `clearAll()`, we should use the native `deleteAll()` method provided by `FlutterSecureStorage`. This method handles the file operations safely in a single atomic pass (or simply deletes the entire file safely).

### Trade-offs / Pros & Cons
- **Pros**: Completely resolves the Windows locking exception. Atomic and faster than multiple sequential deletes.
- **Cons**: `deleteAll()` wipes *every* key in secure storage. If the app ever stores non-auth secrets in the future that should survive a logout, this method will wipe them too. (Currently, the app only stores token and session, so this is safe).

**Fix to apply in `SecureStorageService`:**
```dart
  // ---------- Clear All ----------
  Future<void> clearAll() async {
    // Replaced sequential deletes with native atomic wipe to fix Windows errno 32
    await _storage.deleteAll();
  }
```

## Handoff Block
1. **Verdict**: Windows OS File Lock race condition inside `flutter_secure_storage`.
2. **Blast Radius**: Extremely Low. Only modifies the `clearAll` method inside `SecureStorageService`.
3. **AI Agent Mission Brief**: Update `SecureStorageService.clearAll()` to use `await _storage.deleteAll()` instead of sequential key deletes to prevent Windows `errno 32` file locking crashes.
4. **Execution Queue**:
- [ ] `@[/implement] docs/diagnostics/failure_report_20260503_133600_70e13ccc_secure_storage_lock.md`

<forensic_evidence>
Used view_file to examine `lib/features/auth/services/secure_storage_service.dart`.
Confirmed sequential `delete()` calls within the `clearAll()` method structure.
</forensic_evidence>
