# Sync & Services Gotchas

## Sync Engine (sync_engine.dart)

- **Gotcha: RETRY must await Outbox update.** Any UI action that resets outbox records (e.g. `requeueExhausted`) returns a `Future`. You MUST `await` this future before calling `SyncEngine.requestSync()`. Because SQLite local commits have microsecond latency, falling into a synchronous race condition will cause `requestSync()` to fetch from the DB before the records are marked `pending`, resulting in a silent failure where nothing is sent.
- **Gotcha: SyncEngine batch abort.** Do not use `return` or `break` to exit early when catching a connection error in `requestSync()`. Exiting the event loop kills the entire pending batch. New submissions queued logically behind older failing records will be dropped as collateral damage. ALWAYS use `continue` inside the record-processing loop to attempt every record in the batch.

## Scoring Engine (scoring_engine.dart)

- **Gotcha 20: Denominator = criteria weight sum, NOT sub.maxPoints.** `sectionBefore` must accumulate the actual sum of `c.pointsWeight` for each criterion in a subsection. Using `sub.maxPoints` was the old bug that caused engine drift from the server. `sub.maxPoints` is ONLY a deduction cap. If you change `sectionBefore` logic, validate with V11 in `scoring_test_vectors.json` (expected: 44.44%).
- **Gotcha 21: Purity Gate type list must stay in sync with server.** Measurable types: `{pass_fail, numeric, scale, single_choice, multi_choice}`. If any measurable criterion has `pointsWeight <= 0`, the engine returns `null`. Update both `scoring_engine.dart::_kMeasurableTypes` AND `ScoringVerifier.cs::MeasurableTypes` together — never one without the other. Survey mode bypasses the gate entirely.
