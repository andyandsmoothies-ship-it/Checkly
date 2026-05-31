---
ConversationID: f625c2e4-0fdd-4c33-9271-185cf5df427c
---

# Task: UX Copywriting & Semantic Tone Replacements - Slice 1

```
      [SLICE 1: AUTH & DASHBOARD COPIES]
                      │
   ┌──────────────────┴──────────────────┐
   ▼                                     ▼
lib/features/auth/                    lib/features/audit/
login_page.dart                       widgets/audit_form_dialogs.dart
   │                                     │
   ▼                                     ▼
[Reset Password / Continue]          [Location / Questions / Syncing]
```

This task covers the systematic implementation of Chunk 1 (Authentication) and Chunk 2 (Dashboard & Audit Execution) copywriting fixes, ensuring high-compliance UX standards.

## 📋 Slice 1 Checklist

- [x] Update `lib/features/auth/pages/login_page.dart`
  - [x] Replace "Forgot Password?" with "Reset Password"
  - [x] Replace "Got it" with "Continue"
- [x] Update `lib/features/audit/widgets/audit_form_dialogs.dart`
  - [x] Replace "Unverified location — ${result.distance}m from store" with descriptive "Location verification failed — you are ${result.distance} meters away from the store."
  - [x] Replace "Location unavailable — submitting without GPS" with outcome-driven "Location services are unavailable. Your audit will be saved without coordinate pinning."
  - [x] Soften "⚠ ${total - answered} criteria unanswered" to "Please note: ${total - answered} questions are still unanswered."
- [x] Update `lib/features/dashboard/pages/widgets/submission_row.dart`
  - [x] Replace "This audit is syncing. Please wait a moment." with human-centric "We are saving your audit. Please wait a moment."
  - [x] Soften void alert "This will permanently void..." to "Are you sure you want to void..."
- [x] Update `lib/features/audit/pages/widgets/history_list_view.dart`
  - [x] Replace "This audit is syncing. Please wait a moment." with human-centric "We are saving your audit. Please wait a moment."
  - [x] Soften void alert "This will permanently void..." to "Are you sure you want to void..."
- [x] Verify that the application compiles and passes all unit and widget tests:
  - [x] Run `rtk flutter test` on `test/features/` and verify success.
