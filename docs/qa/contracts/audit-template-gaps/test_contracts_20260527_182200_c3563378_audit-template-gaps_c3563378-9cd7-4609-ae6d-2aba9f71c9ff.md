# Test Contracts: Audit Template CategoryTags Integration - Slice 1

## Input Lineage

- **Source Implementation Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-gaps\implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

## 📋 Approved Acceptance Criteria

### TC-CAT-01: Admin Can Save Group With Category Tags
**Gherkin Specification**:
```gherkin
Given an authenticated administrator
And a template tree payload containing a group with categoryTags ["Food Safety", "Cleanliness"]
When the administrator upserts the template tree via PUT /api/templates/{id}/tree
Then the response status is 200 OK
And the saved group contains categoryTags ["Food Safety", "Cleanliness"]
And retrieving the template via GET /api/templates/{id} includes the same categoryTags for the group
```

### TC-CAT-02: Admin Can Save Criterion With Category Tags
**Gherkin Specification**:
```gherkin
Given an authenticated administrator
And a template tree payload containing a criterion with categoryTags ["Hygiene"]
When the administrator upserts the template tree via PUT /api/templates/{id}/tree
Then the response status is 200 OK
And the saved criterion contains categoryTags ["Hygiene"]
And retrieving the template via GET /api/templates/{id} includes the same categoryTags for the criterion
```

---

## 🚦 Test Case Executions (RED Stage)

These cases have been physically executed against the API integration test harness inside `TemplateCategoryTagsTests.cs` and confirmed to fail with clear business assertions.

| Test Case ID | Gherkin Reference | Asserted Property | Status |
|---|---|---|---|
| `Admin_Can_Save_Group_With_Category_Tags` | TC-CAT-01 | `categoryTags` key existence in group JSON | 🔴 Business RED |
| `Admin_Can_Save_Criterion_With_Category_Tags` | TC-CAT-02 | `categoryTags` key existence in criterion JSON | 🔴 Business RED |
