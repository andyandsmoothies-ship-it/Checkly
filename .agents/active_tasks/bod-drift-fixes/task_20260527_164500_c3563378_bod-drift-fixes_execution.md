# Task Execution Checklist: BOD Analytics DTO Drift Fixes

```
[Server DTO]
    │
    ├─ kpis.activeStores      ──► BodChainKpis.activeStores ──► KPI Grid Card
    ├─ kpis.totalAuditors     ──► BodChainKpis.totalAuditors ──► KPI Grid Card
    ├─ goldenStore.province   ──► BodGoldenStore.province
    └─ actionPlanAging (list) ──► BodApAging (bucket0to7, bucket8to30, bucket31to90, bucket90Plus)
                                         │
                                         ▼
                                  ApAgingFunnel (renders 0-7, 8-30, 31-90, 90+ Days)
                                         │
                                         ▼
                                  loadApDetails("0-7d", etc.) ──► API
```

## Slices to Execute

- [ ] **Slice 1: Fix Data Layer (Models + Mock Data)**
  - [ ] Modify `lib/features/analytics/manager/bod_analytics_data.dart`
    - [ ] Update `BodChainKpis` to include `activeStores` and `totalAuditors`
    - [ ] Update `BodApAging` rename fields (`bucket0to7`, `bucket8to30`, `bucket31to90`, `bucket90Plus`) & update `fromDynamic` & backwards-compatible `fromJson` & `toJson`
    - [ ] Update `BodGoldenStore` to remove `storeId` and add `province`
  - [ ] Update `test/features/analytics/manager/bod_analytics_manager_test.dart`
  - [ ] Update `test/features/analytics/manager/bod_analytics_slice3_test.dart`
  - [ ] Update `test/features/analytics/pages/bod_analytics_page_test.dart`
  - [ ] Verify compilation and run test suite: `rtk flutter test test/features/analytics/`

- [ ] **Slice 2: Fix Funnel Widget Labels & Drill-down Names**
  - [ ] Modify `lib/features/analytics/widgets/bod_ap_aging_funnel.dart`
    - [ ] Update key lookups in `build()` to match new `toJson()` keys
    - [ ] Update display labels to `"0-7 Days"`, `"8-30 Days"`, `"31-90 Days"`, `"90+ Days"`
    - [ ] Update `onTap` parameters passed to `_openBucketDetails` to match API path format: `'0-7d'`, `'8-30d'`, `'31-90d'`, `'90d+'`
  - [ ] Verify and run test suite

- [ ] **Slice 3: Add Missing KPI Tiles to Grid**
  - [ ] Modify `lib/features/analytics/widgets/bod_kpi_grid.dart`
    - [ ] Read `activeStores` and `totalAuditors` from raw `chainKpis` map
    - [ ] Add 2 new `_buildKpiCard` widgets in a third row
  - [ ] Run full analytical suite tests and perform visual check/verification
