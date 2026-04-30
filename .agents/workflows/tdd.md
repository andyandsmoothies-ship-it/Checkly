---
description: Test-Driven Development (TDD) workflow for the QA Agent (Sentinel) to write unit tests.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /tdd

> [!NOTE]
> This is the **Test-Driven Development (TDD)** workflow. The QA Agent (@Sentinel) uses this to write failing unit tests based on a plan. The Builder Agent (@Forge) should never run this workflow.

## Pre-Flight Setup
- **Task File**: Create a `task_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` document right now using this exact template. Update your progress as you work.
  ```markdown
  # Task: [Test Generation Topic]
  Workflow: /tdd | Track: [A / B1 / B2 / C]

  ## Input Lineage
  - **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`

  ## Phases
  - [ ] Phase 1: Read the Plan
  - [ ] Phase 2: Write Tests (Red Phase)
  - [ ] Phase 3: Check Failures
  - [ ] Phase 4: Handoff
  ## Artifact Inventory
  | Status | File Path | Type |
  | [NEW]  | brain/.../executed_tests_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md | Red Tests |
  | [NEW]  | brain/.../walkthrough_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md | Summary |
  ```

## Phase 1: Read the Plan
- **Your Role**: Act as **Sentinel** (QA Engineer).
- **Read the Plan**: Read the provided `implementation_plan_[...].md`. Make sure you understand the class names and API contracts before you start.
- **Load Testing Skills**: You must load the correct testing skills for the project's tech stack. Look in `.agents/skills/`:
  - **.NET / C# Backend**: Load `testing-strategy` (for xUnit v3, Verify).
  - **React / Frontend**: Load `frontend-testing` (for Jest, React Testing Library).
  - **Flutter / Apps**: Load `mobile-app-testing` (for widget tests).
- **Find Dependencies**: If the plan asks you to mock complex services, check if it gave you exact file paths. If not, use `grep_search` to find the exact import paths.
- **Check Backend & Frontend**: If the plan touches an API route, you must use `grep_search` to check BOTH the backend handler (`server/Features/`) AND the frontend client (`lib/`). Make sure the route, HTTP method, and parameters match on both sides.
- **Check Test Contracts**: Before writing a test, check that every contract in the plan has all required fields. If anything is missing, STOP and ask the user:
  - [ ] **Exact Text** specified? (e.g., the exact string `'SIGN OUT'`)
  - [ ] **State Matrix** defined? (Happy Path + Error State + Empty State)
  - [ ] **Private Method Access** stated? (e.g., `@visibleForTesting`)
  - [ ] **Why it fails** includes a line number?

> **@@SCAN** (1) Did you read the plan? (2) Did you load the correct testing skill? (3) Did you check the test contracts?

## Phase 2: Write Tests (Red Phase)
- **Goal**: Write the test files (like `_test.dart` or `*Tests.cs`).
- **Do Not Change App Code**: You are writing tests, not building the feature. Do not write or change code in the main `lib/` or `server/` folders. **Exception**: You may add `@visibleForTesting` (or `InternalsVisibleTo` in .NET) to a main file just to expose a private method for testing.
- **Do Not Copy Logic**: Never copy production logic into a test file just to test it. Expose the real method and test that instead.
- **Do Not Fix Old Code**: For older code, do not change working production code to make your test pass. Write tests that assert the current behavior.
- **Mocking Rules**: Use a mocking library (like `mocktail` or `NSubstitute`). Do not write manual Fake or Mock classes from scratch for complex services.
- **Mock Everything Public**: When mocking, stub all public properties and getters. Never stub `@protected` members (like `hasListeners`), as this causes crashes.
- **Scroll Before Tap (Flutter)**: Always use `await tester.ensureVisible(finder)` before tapping items inside a scrolling list.
- **Use Keys (Flutter)**: Use `find.byKey()` instead of searching for text on buttons or important structure.
- **No Double Underscores (Dart)**: Do not use `(_, __)` for empty parameters. This causes warning errors. Use real names or a single `_`.
- **New Files Only**: Create 1 new test file for 1 feature slice. Do not add tests to massive, generic test files (like `UserServiceTests.cs`). Create a specific new file (like `UserService_Password_Tests.cs`).
- **Cover All States**: Your tests must cover:
  1. **Happy Path** (Success - 200 OK, UI renders correctly).
  2. **Error State** (Validation errors, 404s, exceptions).
  3. **Empty State** (Null inputs, empty lists).

> **@@SCAN** (1) Did you cover Happy, Error, and Empty states? (2) Did you avoid writing main app code?

## Phase 3: Check Failures
> [!IMPORTANT]
> A test is only helpful if it fails because the feature isn't built yet. If it fails because of a typo or bad setup, it is useless to the Builder.

- **Run Tests to a File**: Run the tests and save the output to a file so you can read all of it. Then use `view_file` to read the results:
  - `.NET`: `powershell -File scripts\CollectTestResults.ps1` (or standard `dotnet test`)
  - `Flutter`: `flutter test --machine > .agents/tmp/test_results.json`
  - `Node`: `npm test -- --json > .agents/tmp/test_results.json`
- **Check the Results**: 
  - ✅ **Good Failure**: The test fails because of missing logic (like `NotImplementedException`, `MethodNotFound`, or the exact check failed). -> **Move to Phase 4**.
  - ❌ **Bad Validation**: The test fails right away because your test data is badly formatted and the server rejected it as a `400 BadRequest`. -> **Fix the test data and re-run.**
  - ❌ **Bad Syntax**: The test code has a typo or broken import. -> **Fix it and re-run.**
  - ❌ **Bad Setup**: The test crashes during the `// Arrange` setup phase (before it even tests the logic). -> **Fix the setup and re-run.**
- Keep fixing and running until 100% of the tests fail ONLY because the feature logic is missing.

> **@@SCAN**: (1) Did you run the tests? (2) Are they failing ONLY because the feature is missing?

## Phase 4: Handoff
- **Save Logs**: Use `write_to_file` to save the raw terminal output proving the tests fail correctly to `executed_tests_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` in the `brain/` folder. Do not print long logs in the chat.
- **Write Summary**: Use `write_to_file` to create `walkthrough_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md` in the `brain/` folder. Explain the tests you wrote and give the exact terminal commands the Builder should use to run them. **MANDATORY**: You MUST include an `## Input Lineage` section at the top of both files with the absolute path of the input plan.
- **Give Command**: Print the exact block below for the user:

## 🚦 User Handoff & Next Steps

> [!IMPORTANT]
> **Outputs Created:** Failing Unit Tests + `executed_tests_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md`.
>
> **YOUR NEXT COMMAND:** 
> - Return to your chat with Forge Builder and paste: `Here is the result of tdd from this artifact: {Absolute_Path_to_executed_tests.md}. Go.`

---

## Final Phase: Script Verification

> [!IMPORTANT]
> **Update `task_[YYYYMMDD_HHMMSS]_[ConversationID]_[topic].md`**: Change all checkboxes to `[x]` and add the absolute file paths to your Artifact Inventory.

Run this exact command using the `run_command` tool:
// turbo
`cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`

- Code 0 (PASS): Workflow complete. Share summary and stop.
- Code 1 (FAIL): Fix reported errors and try again.
- Note: If the same error happens twice, STOP and tell the user you are blocked.