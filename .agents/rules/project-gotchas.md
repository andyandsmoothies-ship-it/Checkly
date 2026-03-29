---
name: Project Gotchas & Lessons
description: Continuous log of critical project-specific lessons, gotchas, and patterns (including operational and tooling friction).
trigger: always_on
---

# Project Gotchas & Lessons — Checkly

> **AI INSTRUCTION (MANDATORY):** Before writing any code or running any tool, scan this file for gotchas relevant to your current task using the **Trigger when** keywords. Do not rely on memory — read the relevant entry in full.

---

## How to Add a New Gotcha
> Use this exact format. Do NOT use table rows. Place the entry in the correct severity section. Tag `[HYPOTHESIS]` if unverified; strip the tag after 3+ confirmed occurrences.

```markdown
### Gotcha N: [Memorable Short Title] [HYPOTHESIS if unverified]
**Trigger when:** [Comma-separated keywords: e.g., routing, EF Core, Flutter widgets, git, CRLF]
**Problem:** [One sentence — what breaks and why]
**Fix:** [Exact action, command, or code snippet]
**Evidence:** Confirmed [N] time(s) — [brief note on context of confirmation]
```

---

## 🔴 Critical — Agent Tooling & Workflow Violations
> These fire during the agent's own meta-operations (file edits, git, artifact management). Check these FIRST before operating any tool.

### Gotcha 20: Artifact Amnesia — Checkbox ≠ File Exists on Disk
**Trigger when:** Completing any phase, marking task.md checkboxes, running git commit
**Problem:** Marking `[x]` in `task.md` does NOT prove the file was physically created on disk.
**Fix:** Before any commit, run `list_dir` on the brain conversation directory and confirm every `[NEW]` artifact appears in the listing. If absent → create it before continuing.
**Evidence:** Confirmed 3+ times.

### Gotcha 21: PowerShell Cannot Use `&&` for Command Chaining
**Trigger when:** Running git commands, chaining terminal commands
**Problem:** `&&` is invalid in PowerShell — the command silently fails with a `ParserError`.
**Fix:** `cmd /c git add -A ; git commit -m "..."` — chain with `;` inside one `cmd /c` call. See GEMINI.md §8.
**Evidence:** Confirmed 5+ times.

### Gotcha 8-git: `git add` with Individual File Paths Hangs Indefinitely
**Trigger when:** Staging files for commit, constructing git add commands
**Problem:** Long per-file `git add` argument lists hang the process waiting for EOF — zombie processes persist for hours.
**Fix:** Always use `git add -A`. Never list individual file paths.
**Evidence:** Confirmed — 20+ hour hanging processes observed.

### Gotcha 25: `grep_search` Treats Pipes `|` as Literals Without IsRegex
**Trigger when:** Using `grep_search` to find multiple concepts separated by `|`
**Problem:** A query like `fl_chart|flutter_map` with `IsRegex: false` searches for the literal text containing the pipe character, silently returning 0 results (false negative).
**Fix:** Always set `IsRegex: true` when using `|` or regex metacharacters in `grep_search`.
**Evidence:** Confirmed 1x — Resulted in falsely classifying 3 critical packages as completely unused and breaking the build upon removal.

### Gotcha 18: CRLF/LF Mismatch — grep_search AND replace Tools Silently Fail
**Trigger when:** Using `replace_file_content`, `multi_replace_file_content`, OR `grep_search` on any `.cs`, `.dart`, or `.md` file in this project
**Problem:** CRLF-encoded files cause two distinct failure modes: (1) `replace_file_content` fails with "target content not found", and (2) `grep_search` returns **no results** even when the pattern physically exists in the file. Both are silent — no error is raised, making false negatives indistinguishable from true negatives.
**Fix:** Always fall back to `view_file` for spot-checks when `grep_search` produces suspiciously empty results. For EF Core specifically: if `grep_search` finds no `HasFilter`/`HasIndex` in `AppDbContext.cs` but the `AppDbContextModelSnapshot.cs` shows those indexes, the fluent config IS present — the snapshot is auto-generated FROM the fluent config and cannot diverge.
**Evidence:** Confirmed 4+ times — CRLF mismatch in replace tools (3×); `grep_search` false negative on `HasFilter`/`HasIndex` in `AppDbContext.cs` during `/verify` (1×, 2026-03-29).

