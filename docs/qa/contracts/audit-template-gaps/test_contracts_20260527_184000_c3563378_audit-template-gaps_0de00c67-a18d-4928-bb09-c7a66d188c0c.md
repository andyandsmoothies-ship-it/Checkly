# Test Contracts: Audit Template CategoryTags Integration - Slice 2

## Input Lineage

- **Source Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-gaps\implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

## 📋 Approved Acceptance Criteria

### TC-CAT-03: Sync Endpoint Includes CategoryTags
**Gherkin Specification**:
```gherkin
Given an authenticated administrator
And a template has been saved with group categoryTags ["Kitchen-Sync", "FOH-Sync"] and criterion categoryTags ["CCP-Sync"]
When the client syncs templates via GET /api/sync/templates?since={timestamp}
Then the response status is 200 OK
And the returned "groups" list includes the group with its specific "categoryTags"
And the returned "criteria" list includes the criterion with its specific "categoryTags"
```

### TC-CAT-04: Backward Compat — Null tags do not break responses
**Gherkin Specification**:
```gherkin
Given an authenticated administrator
And a legacy template tree without categoryTags is upserted
When retrieving the template via GET /api/templates/{id}
Or syncing the templates via GET /api/sync/templates?since={timestamp}
Then the response statuses are 200 OK
And the "categoryTags" fields in the returned JSON groups and criteria project as null
And no null reference or serialization failures occur
```

---

## 🚦 Test Case Executions (GREEN Stage)

These cases have been physically executed against the API integration test harness inside `TemplateCategoryTagsProjectionTests.cs` and confirmed to pass cleanly, verifying both delta sync projections and backward compatibility.

| Test Case ID | Gherkin Reference | Asserted Property | Status |
|---|---|---|---|
| `Admin_Can_Sync_Category_Tags` | TC-CAT-03 | `categoryTags` presence in sync delta payload | 🟢 GREEN |
| `Old_Templates_Project_Null_Category_Tags` | TC-CAT-04 | Null categoryTags serialization & compatibility | 🟢 GREEN |

---

<test_trace>
Active code page: 65001
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

Starting test execution, please wait...
A total of 1 test files matched the specified pattern.

Passed!  - Passed:     2, Failed:     0, Skipped:     0, Total:     2, Duration: 873 ms - Checkly.Api.Tests.dll (net10.0)
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings)
</test_trace>

<forensic_evidence>
- Created test file: C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\TemplateCategoryTagsProjectionTests.cs
- Executed command: cmd /c chcp 65001 && rtk dotnet test --filter FullyQualifiedName~TemplateCategoryTagsProjectionTests
- Asserted JSON properties: group.categoryTags, criterion.categoryTags
- Checked results: Passed 2 of 2 tests successfully
</forensic_evidence>
