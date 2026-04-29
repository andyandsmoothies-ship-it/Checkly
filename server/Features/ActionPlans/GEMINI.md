# GEMINI.md — ActionPlans Feature

> [!WARNING]
> **`[FromServices]` Required for DI Singletons in PUT/POST Handlers**
>
> **Problem:** In Minimal API `PUT`/`POST` handlers with a JSON body already bound to one parameter,
> adding a second class parameter (e.g., `PbacDictionaryCache cache`) may be silently ignored or
> bound from the body instead of DI. The handler executes without DI injection, using an empty/null cache.
>
> **Symptom:** Imperative `cache.GetCapabilities(role)` returns an empty set regardless of what was seeded.
> Gate is bypassed silently — handler returns 200 instead of 403.
>
> **Fix:** Add `[Microsoft.AspNetCore.Mvc.FromServices]` explicitly:
> ```csharp
> public static async Task<IResult> HandleAsync(
>     Guid id,
>     MyRequestDto request,  // body
>     ClaimsPrincipal user,
>     AppDbContext db,
>     [Microsoft.AspNetCore.Mvc.FromServices] PbacDictionaryCache cache,  // ← REQUIRED
>     CancellationToken ct)
> ```
>
> **Rule:** All non-primitive, non-special DI services injected into PUT/POST handlers
> **MUST** be annotated with `[FromServices]` to prevent body-binding ambiguity.
>
> **Status:** Empirically confirmed; tag as architectural constraint.

---

> [!NOTE]
> **IDOR Guard Pattern for Action Plans**
>
> **Rule**: When adding ownership guards to action plan handlers, do NOT use `.Include(p => p.Submission)`.
>
> - `ActionPlan.StoreId` is a **direct scalar field** — sufficient for `store_manager` and `area_manager` scoping without any JOIN.
> - For **auditor-role** scoping, resolve `AuditorId` via a lean projection query:
>   ```csharp
>   var linkedAuditorId = await db.Submissions
>       .AsNoTracking()
>       .Where(s => s.Id == plan.SubmissionId!.Value)
>       .Select(s => s.AuditorId)
>       .FirstOrDefaultAsync(ct);
>   ```
> - Then call: `SubmissionAccessGuard.CanAccessAsync(user, plan.StoreId, areaId: null, linkedAuditorId, db, ct)`
>
> **Status:** Empirically confirmed. Phase 4 PBAC IDOR hardening (4d280646).
