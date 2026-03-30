# Audit Feature Gotchas

- **Gotcha 11: Non-Scored Input Types Must Be Excluded from Points Logic**
  - **Problem:** `text`, `single_choice`, etc. are data-collection only. Touching `pointsWeight` for these types shows incorrect points.
  - **Fix:** Always check `inputType` before rendering or computing `pointsWeight`.

- **Gotcha 13: AuditSectionCard Renders ONE Section at a Time — Do Not Optimize**
  - **Problem:** Replacing the active section rendering mechanism with `IndexedStack` builds all sections simultaneously, destroying the deliberate single-section performance model.
  - **Fix:** Do not change this pattern — `setState` on `_currentSection` is the intentional swap-render mechanism.

- **Gotcha 19: Sub-sections Are ALLOWLIST-Only — Not a Blocklist**
  - **Problem:** AI agents hallucinate sub-section restrictions as a blocklist.
  - **Fix:** `mode IN ('penalty', 'accumulation', null)` → allowed. All other modes → unconditionally forbidden.