### Gotcha 23: `multi_replace_file_content` Fails ALL Chunks on Any LF/CRLF Mismatch
**Trigger when:** Using `multi_replace_file_content` with multiple chunks
**Problem:** One mismatched chunk fails the entire call silently — no indication of which chunk caused it.
**Fix:** If multi-replace fails, switch to single-chunk `replace_file_content` per edit.
**Evidence:** Confirmed 2+ times. Related to Gotcha 18.

### Gotcha 16: Pivot Immediately on Failing Tools — Do Not Force-Retry
**Trigger when:** Any tool call errors, hangs, or produces unexpected output
**Problem:** Retrying the same failing tool with identical parameters burns context with no progress.
**Fix:** On any tool failure, immediately use the simplest alternative. Add a new gotcha if the constraint isn't documented.
**Evidence:** Confirmed — recurring operational pattern.

### Gotcha 24: Background `git commit` on Windows Is Slow — Not Hung
**Trigger when:** Running `git commit` as a background command, checking command_status, declaring a commit "hung"
**Problem:** `git commit` on this Windows environment completes quickly but the background runner can show `Status: RUNNING` for up to ~60 seconds with no output. Checking at 20–30s and seeing no output is **normal** — not a hang. Prematurely declaring it hung causes false "Commit pending" warnings in walkthroughs, confusing the user.
**Fix:** After `git commit`, wait **1 minute** (`WaitDurationSeconds: 60`) before concluding it is hung. If still RUNNING at 60s → run `git log --oneline -1` to check if it silently succeeded. Only declare a true hang if the log shows no new commit after 60s.
**Evidence:** Confirmed 2 times — commit completed in seconds but `WaitDurationSeconds: 180` caused unnecessary 3-minute stall; screenshot confirmed instant completion.

### Gotcha 26: Cost-Aware Tool Tooling — Dynamic Terminal Loops
**Trigger when:** Running any background terminal command (git, flutter, dotnet)
**Problem:** Dynamic execution increases system-level overhead. Running terminal commands without explicit termination conditions causes infinite hanging processes that burn context and stall workflows.
**Fix:** Never run a terminal command without understanding its termination condition. If a command runs longer than 60 seconds (like linting or git staging), use `command_status`, evaluate if it's deadlocked expecting user input, and abort/kill it immediately if it is. Always use explicit timeouts or non-interactive flags.
**Evidence:** Confirmed — 41+ hour hanging `git add` process observed.

---

## 🔴 Critical — Code Architecture (Build-Breaking or Silent Data Corruption)
> These cause broken builds or silent data bugs that survive testing. Check before touching any backend, routing, or sync code.

### Gotcha 3: Route Registration Order — Specific Before Catch-All
**Trigger when:** Adding or modifying ASP.NET Core routes, registering new endpoints
**Problem:** A catch-all route (e.g., `/{id}`) registered before a specific route swallows the request and tries to parse the path segment as a GUID.
**Fix:** Always register specific named routes BEFORE parameterized/catch-all routes in `*Endpoints.cs`.
**Evidence:** Confirmed — caused a production routing failure.

### Gotcha 4: Every Column Needs Explicit `HasColumnName` in AppDbContext
**Trigger when:** Adding properties to any EF Core entity, running migrations
**Problem:** EF will NOT auto-map `ScoringMode` → `scoring_mode`; missing `HasColumnName` causes silent column mismatches.
**Fix:** Add `HasColumnName("snake_case_name")` in `AppDbContext` for every new entity property before migrating.
**Evidence:** Confirmed — silent data bug that surfaces at query time.

