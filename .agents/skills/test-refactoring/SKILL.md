---
name: test-refactoring
description: >
  SCRAP-inspired AI decision framework for test file refactoring. Classifies test
  files into 5 actionability categories (LEAVE_ALONE, AUTO_TABLE_DRIVE, AUTO_REFACTOR,
  MANUAL_SPLIT, REVIEW_FIRST) before the AI touches them. Prevents blind test cleanup
  that makes tests harder to read. Stack-agnostic — works for xUnit, NUnit, Flutter
  test, Jest, pytest, etc. Load this skill when: "refactor tests", "clean up tests",
  "test quality", "test smells", "duplicate tests", "test structure", "table-driven",
  "parameterized tests", "Theory", "test audit", "SCRAP", "test complexity", or
  when the /audit-code workflow scans test files.
---

# Test Refactoring (SCRAP-Inspired)

## Core Principle

Test code has different quality criteria than production code. Extracting shared setup into helpers can make tests **harder to understand**, not easier. Converting explicit test cases into loops can **hide the intent** of each scenario.

Before refactoring any test file, the AI MUST classify it into an **AI Actionability Category** to determine the correct refactoring approach — or to determine that no refactoring is needed at all.

This skill is derived from the SCRAP (Structural Complexity Rating for Automated Pruning) methodology, adapted for modern testing frameworks.

## The AI Actionability Matrix

| Category | Meaning | AI Action | Confidence |
|----------|---------|-----------|------------|
| `LEAVE_ALONE` | Test is well-structured and readable | Do nothing unless explicitly asked | High — requires no justification |
| `AUTO_TABLE_DRIVE` | Repetitive low-complexity tests with varying data | Convert to parameterized tests (`[Theory]`, `@parameterized`, `test.each`) | High — safe mechanical transformation |
| `AUTO_REFACTOR` | Locally messy but tests a single coherent concern | Extract shared arrange, simplify assertions, reduce setup depth | Medium — verify intent is preserved |
| `MANUAL_SPLIT` | File tests multiple unrelated concerns | Split into separate test classes/files FIRST, then clean up | Medium — requires understanding boundaries |
| `REVIEW_FIRST` | Heuristic is not confident | Present findings to user before acting | Low — human must decide |

## Classification Signals

Evaluate these signals to determine the correct category:

### Signal 1: Structural Duplication
Count sibling test methods that have structurally similar arrange/act patterns but differ only in input data.

- **≥ 3 structurally similar tests** with only data differences → `AUTO_TABLE_DRIVE`
- **≥ 3 structurally similar tests** with different assertions → `AUTO_REFACTOR` (extract shared arrange)
- **< 3 similar tests** → Not a duplication concern

### Signal 2: Test Method Size
Measure line count per test method (excluding blank lines and comments).

- **≤ 15 lines**: Focused — no smell
- **16-30 lines**: Acceptable if arrange is complex
- **31+ lines**: Smell — likely multiple phases or excessive setup → `AUTO_REFACTOR`

### Signal 3: Assertion Density
Count assertions per test method.

- **0 assertions**: 🔴 Critical smell — test verifies nothing
- **1 assertion in a 20+ line test**: Weak — setup cost not justified
- **2-5 assertions**: Normal
- **6+ assertions**: May be testing multiple behaviors → `MANUAL_SPLIT` or `AUTO_REFACTOR`

### Signal 4: Arrange Depth
Count the layers of setup: builders, factory methods, mock configurations, database seeding.

- **0-1 layers**: Simple
- **2-3 layers**: Moderate — acceptable for integration tests
- **4+ layers**: Deep — consider extracting a test builder or fixture class → `AUTO_REFACTOR`

### Signal 5: Mock Count
Count distinct mocked/stubbed dependencies.

- **0 mocks**: Clean (likely integration test or pure logic test)
- **1-2 mocks**: Acceptable
- **3+ mocks**: Smell — may indicate the SUT has too many dependencies → `REVIEW_FIRST`

> [!WARNING]
> **Detroit TDD Constraint**: If the project follows Detroit-style (classical) TDD, high mock counts are a stronger smell than in London-style. Do NOT recommend adding mocks to lower complexity scores. Instead, recommend refactoring the production code to reduce dependencies.

