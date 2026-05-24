# Test Contracts: Strict AM-Store Assignment (Phase 2 UI)

## Input Lineage
- **Source Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260505_165000_am_store_strict_1_to_m.md`

## Origin Idea Alignment
The origin idea is to allow Admins to cleanly transfer stores between Area Managers. The UI must facilitate this by showing a "Show assigned stores" toggle to view taken stores, and upon selection/submission, catch the `409 Conflict` to prompt a clean Transfer Dialog (similar to the SM transfer logic).

## Gap Analysis (Adversary)
- **Gap 1 (API Params)**: When the "Show assigned stores" toggle is ON, the API call to `loadStores` must drop the `assignableAs=area_manager` parameter, otherwise taken stores won't be returned.
- **Gap 2 (Dialog Cancellation)**: If an Admin cancels the Transfer Dialog, the form must remain open and no `forceReassign=true` request should be sent.
- **Gap 3 (Form State)**: The `UserEditSheet` must handle `409 Conflict` gracefully; it shouldn't just map 409 to `emailError` if it's an AM store conflict.

## Acceptance Criteria (Gherkin)

### Scenario 1: Toggle 'Show assigned stores' modifies API payload
```gherkin
Given the Admin is creating or editing an Area Manager
When the Admin toggles "Show assigned stores" to ON
Then the UI requests stores without the 'assignableAs=area_manager' filter
And taken stores appear in the list with visual indicators
```

### Scenario 2: 409 Conflict triggers Transfer Dialog
```gherkin
Given the Admin selects a store already assigned to another AM
When the Admin submits the form
And the server returns a 409 Conflict with the existing manager's details
Then the UI intercepts the 409 and displays a Transfer Confirmation Dialog
```

### Scenario 3: Confirming Transfer submits with forceReassign=true
```gherkin
Given the Transfer Confirmation Dialog is visible
When the Admin taps "Confirm Transfer"
Then the UI resubmits the exact same payload but with 'forceReassign=true'
And the sheet closes upon 200 OK
```

### Scenario 4: Cancelling Transfer aborts the operation
```gherkin
Given the Transfer Confirmation Dialog is visible
When the Admin taps "Cancel"
Then no additional API requests are made
And the sheet remains open
```

## Test Infrastructure Map

### Helper Methods
| Method | Behavior |
|--------|----------|
| `pumpWidget` | Renders `UserCreateSheet` or `UserEditSheet` with mocked callbacks |
| `MockAdminApiService` | Mocks `loadStores`, `createUser`, and `updateUser` methods |

### Expected Response Shapes
```json
// POST /api/admin/users → 409 Conflict
{
  "error": "Store already has an area manager assigned",
  "existingManagerId": "uuid",
  "existingManagerName": "John Doe",
  "storeName": "Store 1"
}
```
