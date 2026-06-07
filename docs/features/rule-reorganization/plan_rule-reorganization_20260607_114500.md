# Plan: Rule Reorganization and Docs Update

This plan outlines how to clean up the root `GEMINI.md` file by moving feature-specific gotchas to their respective subfolder-level `GEMINI.md` files. It also covers updating `DATABASE_SCHEMA.md` in `docs/project/` to reflect that the `bod_report_snapshots` table has been dropped.

## Reorganization Architecture

```
[GEMINI.md (Root)]
   |
   +---> Keep Project-Wide Rules:
   |        - Terminology Map (Audit vs Submission)
   |        - The 7 Sync Steps (PBAC & Data Sync)
   |        - Orphaned ATDD Stubs (fail(...))
   |        - Hybrid Entity-Driven UI (HATEOAS)
   |        - Silent DTO Contract Drift
   |        - Linter Rule Drift & HTTP 422 Mapping
   |
   +---> Move Scoped Gotchas to Nearest Folders:
            |
            v
   [lib/features/admin/GEMINI.md]
            - Add AM Store Assignments Gotcha (Explicit Empty Array)
            |
            v
   [lib/features/analytics/GEMINI.md] (New File)
            - Add Live Boardroom Analytics Gotcha (No Caching/Polling)
            - Add BOD Section Scores Key Mismatch Gotcha
            |
            v
   [lib/features/programs/GEMINI.md] (New File)
            - Add Programs Module Sync Steps Gotcha
            |
            v
   [lib/features/templates/GEMINI.md]
            - Add TemplateDto/TemplateTreeDto Optional Params Gotcha
            |
            v
   [server/Common/Scoring/GEMINI.md]
            - Add Nesting Depth Constraints Gotcha
            - Add Progressive Repeat Decimal Overflow Safeguards Gotcha
```

## Proposed Changes

### 1. Root `GEMINI.md`
- Remove the following gotchas from Section 3:
  - Programs Module Sync Steps (moves to `lib/features/programs/GEMINI.md`)
  - Live Area Boardroom Analytics (No Caching/Polling) (moves to `lib/features/analytics/GEMINI.md`)
  - BOD Section Scores Key Mismatch (moves to `lib/features/analytics/GEMINI.md`)
  - Nesting Depth Constraints (moves to `server/Common/Scoring/GEMINI.md`)
  - Progressive Repeat Decimal Overflow Safeguards (moves to `server/Common/Scoring/GEMINI.md`)
  - TemplateDto and TemplateTreeDto optional params (moves to `lib/features/templates/GEMINI.md`)
  - Clearing Area Manager Store Assignments (Explicit Empty Array) (moves to `lib/features/admin/GEMINI.md`)

### 2. `lib/features/admin/GEMINI.md`
- Append `Gotcha E: Clearing Area Manager Store Assignments (Explicit Empty Array)` to the end.

### 3. `lib/features/analytics/GEMINI.md` (New File)
- Create and add gotchas:
  - `Gotcha AN-01: Live Area Boardroom Analytics (No Caching/Polling)`
  - `Gotcha AN-02: BOD Section Scores Key Mismatch`

### 4. `lib/features/programs/GEMINI.md` (New File)
- Create and add gotcha:
  - `Gotcha P-01: Programs Module Sync Steps`

### 5. `lib/features/templates/GEMINI.md`
- Append `Gotcha T-03: TemplateDto and TemplateTreeDto Optional Parameters` to the end.

### 6. `server/Common/Scoring/GEMINI.md`
- Append gotchas:
  - `Nesting Depth Constraints`
  - `Progressive Repeat Decimal Overflow Safeguards`

### 7. `docs/project/DATABASE_SCHEMA.md`
- Update the total table count from 31 to 30.
- Update the Business Domain tables count from 23 to 22 in the overview.
- Remove the subsection detailing the `bod_report_snapshots` table.

## Verification Strategy
- Perform a visual and compilation check to ensure all files are in their correct locations and well-formed.
