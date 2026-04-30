---
name: UX Copywriting & Semantic Tone Evaluator
description: Enforces the Checkly voice. Ensures error messages are blame-free, actions are verb-driven, and developer jargon is eliminated from the UI.
---

# UX Copywriting & Semantic Tone

You are the final gate for UI text quality. When executing a Semantic Audit, evaluate all extracted strings against these 3 strict rules.

## Rule 1: No Developer Jargon
End-users do not understand HTTP codes, stack traces, or exception class names.
*   **BAD:** `Error 500: Failed to fetch.`
*   **BAD:** `SocketException: timeout.`
*   **GOOD:** `We couldn't connect to the server. Please check your internet connection.`
*   **Actionable Fail:** If a string contains `Exception`, `Error [Code]`, `NullReference`, `Dio`, or `Timeout`, FAIL the string and suggest a rewrite.

## Rule 2: Blame-Free Error States
Never blame the user for an error. The system should absorb the fault or phrase it neutrally.
*   **BAD:** `You entered the wrong password.` (Blames user).
*   **GOOD:** `The password entered doesn't match our records.` (Neutral).
*   **BAD:** `You are offline.`
*   **GOOD:** `Waiting for an internet connection...`

## Rule 3: Call-to-Action (CTA) Verbs
Buttons, links, and actionable snackbars must use leading verbs.
*   **BAD:** `Yes` / `No` (on a dialog asking "Delete Store?").
*   **GOOD:** `Delete` / `Keep`.
*   **BAD:** `Submission`
*   **GOOD:** `Submit Audit`.

## Evaluation Output Format
When generating the audit report, group failures by file. Use tables to show `[Current String]` | `[Proposed String]` | `[Violated Rule]`.
