---
conversation_id: "b94d1673-00ee-4f82-9a9f-6ec46444aa69"
---

# Test Contracts: Historical Manager Snapshots - Slice 2 API Contract

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\historical-manager-snapshots\implementation_plan_historical-manager-snapshots_20260607_190500.md`

## Acceptance Scenarios (Gherkin Format)

### Scenario 1: GET /api/submissions/{id} returns snapshotted manager info (TC-2.1)
* **Given** a completed submission `Sub-1` exists in the database
* **And** `Sub-1` has `AreaManagerId` = `AM-1.Id`, `AreaManagerName` = `AM-1.FullName`, `StoreManagerId` = `SM-1.Id`, and `StoreManagerName` = `SM-1.FullName`
* **When** a request is made to GET `/api/submissions/Sub-1.Id`
* **Then** the response JSON has `areaManagerId` equal to `AM-1.Id`, `areaManagerName` equal to `AM-1.FullName`, `storeManagerId` equal to `SM-1.Id`, and `storeManagerName` equal to `SM-1.FullName`

### Scenario 2: GET /api/submissions (List) returns snapshotted manager info (TC-2.2)
* **Given** a completed submission `Sub-1` exists in the database
* **And** `Sub-1` has `AreaManagerId` = `AM-1.Id`, `AreaManagerName` = `AM-1.FullName`, `StoreManagerId` = `SM-1.Id`, and `StoreManagerName` = `SM-1.FullName`
* **When** a request is made to GET `/api/submissions`
* **Then** the response JSON list has a submission with `areaManagerId` equal to `AM-1.Id`, `areaManagerName` equal to `AM-1.FullName`, `storeManagerId` equal to `SM-1.Id`, and `storeManagerName` equal to `SM-1.FullName`

### Scenario 3: Legacy or Draft submissions return null values (TC-2.3)
* **Given** a draft submission `Sub-2` exists in the database with `null` manager snapshot values
* **When** a request is made to GET `/api/submissions/Sub-2.Id`
* **Then** the response JSON has `areaManagerId`, `areaManagerName`, `storeManagerId`, and `storeManagerName` set to `null`

---

## Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `RegisterUserAsync` | `(HttpClient, email, password, name, role)` | Creates a user with a specific role |
| `EnsureDatabaseCreated` | `()` | Ensures the DB schema is created |
| `CreateAuthenticatedClient` | `(token)` | Creates an HttpClient with authorization headers |

### Seed Data
- **Users**: Unique emails generated using Guid to prevent database key conflicts.
- **Roles**: `auditor`, `store_manager`, `area_manager`.
- **Database**: Fresh `checkly_test` PostgreSQL database.
