# Walkthrough: BOD Analytics Drill-Down - Slice 2 Client Bridge Fix (Acceptance Tests Complete)

This walkthrough documents the completion of the **Slice 2 Client Bridge Fix** under the `/atdd` flow. The project is now successfully transitioned into a clean, compilation-safe **RED** state. 

All Slice 2 drilldown unit tests have been written and verified to fail strictly due to missing production logic (`UnimplementedError`), establishing a robust contract for the developer/Builder.

---

## 1. Accomplished Tasks

### [x] 1. Spec Discovery & Contract Definition
- Analyzed the Slice 2 requirements in the dynamic implementation plan.
- Discovered and mapped all 8 business test cases (TC-BOD-AP-01 to TC-BOD-AUD-01).
- Produced the formal Quality Gate contract: [test_contracts_20260525_114500_453a8146_bod-analytics_9f01576e-5eea-4355-862d-0d0e6b35f0a8.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/qa/contracts/bod-analytics/test_contracts_20260525_114500_453a8146_bod-analytics_9f01576e-5eea-4355-862d-0d0e6b35f0a8.md)

### [x] 2. Strongly Typed ApDetailEntry Integration
- Refactored `lib/features/analytics/widgets/bod_ap_bucket_detail_sheet.dart` to consume strongly typed `ApDetailEntry` models rather than raw primitive maps (`Map<String, dynamic>`).
- Updated existing `test/features/analytics/pages/bod_analytics_page_test.dart` to instantiate concrete `ApDetailEntry` mock return arrays instead of raw maps.
- Verified that all existing widget and page tests compile flawlessly and pass successfully.

### [x] 3. Client Bridge API & Manager Stubs
- Added the following Slice 2 signature stubs to `BodAnalyticsApiService`:
  - `Future<List<ApDetailEntry>> getApBucketDetail(String bucketName)`
  - `Future<StoreBodSummary> getStoreBodSummary(String storeId)`
  - `Future<List<CategoryStoreEntry>> getCategoryDetail(String name)`
  - `Future<List<dynamic>> getAuditorProductivity()`
- Added fields, getters, and stub methods to `BodAnalyticsManager`:
  - `bool get isStoreDetailLoading`, `StoreBodSummary? get storeDetail`
  - `bool get isCategoryDetailLoading`, `List<CategoryStoreEntry> get categoryDetail`
  - `bool get isAuditorDetailLoading`, `dynamic get auditorDetail`
  - Stubs for `loadApDetails`, `loadStoreDetail`, `loadCategoryDetail`, `loadAuditorDetail` (each throwing `UnimplementedError`).

### [x] 4. Failing Unit Tests (RED State)
- Appended the comprehensive Slice 2 ATDD unit test suite to `test/features/analytics/manager/bod_analytics_manager_test.dart`.
- Executed the test suite to confirm compile-level compliance and robust failure execution (asserting `UnimplementedError`).

---

## 2. Dynamic Verification State

Run the following command to verify the RED state of the manager unit tests:

```bash
rtk flutter test test/features/analytics/manager/bod_analytics_manager_test.dart
```

Expected output:
- **8 failures** on the newly introduced tests (`Slice 2 - Drilldown Client Bridge Tests`).
- **All** failures must state `UnimplementedError` originating from `BodAnalyticsManager`.

Run the following command to verify all existing tests still pass successfully:

```bash
rtk flutter test test/features/analytics/pages/bod_analytics_page_test.dart
```

Expected output:
- **All tests passed!**

---

## 3. Transition Directive for the Builder Agent

> [!IMPORTANT]
> The next agent (Builder) is authorized to implement the production code in the features directory to transition these tests from **RED** to **GREEN**.

### Implementation Guidelines for the Builder:

1. **`loadApDetails(String bucketName)`**:
   - Trim the inputs and normalize display bucket names to normalized parameter names (e.g. `'0-30 Days'` or `'  0-30 days  '` maps to `'0-30d'`).
   - Implement concurrency locking via `isApDetailLoading` to discard double-clicks.
   - Perform the api call using `_api.getApBucketDetail()`.
   - Update `_apDetails`, reset `_error`, and notify listeners. Handle network exceptions elegantly (map error string).

2. **`loadStoreDetail(String storeId)`**:
   - Set `isStoreDetailLoading` to `true`, clear `_storeDetail`, and fetch via `_api.getStoreBodSummary()`.
   - On success, populate `_storeDetail`, set loading to `false`, and notify listeners.
   - On exception, clear state, populate `_error` with `Something went wrong. Please try again.`, and notify.

3. **`loadCategoryDetail(String name)`**:
   - Trim Whitespace from `name` and fetch via `_api.getCategoryDetail()`.
   - Populate `_categoryDetail` and notify.

4. **`loadAuditorDetail(String auditorName)`**:
   - Fetch the list from `_api.getAuditorProductivity()`.
   - Apply client-side filtration using the `auditorName` to extract and populate `_auditorDetail`.

This completes the `/atdd` quality gate loop for Slice 2!
