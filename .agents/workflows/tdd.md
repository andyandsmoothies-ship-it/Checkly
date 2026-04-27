---
description: The QA Test Generation Workflow (Red Phase). Runs before Builder implementation.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /tdd

> [!NOTE]
> This is the **Test-Driven Development (TDD) Generation** workflow — used strictly by the QA/SDET Agent (@Sentinel) to write failing unit and integration tests based on a predefined implementation plan.
> The Builder Agent (@Forge) is strictly forbidden from running this workflow.

## Pre-Flight Setup
- **MANDATORY ARTIFACT**: You MUST create a `task_[YYYYMMDD]_[ConversationID]_[topic].md` document right now using this exact schema. Update progress continuously.
  ```markdown
  # Task: [Test Generation Topic]
  Workflow: /tdd | Track: [A / B1 / B2 / C]
  ## Phases
  - [ ] Phase 1: Blueprint Ingestion
  - [ ] Phase 2: Test Authoring (Red Phase)
  - [ ] Phase 3: The Smoke Gate
  - [ ] Phase 4: Handoff
  ## Artifact Inventory
  | Status | File Path | Type |
  | [NEW]  | brain/.../executed_tests_[YYYYMMDD]_[ConversationID]_[topic].md | Red Tests |
  | [NEW]  | brain/.../walkthrough_[YYYYMMDD]_[ConversationID]_[topic].md | Summary |
  ```

## Phase 1: Blueprint Ingestion
- **Instruction**: Assume the role of **Sentinel** (Senior QA/SDET Engineer).
- **Action**: Read the `implementation_plan_[YYYYMMDD]_[ConversationID]_[topic].md` (or the plan provided by the user). You must fully understand the proposed API contracts, class names, or widget signatures proposed by the Builder.
- **Dynamic Skill Loading (MANDATORY)**: You must load testing skills relevant to the current technology stack. Scan `.agents/skills/` and load the most specific skills. Do NOT run this workflow without loading the correct skill suite:
  - **.NET / C# Backend**: Load `testing-strategy` (for xUnit v3, WebApplicationFactory, Verify).
  - **React / Frontend**: Load `frontend-testing` (for Jest, React Testing Library, Cypress).
  - **Flutter / Native Apps**: Load `mobile-app-testing` (for widget tests, integration_test, Detox).
- **Rule (Dependency Context)**: If the implementation plan requires mocking complex managers or services (like GetIt dependencies), check if the plan provides a **Dependency Context Array** (exact file paths to those services). If it doesn't, use `grep_search` to find the exact import paths before writing code. Do not guess folder names (e.g., `models` vs `model`).
- **Rule (Cross-Stack Boundary Check)**: If the plan touches an API route or DTO, MANDATORY `grep_search` BOTH `server/Features/` for the C# handler AND `lib/` for the Dart API service client. Verify route path, HTTP verb, and parameter types match on both sides before writing a single test. A test written against a mismatched contract will produce a false red.
- **Contract Validation Checklist (MANDATORY)**: Before writing a single test, validate every contract entry has all required fields. If ANY field is missing → **STOP** and ask the Builder to complete the contract:
  - [ ] **Exact Text/Key** specified? (e.g., the literal `'SIGN OUT'` string — not paraphrased)
  - [ ] **State Matrix** defined? (Happy Path + Error State + Empty/Cancel State)
  - [ ] **Private Method Access** stated? (`N/A` or `@visibleForTesting on [Method]`)
  - [ ] **Why RED now** includes a source line number?
- **Action**: If you see missing contracts or undefined signatures in the plan that make test writing impossible, **STOP** and ask the user to clarify.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you read the implementation plan? (2) Which testing skills did you load based on the tech stack? (3) Are ALL contract fields validated against the checklist above?

## Phase 2: Test Authoring (The Red Phase)
- **Requirement**: Write the actual test files (`.spec.ts`, `_test.dart`, `*Tests.cs`) targeting the new feature.
- **Rule (Ghost Protocol)**: Sentinel CANNOT write or modify production code in the `lib/`, `src/`, or `server/` folders. Sentinel writes test code only. **Exception**: You are explicitly allowed to edit production files solely to import `meta` and add `@visibleForTesting` (or equivalent `.NET` `InternalsVisibleTo`) to expose private methods needed for testing. 
- **Rule (The Mirror Function Trap)**: NEVER copy-paste production logic into a test file to bypass access modifiers. Testing cloned functions decouples the test from production reality. If a private method must be unit-tested directly, use the exception above to expose it and test the *real* method.
- **Rule (Legacy Code Assertion)**: For existing code, production logic is immutable. Write tests that assert current behavior. NEVER alter working production code; fix the test.
- **Rule (Mocking Standards)**: NEVER write manual `Fake` or `Mock` classes from scratch for complex dependencies. You must use a mocking library (e.g., `mocktail` in Flutter, `NSubstitute` in .NET) to auto-generate mocks that perfectly match interface signatures.
- **Rule (Exhaustive Mocking)**: When mocking services, stub all **public** readable properties/getters (e.g., `themeMode`), not just methods. **NEVER stub `@protected` members** (e.g., `ChangeNotifier.hasListeners`) — accessing them from outside the class hierarchy triggers `invalid_use_of_protected_member`. Mocktail handles listener attachment internally; only `addListener`/`removeListener` stubs are needed.
- **Rule (Viewport Occlusion - Flutter)**: Always call `await tester.ensureVisible(finder)` before tapping items inside scrollables (`ListView`, etc.) to prevent off-screen hit-test failures.
- **Rule (Explicit Finders)**: Avoid brittle text-matching predicates for structural elements like dialog buttons. Mandate explicit `Key` usage in the test contract and use `find.byKey()`.
- **Rule (Lambda Parameters - Dart)**: Never use `(_, __)` double-underscore lambdas. Modern `flutter_lints` ≥ 4.0 flags `__` as `unnecessary_underscores`. Use real parameter names (e.g., `(context, state)`) or a single `_` if only one parameter is unused.
- **Rule (Anti-Collision / Test Slicing)**: 1 Feature Slice = 1 Dedicated Test File. NEVER append tests to a massive, generic test file (e.g. `UserServiceTests.cs` or `user_page_test.dart`). You must scaffold a brand new, tightly-scoped file (e.g. `UserService_Password_Tests`) to prevent Git merge conflicts and parallel execution locking.
- **Rule (State Matrix)**: Your tests MUST aggressively cover:
  1. The **Happy Path** (Success State - 200 OK, expected view renders).
  2. The **Error State** (Validation failures, 404s, 403s, expected exceptions).
  3. The **Empty State** (Null inputs, empty arrays, edge cases).
