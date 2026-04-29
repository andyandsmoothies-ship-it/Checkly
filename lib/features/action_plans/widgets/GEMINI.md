# GEMINI.md — Action Plans Widgets

## Gotcha: `image_picker` params must always include resize constraints

- **Rule:** When adding a new `ImagePicker.pickImage()` call anywhere in the app,
  ALWAYS include `maxWidth: 1280, maxHeight: 1280, imageQuality: 80` unless there
  is an explicit documented product reason not to.
- **Why:** Omitting these params causes full-resolution photos (up to 40MB+) to
  enter the sync queue unchecked, causing bandwidth spikes, potential server
  `413 Payload Too Large` rejections, and Drift database bloat.
- **Canonical bug:** `submit_evidence_sheet.dart` was missing these params (fixed 2026-04-25).
- **Canonical fix pattern:**
  ```dart
  final xfile = await picker.pickImage(
    source: source,
    maxWidth: 1280,
    maxHeight: 1280,
    imageQuality: 80,
  );
  ```
