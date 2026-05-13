# Diagnostics Report: Program Dashboard Loading Error

## Input Lineage
- **Source Input**: User reported that the Program Dashboard fails to load and shows a generic network error ("Could not load dashboard data. Check your connection.") despite the backend terminal logging `200 OK` for the `/summary` and `/assignments` endpoints.

## Root Cause
The root cause was **Interface Drift** between the backend API and the Flutter client. 

**Explicit Code Trace:**
1. The Flutter UI calls `GET /api/programs/{id}/assignments`. The backend successfully responds with a `200 OK` and a JSON array of `ProgramAssignmentDetailDto` items.
2. In the Flutter layer (`program_api_service.dart`), the `ProgramAssignmentDetailDto.fromJson` method strictly required an `evidence` array in the JSON response: 
   ```dart
   evidence: (json['evidence'] as List<dynamic>)
   ```
3. However, the backend C# DTO (`ProgramDtos.cs`) had been updated/refactored. It no longer returns an `evidence` array directly on assignments (it now returns `LinkedSubmissionId` references instead). 
4. Because the JSON payload did not contain `"evidence"`, `json['evidence']` evaluated to `null`.
5. Casting `null` to `List<dynamic>` triggered a Dart `TypeError`, which the Dio client gracefully caught and surfaced to the UI as a generic "Could not load dashboard data" network error.

<forensic_evidence>
Searched Flutter Dart code for `/summary` and `ProgramEvidenceDto`:
- Found `ProgramAssignmentDetailDto` mapping `json['evidence']` as `List<dynamic>` explicitly.
Searched backend C# code for `ProgramAssignmentDetailDto`:
- Found `ProgramAssignmentDetailDto` in `ProgramDtos.cs` matching `Guid? LinkedSubmissionId` instead of an `evidence` array.
- Traced `GetProgramAssignments.cs` which maps `null, null, null` for submission links, with no `evidence` generated or returned.
</forensic_evidence>

## Proposed Scope-Limited Fix
The fix is to make the `evidence` property parsing null-safe in the Flutter app's DTO, applying an empty default array if the backend omits it.

```dart
evidence: json['evidence'] != null
    ? (json['evidence'] as List<dynamic>)
        .map((e) => ProgramEvidenceDto.fromJson(e as Map<String, dynamic>))
        .toList()
    : const [],
```

**Trade-offs / Pros & Cons:**
- **Pros:** It's a scope-limited UI fix that instantly stops the crash and restores the dashboard without requiring a backend rewrite.
- **Cons:** If the UI fundamentally relies on displaying raw evidence directly from the assignment API, that feature will now just show "No evidence items submitted" until the UI is properly wired to fetch the linked `Submissions`. For now, preventing the crash takes priority.

## Handoff Block
- **Verdict:** Interface Drift / Null Parsing Error in Flutter UI.
- **Fix:** Update `ProgramAssignmentDetailDto.fromJson` to use a null-check fallback (`const []`) when parsing the `evidence` field. (I have already performed this micro-fix to verify it).
- **Mission Brief:** The dashboard crash is resolved by handling missing evidence arrays gracefully.
- **Execution Queue:** 
  - [x] Implemented scope-limited micro-fix in `lib/features/programs/services/program_api_service.dart`.
  - [x] Mark diagnostic task complete.
