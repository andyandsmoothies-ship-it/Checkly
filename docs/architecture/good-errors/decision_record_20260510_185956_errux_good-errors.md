# ADR: Error UX Centralized Service

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260510_185700_15a74aa9_good-errors.md`
- `c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260510_184300_r2_errux.md`

## [ORIGIN_IDEA]
> "Apply good error messages into my system. It explains what happened and why, provides reassurance, is empathetic, helps the user fix the issue, and gives the user a way out."

---

<latent_space_scratchpad>
Both research artifacts independently arrived at exactly the same conclusion (Option A = Central ErrorDisplayService). This is a strong convergence signal; the decision is not genuinely contested.

The real tension is NOT between A, B, or C. It is:
1. How deep should the service be? (Just SnackBars, or also Dialogs, bottom sheets?)
2. How do we handle the 243+ existing raw catch blocks? (Big bang migration vs systematic slicing)
3. How do we handle non-ProblemDetails failures (HTML from NGINX, Dio connection errors, Flutter exceptions)?

Research 1 (15a74aa9) is stronger because it explicitly maps the E2E flow from backend ProblemDetails → DioException → AppError typed model → ErrorDisplayService. It names the key risk (Non-JSON server errors like NGINX HTML) and explicitly argues against coupling UX copy to backend.

Research 2 (r2_errux) is broader and more direct. It cites a concrete real offender: `e.response?.data?['message'] ?? 'Failed to create global risk'` in risk_form_sheet.dart. This is the most important forensic evidence because it proves the problem is ALREADY in production, not theoretical.

Synthesis adds value by: combining the explicit E2E model from R1 with the forensic evidence from R2, and resolving the one small genuine difference — R1 proposes a typed `AppError` intermediate model between DioException and the service, while R2 does not. R1's typed model is the right choice because without it the service signature must accept `Object?` which is too loose.

Blast radius: The NEW `ErrorDisplayService` file is trivially small. The LARGE blast radius is the systematic migration of 243+ catch blocks. Must be sliced.
</latent_space_scratchpad>

---

## Normalized Options Summary

| Option | Core Idea |
|---|---|
| **A – Central ErrorDisplayService** | A singleton Flutter service that accepts a `DioException` (or typed `AppError`) + optional retry callback, looks up an empathetic string from a hardcoded dictionary, and renders a SnackBar/Dialog. |
| **B – Local String Constants** | Each widget continues to show its own SnackBar, but developers import a shared constants file for the message strings. No centralized dispatch. |
| **C – Backend-Driven UX Copy** | The ASP.NET backend's `ProblemDetails` includes pre-translated, user-facing empathetic text that Flutter renders directly. |

---

## Red Team Hostile Interrogation

### Attack on Option A (Central ErrorDisplayService)
**Scenario:** The service is called from inside a `BuildContext` that has already been disposed (e.g., user navigates away during an async upload). The `ScaffoldMessenger.of(context)` call throws a `FlutterError: setState() called after dispose()`. Result: The error message itself crashes the app silently, the user sees a frozen screen, and the original error is swallowed.
**Mitigation required:** The service MUST accept a `GlobalKey<ScaffoldMessengerState>` or check `context.mounted` before rendering. Alternatively, decouple the service from BuildContext entirely using a `ScaffoldMessengerState` injected via `get_it`.

### Attack on Option B (Local String Constants)
**Scenario:** A developer is in a rush. They catch the exception, look at the constants file, can't find an exact match, and write `'An error occurred'`. Six months later, 40% of error paths show the same useless generic string. The "way out" button is never added because there's no forcing function to include it.
**Verdict:** This is not a hypothetical. Research 2 found this exact pattern already in `risk_form_sheet.dart`. Option B is already the status quo and is provably broken in production.

### Attack on Option C (Backend-Driven UX Copy)
**Scenario:** The app ships in multiple languages (e.g., Thai + English). The backend now owns UI copy. Every translation update requires a backend deployment, a server restart, and a coordinated mobile app release. The backend team now owns UX strings written by a product copywriter, which they don't understand. A developer pushes `"ProblemDetails { detail: 'FK constraint violated on table users_stores'" }` to production because they forgot to update the UI-facing text. The user sees a raw database error.
**Verdict:** Catastrophic architectural violation. Mixes concerns, destroys localization, and removes the safety net of a frontend translation layer. Eliminated.

---

## Pugh Decision Matrix

**Baseline: Option B** (score = 0)

| NFR Criterion | Weight | Option A | Option B (Baseline) | Option C |
|---|---|---|---|---|
| **Origin Idea Alignment** (Empathy + Way Out) | 3x | +1 ✅ | 0 | -1 ❌ |
| **Actionable "Way Out" (Retry callbacks)** | 2x | +1 ✅ | 0 | -1 ❌ |
| **Enforcement / Forcing Function** | 2x | +1 ✅ | 0 | -1 ❌ |
| **Architectural Fit (get_it, service pattern)** | 1x | +1 ✅ | 0 | -1 ❌ |
| **Implementation Effort** | 1x | -1 ⚠️ | 0 | -1 ❌ |
| **Localization Safety** | 1x | +1 ✅ | 0 | -1 ❌ |
| **Blast Radius on Existing Code** | 1x | -1 ⚠️ (243+ blocks) | 0 | -1 ❌ |

**Weighted Final Score:**

| Option | Weighted Score |
|---|---|
| **Option A** | 3(+1) + 2(+1) + 2(+1) + 1(+1) + 1(-1) + 1(+1) + 1(-1) = **+8** |
| **Option B** | 0 |
| **Option C** | 3(-1) + 2(-1) + 2(-1) + 1(-1) + 1(-1) + 1(-1) + 1(-1) = **-11** |

**🏆 Winner: Option A with +8 vs Baseline.**

---

## Final Verdict

**Option A – Central `ErrorDisplayService`** is the winner. The two research documents independently reach the same conclusion, giving this verdict high confidence.

The core implementation must include:
1. An `AppErrorMapper` utility that centrally parses `Object error, StackTrace? st` into a typed `AppError` record (`{code, message, details, isSafeForUserDisplay, isOptimisticOffline}`).
2. `ErrorDisplayService` registered as a singleton in `get_it`, injected with both a `GlobalKey<ScaffoldMessengerState>` (for transient SnackBars) and `GlobalKey<NavigatorState>` (for blocking Dialogs) to avoid `BuildContext` lifecycle crashes.
3. A debouncing mechanism inside the service to prevent rapid-fire identical SnackBar stacking (e.g. 5 identical timeouts within 500ms).
4. A hardcoded `ErrorDictionary` (`Map<String, String>`) mapping known error codes to empathetic, blame-free strings.
5. A single `show(Object error, StackTrace? st, {VoidCallback? onRetry})` entry point.
6. Offline suppression: If the mapped `AppError` has `isOptimisticOffline = true`, convert the error to a reassuring success message instead of a scary failure.
7. Systematic migration of 243+ catch blocks via sliced implementation phases, supported by an optional `custom_lint` rule to prevent new direct `ScaffoldMessenger` usage.

**Key resolution from synthesis & review:** 
We use an explicit `AppError` intermediate typed model, but we HIDE the parsing from the caller. The `ErrorDisplayService` accepts a raw `Object error` and internally uses `AppErrorMapper` to categorize it. This prevents duplicating parsing logic across 243+ catch blocks. Furthermore, we explicitly support backend validation passthrough (via `isSafeForUserDisplay`) and offline-first safety (via `isOptimisticOffline`).

---

## Executive Business Summary

**In plain English for the Product Owner:**

Right now, when anything fails in the app (a form save, a photo upload, a network timeout), the user sees raw developer text like `"DioException [bad response]: Http status error [409]"`. This is alarming, meaningless to a user, and gives them no idea what to do next. They often just close the app.

The fix creates one central "translator" in the app. When anything fails, the translator intercepts the error, looks it up in a list of approved, friendly phrases, and shows the user a clear message like *"We couldn't save your progress. Check your connection and try again."* with a single **Retry** button. This matches how apps like Google Drive and Notion handle errors.

**Business impact:**
- Fewer support tickets from confused users.
- Reduced user churn caused by opaque failures.
- Consistent, on-brand voice for every error state in the app.

**Operational tradeoff:** There is a one-time migration cost to update 243+ error catch blocks. This must be sliced into phases — the new service is built first, then migration proceeds feature by feature. This is planned work, not a risk.

---

## Risk Assessment
- **H (High): Context-Disposed SnackBar crash.** Mitigated by injecting `GlobalKey<ScaffoldMessengerState>` and `GlobalKey<NavigatorState>` rather than accepting `BuildContext` directly.
- **M (Medium): 243+ catch blocks to migrate.** Mitigated by systematic sliced migration and adding a `custom_lint` rule to prevent regression.
- **L (Low): Non-ProblemDetails responses (NGINX HTML).** Mitigated by the central `AppErrorMapper` falling back to a generic "connection problem" `AppError`.
- **L (Low): SnackBar Spam.** Mitigated by a 500ms debounce in `ErrorDisplayService`.

## Verification Plan
- Confirm `ErrorDisplayService` is instantiable and registers cleanly in `get_it`.
- Unit test: valid ProblemDetails → correct empathetic string.
- Unit test: unknown error code → generic fallback string.
- Integration test: form submit failure → SnackBar with Retry button appears.
- Run `rtk flutter analyze` with 0 issues.

---

## Handoff Block

**Final Verdict:** Option A — Central `ErrorDisplayService` via singleton in `get_it`, with typed `AppError` intermediate model and an `ErrorDictionary`.

**Strict Constraints the next Agent must NOT ignore:**
1. The service MUST NOT accept a raw `BuildContext` parameter. It must use injected `GlobalKey<ScaffoldMessengerState>` and `GlobalKey<NavigatorState>` to support both SnackBars and Dialogs safely.
2. The service signature MUST be `show(Object error, StackTrace? st, {VoidCallback? onRetry})`. Do not force UI widgets to map to `AppError`. Centralize parsing inside an `AppErrorMapper`.
3. The `AppError` intermediate typed record (`code`, `message`, `details`, `isSafeForUserDisplay`, `isOptimisticOffline`) must be defined in `lib/_shared/` so all features can share it.
4. The service MUST implement debouncing (e.g., 500ms) to prevent SnackBar spam on rapid parallel failures.
5. Offline-first errors (`isOptimisticOffline`) MUST suppress the failure and show a reassuring sync message.
6. The `ErrorDictionary` strings MUST comply with the `ux-copywriting` skill. Business validation errors (`isSafeForUserDisplay`) may bypass the dictionary.
7. Migration of 243+ blocks MUST be sliced. The first slice builds the service and configures a `custom_lint` rule to prevent new direct `ScaffoldMessenger` calls.

**Execution Slices:**
- **Slice 1 (Foundation):** Create `AppError`, `AppErrorMapper`, `ErrorDictionary`, and `ErrorDisplayService` (with debouncing). Register keys in `get_it` and update main router. Add `custom_lint` rule.
- **Slice 2 (Adoption):** Refactor Admin page catch blocks (highest-traffic).
- **Slice 3 (Adoption):** Refactor Profile + Auth catch blocks.
- **Slice 4 (Adoption):** Sweep remaining features.

**Requirements Alignment Check:** No existing `requirements.md` is contradicted. This is a cross-cutting infrastructure concern, not a new user flow.

**AI Agent Mission Brief:** Build a centralized `ErrorDisplayService` singleton in Flutter using `get_it`. It accepts a raw `Object error`, uses an `AppErrorMapper` to categorize it, applies debouncing, looks up an empathetic string from `ErrorDictionary` (or passes through safe business rules), and renders a SnackBar or Dialog using injected GlobalKeys. If the error is an offline-sync trigger, convert it to a success message. Do NOT refactor the 243+ existing catch blocks yet — that is Slices 2–4.

**Next Command:**
`@[/analyze-feature]` Execute analysis for Slice 1 (Foundation): `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_185956_errux_good-errors.md`
