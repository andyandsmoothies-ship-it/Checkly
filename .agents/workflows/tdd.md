---
description: The QA Test Generation Workflow (Red Phase). Runs before Builder implementation.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /tdd

> [!NOTE]
> This is the **Test-Driven Development (TDD) Generation** workflow — used strictly by the QA/SDET Agent (@Sentinel) to write failing unit and integration tests based on a predefined implementation plan.
> The Builder Agent (@Forge) is strictly forbidden from running this workflow.

## Pre-Flight Setup
- **MANDATORY ARTIFACT**: You MUST create a `task.md` document right now using this exact schema. Update progress continuously.
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
  |--------|-----------|------|
  ```

## Phase 1: Blueprint Ingestion
- **Instruction**: Assume the role of **Sentinel** (Senior QA/SDET Engineer).
- **Action**: Read the `implementation_plan_[topic].md` (or the plan provided by the user). You must fully understand the proposed API contracts, class names, or widget signatures proposed by the Builder.
- **Dynamic Skill Loading (MANDATORY)**: You must load testing skills relevant to the current technology stack. Scan `.agents/skills/` and load the most specific skills. Do NOT run this workflow without loading the correct skill suite:
  - **.NET / C# Backend**: Load `testing-strategy` (for xUnit v3, WebApplicationFactory, Verify).
  - **React / Frontend**: Load `frontend-testing` (for Jest, React Testing Library, Cypress).
  - **Flutter / Native Apps**: Load `mobile-app-testing` (for widget tests, integration_test, Detox).
- **Action**: If you see missing contracts or undefined signatures in the plan that make test writing impossible, **STOP** and ask the user to clarify.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you read the implementation plan? (2) Which testing skills did you load based on the tech stack? (3) Are the proposed contracts clear enough to write tests against?

## Phase 2: Test Authoring (The Red Phase)
- **Requirement**: Write the actual test files (`.spec.ts`, `_test.dart`, `*Tests.cs`) targeting the new feature.
- **Rule (Ghost Protocol)**: Sentinel CANNOT write or modify production code in the `lib/`, `src/`, or `server/` folders. Sentinel writes test code only. You must mock or assume the existance of the exact classes defined in the plan.
- **Rule (State Matrix)**: Your tests MUST aggressively cover:
  1. The **Happy Path** (Success State - 200 OK, expected view renders).
  2. The **Error State** (Validation failures, 404s, 403s, expected exceptions).
  3. The **Empty State** (Null inputs, empty arrays, edge cases).
- **Action**: Write the tests and save them to the correct test directory. 

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Did you cover Happy, Error, and Empty states? (2) Did you strictly avoid writing production code?

## Phase 3: The Smoke Gate (Red for the Right Reason)
> [!IMPORTANT]
> A failing test is only valuable if it fails for a **Business Reason**. If it fails because of a syntax error, bad import, or a broken test runner, it is totally useless to the Builder and wastes their context limit.

- **Action**: Compile and run the tests using your terminal (e.g., `dotnet test`, `flutter test`, `npm run test`).
- **Gate Verdict**: Look at the terminal output. 
  - ✅ **Valid Red**: The test fails because `MethodNotFound`, `NotImplementedException`, or `Expected 200 but got 404` (because the endpoint does not physically exist yet). -> **Proceed to Phase 4**.
  - ❌ **Invalid Syntax**: The test fails to compile due to a missing semicolon, incorrect syntax in the test file itself, or a broken import path not specified in the plan. -> **Fix it and re-run immediately.**
- You must repeat this loop until you prove 100% of the tests are syntactically valid and failing purely because the logic implementation is missing.

> **@@SCAN**: (1) Tests physically executed? (2) Failing purely for missing implementation (Valid Red)?

## Phase 4: Handoff
- **Requirement**: Output the failed test execution log securely.
- **Action**: Create an `executed_tests_[topic].md` artifact containing the raw terminal output proving the Valid Red test failures.
- **Action**: Create a `walkthrough_[topic].md` declaring the scope of the tests written along with the exact commands the Builder should use to run them.
- **Final Message**: You MUST output the exact following block to the user so they can pivot back to the Builder Agent:

> **Tests are written and Red.**
> 
> *To the Product Owner: Please swap back to your chat with Forge (the Builder Agent) and send this exact message:*
> "The QA Agent has written the TDD tests. The tests are red for the right reasons. Proceed to Phase 3: Coding and turn them green."

---

## Final Phase: Script Verification Gate
Run EXACTLY:
`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

- Code 0 (PASS): Workflow complete. Share summary and stop.
- Code 1 (FAIL): Fix reported errors and retry.
- 2-Strike Rule: Same error fails twice → STOP. Write `handoff_[topic].md` with error. Tell user: "Hard gate blocked on: [error]".

