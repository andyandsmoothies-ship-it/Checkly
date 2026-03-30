# Submission Overrides & Gotchas

- **Gotcha 7: Snapshot Fields Need Dual Writes — Create AND Finalize**
  - **Problem:** Writing only in `CreateSubmission` OR `FinalizeSubmission` leaves the field null for one of the two submission flows.
  - **Fix:** Always write new snapshot fields in BOTH `CreateSubmission` AND `FinalizeSubmission`.