- **Action**: Write the tests and save them to the correct test directory. 

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you cover Happy, Error, and Empty states? (2) Did you strictly avoid writing production code?

## Phase 3: The Smoke Gate (Red for the Right Reason)
> [!IMPORTANT]
> A failing test is only valuable if it fails for a **Business Reason**. If it fails because of a syntax error, bad import, or a broken test runner, it is totally useless to the Builder and wastes their context limit.

- **Action**: Run tests outputting to machine-readable files to bypass terminal truncation, then `view_file` the result:
  - `.NET`: `powershell -File scripts\CollectTestResults.ps1` (or standard `dotnet test`)
  - `Flutter`: `flutter test --machine > .agents/tmp/test_results.json`
  - `Node`: `npm test -- --json > .agents/tmp/test_results.json`
- **Gate Verdict**: Look at the parsed results instead of truncated terminal output.
  - ✅ **Valid Red**: The test fails because `MethodNotFound`, `NotImplementedException`, `Expected 200 but got 404`, or fails exactly at the expected business assertion. -> **Proceed to Phase 4**.
  - ❌ **False RED (Validation Trap)**: The test fails early because the server immediately rejects the request (e.g., `400 BadRequest`, `422 Unprocessable Entity`) due to structurally invalid test data, missing query parameters, or bad setup. -> **Fix the test payload to bypass initial validation and re-run immediately.**
  - ❌ **Invalid Syntax**: The test fails to compile due to a missing semicolon, incorrect syntax in the test file itself, or a broken import path not specified in the plan. -> **Fix it and re-run immediately.**
  - ❌ **Invalid Setup (The Arrange Rule)**: The test crashes during the `// Arrange` setup phase (e.g., seeding users, setting up auth tokens, registering dependencies) BEFORE hitting the business logic. -> **Fix the test setup and re-run immediately.**
- You must repeat this loop until you prove 100% of the tests are syntactically valid, properly configured, and failing purely because the logic implementation is missing.

> **@@SCAN**: (1) Tests physically executed? (2) Failing purely for missing implementation (Valid Red)?

## Phase 4: Handoff
- **Requirement**: Output the failed test execution log securely via file paths, NEVER via chat UI.
- **Action**: MANDATORY: Use `write_to_file` to create an `executed_tests_[YYYYMMDD]_[ConversationID]_[topic].md` artifact in the `brain/` directory containing the raw terminal output proving the Valid Red test failures.
- **Action**: MANDATORY: Use `write_to_file` to create a `walkthrough_[YYYYMMDD]_[ConversationID]_[topic].md` in the `brain/` directory declaring the scope of the tests written along with the exact commands the Builder should use to run them.
- **Final Message**: You MUST output the exact block below to the user so they can pivot back to the Builder Agent:

## 🚦 User Handoff & Next Steps

> [!IMPORTANT]
> **Outputs Created:** Internal Unit Tests (RED) + `executed_tests_[YYYYMMDD]_[ConversationID]_[topic].md`.
>
> **YOUR NEXT COMMAND:** 
> - Return to your suspended chat with Forge Builder and type: `Here is the result of tdd from this artifact: {Absolute_Path_to_executed_tests.md}. Go.`

---

## Final Phase: Script Verification Gate

> [!IMPORTANT]
> **Update `task_[YYYYMMDD]_[ConversationID]_[topic].md`**: Before running the script below, you MUST update your `task_[YYYYMMDD]_[ConversationID]_[topic].md` to change all lines to `[x]` and update the `Artifact Inventory` with the absolute paths of the files you just wrote.

Run EXACTLY:
`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

- Code 0 (PASS): Workflow complete. Share summary and stop.
- Code 1 (FAIL): Fix reported errors and retry.
- 2-Strike Rule: Same error fails twice → STOP. Write `handoff_[YYYYMMDD]_[ConversationID]_[topic].md` with error. Tell user: "Hard gate blocked on: [error]".