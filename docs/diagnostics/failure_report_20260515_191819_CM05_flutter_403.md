# Diagnostic Report: Flutter 403 on /programs/area-progress

## Input Lineage
- Source Input: Log output from Flutter frontend `[API] ✖ 403 /programs/area-progress`

## Root Cause
The backend server is in a "Stale State". Although the capability seed for `programs:assignments_list` was successfully coded into `Program.cs` in a previous slice, the local backend process (`dotnet run`) has been running for 32+ minutes and has not been restarted. Because database seeding and PBAC cache initialization only occur during application startup, the active server instance does not possess the updated capability mapping, leading to the `403 Forbidden` rejection on the client.

## Explicit Code Trace (Premises + Proof)
1. The Flutter UI successfully made a request to `GET /programs/area-progress`.
2. The endpoint correctly requires the capability `programs:assignments_list`.
3. The codebase contains the correct SQL seed `INSERT INTO role_capabilities (id, role, capability, created_at) VALUES (gen_random_uuid(), 'area_manager', 'programs:assignments_list', now())`.
4. However, observing the user's active processes, `dotnet run` has been running continuously. Therefore, the startup sequence `app.Services.CreateScope() -> db.Database.ExecuteSqlRawAsync(...)` has not executed to persist the new capability into the `role_capabilities` table.

## Proposed Scope-Limited Fix
**Trade-offs / Pros & Cons:**
There are no code changes required. The fix simply involves restarting the active `dotnet run` process and logging out/in on the Flutter app to retrieve a fresh JWT token if necessary.
- **Pros:** Zero code risk. 
- **Cons:** None.

<forensic_evidence>
- Analyzed the active terminal metadata to notice `dotnet run` was executing continuously for 32 minutes.
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict:** The 403 is a side-effect of a stale backend server instance that has not run the latest startup migration/seeding logic.
2. **The Required Fix and Blast Radius:** Restart the `.NET` backend process. No code blast radius.
3. **AI Agent Mission Brief:** The issue requires an infrastructure restart. No code changes are necessary.
4. **Execution Queue:**
   - [ ] No implementation required. User must manually restart `dotnet run`.
