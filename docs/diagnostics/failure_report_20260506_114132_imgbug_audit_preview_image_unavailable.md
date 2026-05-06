# High-Compliance Diagnostic Report: Audit Preview Image Unavailable

## 1. Description of the Anomaly
When a user completes an audit and attaches a photo, the photo is successfully added locally. However, when viewing the completed audit preview later, the image shows an "Image unavailable" error placeholder. The local device path is being saved directly to the database instead of a remote server URL, which causes `AppNetworkImage` to fail when it cannot locate the local file (e.g. on a different device or if the cache is cleared).

## 2. Hypothesis Generation
- **Hypothesis 1:** The `AppNetworkImage` widget is failing to parse the URL correctly.
- **Hypothesis 2:** The backend is failing to process the uploaded photo and returns an invalid path.
- **Hypothesis 3:** The `PhotoQueueService` is successfully uploading the photo but failing to patch the `Answer` row on the server.
- **Hypothesis 4:** The photos are never actually enqueued into the local outbox during submission, bypassing the `PhotoQueueService` entirely.

## 3. Evidence Gathering & Testing
- **Checked `audit_manager_submit.dart`:** The `_submitAuditLogic` constructs `PendingAnswersCompanion` but never constructs `PendingPhotosCompanion` for any attached photos.
- **Checked `outbox_dao.dart`:** `insertSubmissionWithAnswers` only accepted submissions and answers. `PendingPhotosCompanion` is only used elsewhere (like Action Plans).
- **Checked `PhotoQueueService`:** It queries `_outbox.getPhotosForSubmission(submissionId)` to find pending photos. Since none were ever inserted, the queue is always empty.
- **Result:** Hypothesis 4 is confirmed. Because the photo is never uploaded, the initial local path `C:\...` sent in the submission payload is blindly saved by the backend in the `Answer` table. The UI later tries to load this local path from the server's response.

## 4. Root Cause Analysis
The offline-first audit submission logic failed to persist the attached photo references into the `PendingPhotos` table. Consequently, `PhotoQueueService` never discovered the photos, bypassing the upload and server patching phase. The backend therefore retained the temporary local file path submitted with the original answer payload.

## 5. Resolution Plan
1. **Database DAO Update:** Modify `OutboxDao.insertSubmissionWithAnswers` to accept a `List<PendingPhotosCompanion>` and insert them within the same atomic batch.
2. **Audit Manager Update:** Update `audit_manager_submit.dart` to scan for answers with a local `photoUrl`. For each matching answer, generate a `PendingPhotosCompanion` linked to that specific answer ID.
3. **Persist and Upload:** Pass the generated photo companions to `insertSubmissionWithAnswers`. `SyncEngine` and `PhotoQueueService` will now correctly pick them up and upload them to the server, which will patch the answer row with the real remote URL.

## 6. Implementation Status
- **Status:** **RESOLVED**
- **Changes applied:**
  - `lib/_shared/database/dao/outbox_dao.dart` updated.
  - `lib/features/audit/manager/audit_manager_submit.dart` updated.
- Tests and formatting passed successfully.
