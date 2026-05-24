# UX Error Messaging & Semantic Tone Architecture

### [ORIGIN_IDEA]
"Apply good error message into my system. It explains what happened and why, provides reassurance, is empathetic, helps the user fix the issue and gives the user a way out."

## <latent_space_scratchpad>
**Debate:** How do we bridge the gap between `ProblemDetails` returned by ASP.NET Core and empathetic, non-technical UI messages in Flutter?
*   Currently, the backend correctly adheres to RFC 9457 `ProblemDetails` (via `GlobalExceptionHandler` and `TypedResults`).
*   However, Flutter is directly using `try { ... } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }`.
*   This violates UX copywriting rules: exposing developer jargon, blaming the user, and providing no actionable "way out".
*   If we make the backend return "empathetic" messages directly, we tightly couple UI concerns to backend API definitions. This breaks separation of concerns and ruins localization.
*   The proper seam is an `ErrorDisplayService` (or mapping layer) in the frontend that takes a structured error (e.g., `DomainException` or `ProblemDetails` parsed from `DioException`) and looks up the correct UX-approved semantic string, optionally adding actionable callbacks (Retry).
</latent_space_scratchpad>

## 1. E2E Workflow Map

**Status Quo (Friction & Jargon):**
1. [Backend] Throws exception or returns `TypedResults.Conflict(new ProblemDetails { Detail = "State conflict." })`.
2. [Network] Returns HTTP 409 / 500 JSON.
3. [Flutter `ApiClient`] Throws `DioException`.
4. [Flutter UI] Catches `e` and calls `ScaffoldMessenger.of(context).showSnackBar(Text(e.toString()))`.
5. [User] Sees: `DioException [bad response]: Http status error [409]` (Panics, confused, no way out).

**Target Architecture (Empathetic & Actionable):**
1. [Backend] Returns `ProblemDetails` with specific `type` or `code` extensions.
2. [Flutter `ApiClient`] Maps `DioException` to a typed `AppError` containing the `code` and `details`.
3. [Flutter UI] Catches `AppError` and delegates to `ErrorDisplayService.show(context, error, onRetry: () => submit())`.
4. [Flutter `ErrorDisplayService`] Maps `error.code` to an empathetic string from an approved dictionary.
5. [User] Sees: `We couldn't save your progress. Please check your connection and try again.` with a `[Retry]` button.

## 2. Strategy Assessment

### Impact Spectrum

| Option | Architecture | Tradeoffs |
|---|---|---|
| **A. Strict Native Fit** | Central `ErrorDisplayService` that maps `ProblemDetails.type` to local empathetic UX copy. | **Pros:** Decouples API from UI copy. Single place to enforce Semantic Tone. Actionable retries.<br>**Cons:** Requires refactoring scattered `ScaffoldMessenger` calls. |
| **B. Pragmatic Balance** | Generic `Dio` Interceptor that overwrites error messages globally. | **Pros:** Fast to implement. No UI refactoring.<br>**Cons:** Loses context. Cannot provide contextual "way out" callbacks (e.g., specific retry actions). |
| **C. Enterprise Overhaul** | Switch entire app to Result/Monad pattern (`fpdart`) pushing errors cleanly to ViewModels. | **Pros:** Pure mathematically safe.<br>**Cons:** Massive rewrite of the entire Flutter codebase. Destroys current velocity. |

### Blind Spots & Limitations
1. **Context Loss in Global Guards:** If we rely solely on global mappings, we might lose the specific context of *why* something failed (e.g., "Failed to load templates" vs "Failed to connect"). The UI must still be able to inject context parameters.
2. **Non-JSON Server Errors:** If NGINX or a firewall fails before ASP.NET Core, it returns HTML, not `ProblemDetails`. The parser must gracefully degrade to a generic network error instead of throwing a parsing exception.
3. **Actionable Callbacks:** SnackBar durations are short. If we provide a `[Retry]` button as a "way out", the user must have enough time to click it. We may need different presentation modes (Dialog vs SnackBar) depending on severity.

### Conflicts with Rules
- **Conflict with `UX Copywriting & Semantic Tone Evaluator`:** The existing codebase massively violates Rule 1 (No Developer Jargon) and Rule 2 (Blame-Free Error States) by pushing raw exceptions to the UI.

## 3. Comparative Decision Matrix

| Criteria | Option A (ErrorDisplayService) | Option B (Interceptor Override) | Option C (Fpdart Monads) |
|---|---|---|---|
| **Empathetic & Blame-Free** | High (UX specific mapping) | Medium (Generic messages) | High |
| **Actionable "Way Out"** | High (Supports contextual callbacks) | Low (No context for retries) | High |
| **Implementation Effort** | Medium (Refactoring) | Low (Drop-in) | High (Massive rewrite) |
| **Architectural Fit** | High (Service Locator / get_it friendly) | Medium | Low |

---

<forensic_evidence>
- `list_dir docs/product` to ensure no overrides.
- `grep_search ScaffoldMessenger|SnackBar|showDialog|catch \(e\)` in `lib/` (Found 243+ raw UI snakbars swallowing exceptions).
- `grep_search ProblemDetails` in `server/` (Confirmed backend uses `TypedResults.Conflict(new ProblemDetails)`).
- Loaded `.agents/skills/ux-copywriting/SKILL.md` to establish constraints.
</forensic_evidence>

## Handoff Block
- **Verdict:** Viable. Option A (Strict Native Fit via Central ErrorService) is the ideal path to guarantee empathetic, actionable error states without coupling UI UX copy to the backend API models.
- **Effort Sizing:** Track A (Moderate). Building the core service and standardizing API client mapping is easy, but migrating all 243+ existing catch blocks across the app will take systematic slicing.
- **AI Agent Mission Brief:** Implement a centralized `AppErrorDisplay` mechanism in Flutter that translates backend `ProblemDetails` and network exceptions into empathetic, blame-free `SnackBar` or Dialog UI. The service must support actionable "way out" callbacks (like Retry).
- **Next Command:** `@[/analyze-feature] docs/product/research_20260510_185700_15a74aa9_good-errors.md`
