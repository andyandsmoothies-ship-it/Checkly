# Test Contracts: Flutter Template CategoryTags Integration

## Input Lineage

- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\audit-template-gaps\implementation_plan_20260527_181300_c3563378_audit-template-gaps_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

## Acceptance Criteria & Scenarios (Gherkin Format)

### TC-CAT-05: Flutter DTO - GroupDto JSON Parsing
- **Citation**: implementation_plan_20260527_181300_c3563378 §Slice 3
- **Gherkin**:
  ```gherkin
  Given a Group JSON payload with a list of categoryTags ["Food Safety", "Cleanliness"]
  When parsing the payload into a GroupDto
  Then the categoryTags field should contain exactly ["Food Safety", "Cleanliness"]
  ```

### TC-CAT-06: Flutter DTO - CriterionDto JSON Parsing
- **Citation**: implementation_plan_20260527_181300_c3563378 §Slice 3
- **Gherkin**:
  ```gherkin
  Given a Criterion JSON payload with a list of categoryTags ["CCP", "Hygiene"]
  When parsing the payload into a CriterionDto
  Then the categoryTags field should contain exactly ["CCP", "Hygiene"]
  ```

### TC-CAT-07: Flutter DAO - Store and Retrieve Group CategoryTags
- **Citation**: implementation_plan_20260527_181300_c3563378 §Slice 3
- **Gherkin**:
  ```gherkin
  Given an in-memory Drift database instance
  And a GroupDto with categoryTags ["Food Safety"]
  When calling upsertGroups() to save the group to the database
  And calling getTemplateTree() to retrieve the template tree
  Then the retrieved GroupDto's categoryTags must equal exactly ["Food Safety"]
  ```

### TC-CAT-08: Flutter DAO - Store and Retrieve Criterion CategoryTags
- **Citation**: implementation_plan_20260527_181300_c3563378 §Slice 3
- **Gherkin**:
  ```gherkin
  Given an in-memory Drift database instance
  And a CriterionDto with categoryTags ["CCP"]
  When calling upsertCriteria() to save the criteria to the database
  And calling getTemplateTree() to retrieve the template tree
  Then the retrieved CriterionDto's categoryTags must equal exactly ["CCP"]
  ```

### TC-CAT-09: Flutter DAO - Null CategoryTags Support
- **Citation**: implementation_plan_20260527_181300_c3563378 §Slice 3
- **Gherkin**:
  ```gherkin
  Given an in-memory Drift database instance
  And a GroupDto with a null categoryTags field
  When calling upsertGroups() to save the group to the database
  And calling getTemplateTree() to retrieve the template tree
  Then the retrieved GroupDto's categoryTags must be null
  ```

### TC-GAP-01: Empty & Whitespace CategoryTags Are Ignored
- **Citation**: Gap Analysis AC-GAP-1
- **Gherkin**:
  ```gherkin
  Given an in-memory Drift database instance
  And a GroupDto with categoryTags containing empty and whitespace values ["", "   ", "Hygiene"]
  When calling upsertGroups() to save the group to the database
  And calling getTemplateTree() to retrieve the template tree
  Then the retrieved GroupDto's categoryTags must contain only ["Hygiene"]
  ```

### TC-GAP-02: Drift Database Schema Migration v30 -> v31
- **Citation**: Gap Analysis AC-GAP-2
- **Gherkin**:
  ```gherkin
  Given a Drift database schema at version 30
  And the schema contains existing CachedGroups and CachedCriteria rows
  When running the database migration to version 31
  Then the columns CachedGroups.categoryTags and CachedCriteria.categoryTags must exist
  And the existing database rows must remain intact with null categoryTags
  ```

## Test Infrastructure Map

### Seed / Helper Methods
- `AppDatabase.forTesting(NativeDatabase.memory())`: Initializes a fresh in-memory Drift database instance.
- `TemplateDao(db)`: The DAO repository under test.

### DTO Payload Helpers
- `GroupDto`: Model for groups.
- `CriterionDto`: Model for criteria.
- `TemplateTreeDto`: Model for the full template tree.