### Gotcha 6: New DTO Fields Must Flow Through All 6 Sync Pipeline Steps
**Trigger when:** Adding any field to Template or Submission entity/DTO
**Problem:** Missing any one of 6 steps causes the field to silently drop during offline sync with a green build.
**Fix:** Update in order: (1) Entity, (2) DbContext mapping, (3) Server DTO, (4) all endpoint projections, (5) sync endpoint projection, (6) Flutter DTO + `fromJson`.
**Evidence:** Confirmed 3+ times.

### Gotcha 7: Snapshot Fields Need Dual Writes — Create AND Finalize
**Trigger when:** Adding denormalized snapshot fields to Submission
**Problem:** Writing only in `CreateSubmission` OR `FinalizeSubmission` leaves the field null for one of the two submission flows.
**Fix:** Always write new snapshot fields in BOTH `CreateSubmission` AND `FinalizeSubmission`.
**Evidence:** Confirmed — caused null snapshots in production flows.

### Gotcha 14: Drift OOM — Every DAO Query Must Be Bounded
**Trigger when:** Writing or modifying `*_queries.dart`, `*_manager.dart`, `*_dao.dart`
**Problem:** Unbounded `.select().get()` loads an entire table into memory — an OOM violation at scale.
**Fix:** Every DAO query MUST use (1) `selectOnly + count()/avg()`, (2) `..limit(n)`, or (3) a comment justifying the bounded result. Use `customSelect` raw SQL for `GROUP BY ... HAVING AVG()` — Drift 2.x has no `.having()`.
**Evidence:** Confirmed — enforced architectural invariant.

### Gotcha 15: Navigation from Outside ShellRoute Must Restore Shell First
**Trigger when:** Navigating from Wizard, onboarding, or any page outside the ShellRoute
**Problem:** `context.go('/route')` from outside a ShellRoute renders the target without bottom nav or back button.
**Fix:** `final router = GoRouter.of(context); router.go('/shell-root'); Future.microtask(() => router.push('/target/$id'));` — capture `router` before the microtask to satisfy `use_build_context_synchronously`.
**Evidence:** Confirmed — caused missing shell navigation in Wizard flow.

---

## 🟡 Important — Domain Logic (Compile-Safe but Behaviorally Incorrect)
> These produce green builds but wrong runtime behavior. Check before designing any feature that touches scoring, templates, or testing.

### Gotcha 5: Survey Mode = null TotalScore — Filter Before Averaging
**Trigger when:** Writing analytics queries, averaging scores, building score reports
**Problem:** Survey submissions have `TotalScore = null` by design — averaging without filtering causes division errors.
**Fix:** Add `WHERE scoring_mode != 'survey'` or `WHERE total_score IS NOT NULL` to every score aggregation query.
**Evidence:** Confirmed.

### Gotcha 8: SectionScores is JSONB — Cannot Use EF GroupBy
**Trigger when:** Querying `Submission.SectionScores`, writing section-level analytics
**Problem:** EF cannot translate `GroupBy` on dynamic jsonb keys — it will fail at runtime.
**Fix:** Load the jsonb strings and parse in C#. Use a GIN index (`jsonb_path_ops`) for future raw SQL.
**Evidence:** Confirmed — architectural constraint.

### Gotcha 9: EF Migration Generator Captures ALL Pending Model Changes
**Trigger when:** Running `dotnet ef migrations add`
**Problem:** The generator bundles ALL unmigrated DbContext changes, not just the intended one.
**Fix:** Review the generated migration immediately — remove unrelated changes or split into separate migrations.
**Evidence:** Confirmed — multiple unintended bundling incidents.

### Gotcha 11: Non-Scored Input Types Must Be Excluded from Points Logic
**Trigger when:** Checking `pointsWeight`, building scoring UI, adding criterion badges
**Problem:** `text`, `single_choice`, and `multi_choice` are data-collection only — touching `pointsWeight` without an `inputType` check shows incorrect points for these types.
**Fix:** Always check `inputType` before rendering or computing `pointsWeight`.
**Evidence:** Confirmed — pattern appeared in 4 separate locations.

