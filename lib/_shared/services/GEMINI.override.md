# Sync & Services Gotchas

## Sync Engine (sync_engine.dart)

- **Gotcha: RETRY must await Outbox update.** Any UI action that resets outbox records (e.g. `requeueExhausted`) returns a `Future`. You MUST `await` this future before calling `SyncEngine.requestSync()`. Because SQLite local commits have microsecond latency, falling into a synchronous race condition will cause `requestSync()` to fetch from the DB before the records are marked `pending`, resulting in a silent failure where nothing is sent.
- **Gotcha: SyncEngine batch abort.** Do not use `return` or `break` to exit early when catching a connection error in `requestSync()`. Exiting the event loop kills the entire pending batch. New submissions queued logically behind older failing records will be dropped as collateral damage. ALWAYS use `continue` inside the record-processing loop to attempt every record in the batch.
