# Walkthrough & Verification Report: Audit Template Linter (Slice 1)

**Topic**: `audit-template-flexibility` | **Date**: 2026-05-29 | **ConversationID**: `91f29479-1843-4148-9f83-137e019d7b73`

---

## ## Input Lineage
*   **Epic Analysis Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-flexibility\analysis_epic_20260529_104152_audit_template_flexibility_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`
*   **ATDD Contracts Spec**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\contracts\audit-template-flexibility\test_contracts_20260529_132009_atdd_slice1_ac4575e5-39d8-4b20-a4a6-49ce53ce5264.md`
*   **Active Task Tracker**: `c:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\audit-template-flexibility\task_20260529_104152_audit_template_flexibility_240f4566-499b-43d5-884f-c338ffd53913.md`

---

## ## Decision Log

### 1. Tenant Ownership Check (IDOR Guard)
*   **Proposed**: Verify that the tenant ID of the template matches the tenant ID of the authenticated user.
*   **Implemented**: In `SaveTemplateTree.cs`, verified `template.CreatedBy == currentUserId` before making any modifications, returning a `403 Forbidden` response if there is a tenant mismatch.

### 2. Node Payload Size Cap (Poison Pill Check)
*   **Proposed**: Enforce an upper limit of combined nodes (groups and criteria) to prevent CPU/memory exhaustion.
*   **Implemented**: Added validation checking `groupCount + criterionCount > 500` immediately at endpoint entry. Rejects payload with `400 Bad Request` if over the threshold.

### 3. Progressive Scoring Cast Overflow Safe Math
*   **Proposed**: Fix overflow risk in repeated faults multiplication.
*   **Implemented**: Refactored `ScoringHelpers.cs` progressive repeat multiplication:
    ```csharp
    decimal repeatedFaultsDec = repeatedFaults;
    decimal deduction = minusImpact * repeatedFaultsDec * repeatedFaultsDec;
    ```
    Casting to `decimal` *before* multiplying eliminates the `long` / `int` overflow.

---

## ## Verification Handoff

### Automated verification
Run the targeted xUnit integration test suite to verify all linter rules and progressive repeat scoring safety:
```bash
dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~TemplateLinter_Slice1_Tests
```

### Manual Verification Steps
1.  **Verify IDOR Block**:
    *   Authenticate as User B.
    *   Attempt to PUT a template tree to `/api/templates/{TemplateA_ID}/tree` owned by User A.
    *   **Expected Result**: HTTP `403 Forbidden` returned.
2.  **Verify Node Limit Cap**:
    *   Attempt to save a template tree with 501 total nodes (e.g. 1 group, 500 criteria).
    *   **Expected Result**: HTTP `400 Bad Request` returned.
3.  **Verify Linter Unprocessable Output**:
    *   Attempt to save a penalty-mode template tree with weights summing to 90%.
    *   **Expected Result**: HTTP `422 Unprocessable Entity` returned with a structured `lintResult` JSON array.

---

## <test_trace>
```
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Failed:     0, Passed:    12, Skipped:     0, Total:    12, Duration: 6 s - Checkly.Api.Tests.dll (net10.0)
```
---

## <forensic_evidence>
Verification commands executed:
*   `dotnet build server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj` - Clean build with 0 errors or warnings.
*   `dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter FullyQualifiedName~TemplateLinter_Slice1_Tests` - Verified green pass on all 12 validation scenarios.

---

## ## Gotcha Protocol

### 1. Progressive Repeat Safety
*   **Proposed Gotcha**: When implementing progressive repeater calculations or penalty repeats, always cast inputs to `decimal` before carrying out nested power multiplications to prevent `long` overflow exceptions in .NET Core runtime.

### 2. Survey Exemption
*   **Proposed Gotcha**: Templates of type `"survey"` do not calculate or require percentage total weights. Always skip penalty or score weight sum linters when `template.Type == "survey"`.