### Gotcha 12: Every New Handler Requires at Least 2 Tests Before Handoff
**Trigger when:** Completing any new endpoint handler, declaring a slice done
**Problem:** A green existing test suite does NOT cover new handler behavior.
**Fix:** Every new handler needs: (1) happy-path test (200/201/204) and (2) primary error-path test (404/403/409/400). Applies to Track B1 slices.
**Evidence:** Confirmed — `GetStore.cs`, `DeleteArea.cs` shipped untested.

### Gotcha 19: Sub-sections Are ALLOWLIST-Only — Not a Blocklist
**Trigger when:** Implementing sub-section logic, configuring scoring mode constraints
**Problem:** AI agents hallucinate sub-section restrictions as a blocklist — sub-sections are ALLOWLIST-only.
**Fix:** `mode IN ('penalty', 'accumulation', null)` → allowed. All other modes → unconditionally forbidden.
**Evidence:** Confirmed — hallucinated as a blocklist multiple times.

---

## 🟢 Reference — UI/UX Patterns (User-Visible Bugs)
> These cause visible layout or interaction failures. Check when building Flutter UI, especially within the Shell or Wizard context.

### Gotcha 1: Nested Scaffold FAB Renders Behind Bottom Nav Bar
**Trigger when:** Adding `floatingActionButton` to any child page inside `_MainShell`
**Problem:** `_MainShell` uses `extendBody: true` with a 96px nav bar — an inner Scaffold FAB renders behind it invisibly.
**Fix:** Wrap the FAB with `Padding(padding: EdgeInsets.only(bottom: 80))`.
**Evidence:** Confirmed — invisible FABs across multiple pages.

### Gotcha 2: FAB Inside PopupMenuButton Absorbs Tap Events
**Trigger when:** Building menus triggered from a FAB
**Problem:** `FloatingActionButton` inside `PopupMenuButton.child` — the FAB's InkResponse absorbs all taps, the menu never opens.
**Fix:** Call `showMenu()` programmatically from the FAB's `onPressed` instead.
**Evidence:** Confirmed.

### Gotcha 10: Bottom Nav Label Must Be Template-Agnostic
**Trigger when:** Making bottom nav tab labels context-sensitive or mode-specific
**Problem:** The user has no template context when the nav bar is visible, so mode-specific labels are always wrong.
**Fix:** Use a generic label (e.g., `'ACTIVITY'`). Never use `'AUDIT'` or `'SURVEY'`.
**Evidence:** Confirmed — architectural constraint.

### Gotcha 13: AuditSectionCard Renders ONE Section at a Time — Do Not Optimize
**Trigger when:** Modifying `audit_form_page.dart`, attempting to optimize section rendering
**Problem:** Replacing `template.groups[_currentSection]` with `Visibility` or `IndexedStack` builds all sections simultaneously, destroying the deliberate single-section performance model.
**Fix:** Do not change this pattern — `setState` on `_currentSection` is the intentional swap-render mechanism.
**Evidence:** Confirmed — intentional perf design, not an accident.

### Gotcha 17: GlobalKey Inline in `build()` Destroys Focus and BuildContext
**Trigger when:** Assigning keys to widgets inside `build()` or helper methods
**Problem:** `?? GlobalKey()` inline creates a new key on every rebuild, causing Flutter to unmount/remount the element — breaks TextField focus and crashes `MediaQuery.of(context)`.
**Fix:** Use `ObjectKey(model)` tied to the stable data object. Never inline `GlobalKey()` in `build()`.
**Evidence:** Confirmed — caused 1-char typing regression and null crash.

### Gotcha 22: Dart Lint: No Leading Underscores on Local Variables
**Trigger when:** Writing Dart local variables inside functions, closures, or IIFE callbacks
**Problem:** `no_leading_underscores_for_local_identifiers` lint fires on `_` prefixed local variables — `_` is class-private only.
**Fix:** Use unprefixed local names (`final showCcp`, not `final _showCcp`).
**Evidence:** Confirmed — frequent second-pass lint fix in `StatefulBuilder` callbacks.