### Signal 6: Concern Cohesion
Analyze whether all test methods in the file exercise the same production class/feature.

- **All tests target the same class/feature**: Cohesive → can be cleaned locally
- **Tests target 2+ unrelated classes/features**: Incoherent → `MANUAL_SPLIT`

## Classification Algorithm

```
FOR each test file:
  1. Count structurally similar test groups (Signal 1)
  2. Measure max test method size (Signal 2)
  3. Check for zero-assertion tests (Signal 3)
  4. Measure arrange depth (Signal 4)
  5. Count mocks (Signal 5)
  6. Check concern cohesion (Signal 6)

  IF Signal 6 shows incoherent concerns:
    → MANUAL_SPLIT

  ELSE IF Signal 1 shows ≥ 3 data-only duplicates:
    → AUTO_TABLE_DRIVE

  ELSE IF Signal 2 shows 31+ lines OR Signal 4 shows 4+ depth:
    → AUTO_REFACTOR

  ELSE IF Signal 5 shows 3+ mocks AND project uses Detroit TDD:
    → REVIEW_FIRST  (may need production code refactor, not test refactor)

  ELSE IF Signal 3 shows zero-assertion tests:
    → AUTO_REFACTOR  (add assertions or delete the test)

  ELSE:
    → LEAVE_ALONE
```

## Refactoring Playbooks

### AUTO_TABLE_DRIVE Playbook
1. Identify the repeated test structure.
2. Extract the varying data points into a test data source:
   - **xUnit**: `[Theory]` + `[InlineData]` or `[MemberData]`
   - **NUnit**: `[TestCase]` or `[TestCaseSource]`
   - **Flutter**: parameterized test packages or inline loops
   - **Jest**: `test.each` or `describe.each`
3. Collapse the duplicate test methods into a single parameterized test.
4. Verify: the same number of test cases execute. No test case was lost.

### AUTO_REFACTOR Playbook
1. Extract shared arrange steps into a builder or fixture method.
2. **CRITICAL**: The builder must NOT hide the test's intent. Each test should still clearly show what makes its scenario unique.
3. Reduce assertion clusters — if a test has 6+ assertions, consider splitting into separate test methods.
4. Verify: all tests still pass, and a new developer can understand each test in < 30 seconds.

### MANUAL_SPLIT Playbook
1. Group test methods by the production class/feature they exercise.
2. Create a new test file for each group.
3. Move shared setup (if any) into a shared fixture or base class.
4. **Do NOT** do local cleanup during the split. Split first, then rerun this skill on each resulting file for local classification.

## Anti-patterns

### Blind Helper Extraction

```
# BAD — extracting setup hides what the test is actually verifying
private Order CreateStandardOrder() => new Order { /* 20 lines of setup */ };

[Fact] public void RejectsEmptyCart() {
    var order = CreateStandardOrder(); // What did we set up? Who knows.
    order.Items.Clear();
    // ...
}

# GOOD — builder makes the unique scenario visible
[Fact] public void RejectsEmptyCart() {
    var order = AnOrder().WithNoItems().Build(); // Intent is clear
    // ...
}
```

### Over-Parameterization

```
# BAD — parameterized test where scenarios are fundamentally different
[Theory]
[InlineData("valid", true, null)]
[InlineData("", false, "Name required")]  // Different error path!
[InlineData(null, false, "Name required")] // Also different error path!
public void ValidatesName(string name, bool valid, string? error) { ... }

# GOOD — only parameterize truly data-variant scenarios
[Theory]
[InlineData("")]
[InlineData(null)]
[InlineData("   ")]
public void RejectsBlankNames(string? name) { ... }  // Same behavior, different data
```

## Decision Guide

| Scenario | Action |
|----------|--------|
| Asked to "clean up" a test file | Classify first, then apply the matching playbook |
| Writing new tests during /implement | Classify is not needed — write fresh tests following TDD skill |
| Reviewing tests during /audit-code | Classify each test file, report findings in audit |
| Test file has 0 smells | Report `LEAVE_ALONE`, do not touch |
| High mock count + Detroit TDD project | Report `REVIEW_FIRST`, suggest production code refactor instead |
| Multiple concerns in one file | `MANUAL_SPLIT` — do NOT attempt local cleanup first |
