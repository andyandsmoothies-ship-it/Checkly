UPDATE bod_report_snapshots
SET payload = jsonb_set(
  jsonb_set(
    payload,
    '{topStores}',
    '[{"storeId": "ba7e69f8-7a67-4092-ae80-51291a18aa25", "storeName": "Checkly D1 - Nguyen Hue", "avgScore": 91.7, "auditCount": 2, "lastSyncedAt": null}, {"storeId": "0ac3cf0b-e393-40f0-81c7-2e4f296bec94", "storeName": "Checkly Binh Thanh - Landmark 81", "avgScore": 90.5, "auditCount": 2, "lastSyncedAt": null}, {"storeId": "9a1082b2-2796-42ef-885f-34f8c746a110", "storeName": "Checkly Go Vap - Quang Trung", "avgScore": 89.0, "auditCount": 3, "lastSyncedAt": null}, {"storeId": "155be63b-056d-43ff-8c51-68243de324b5", "storeName": "Checkly D7 - Phu My Hung", "avgScore": 87.2, "auditCount": 3, "lastSyncedAt": null}, {"storeId": "82e71697-8d6c-45ae-8734-2f26d738275a", "storeName": "Checkly D10 - Su Van Hanh", "avgScore": 87.1, "auditCount": 3, "lastSyncedAt": null}]'::jsonb
  ),
  '{bottomStores}',
  '[{"storeId": "ed6dd187-7709-41bc-89e4-b6e7994d5d72", "storeName": "Checkly Phu Nhuan - Phan Xich Long", "avgScore": 79.6, "auditCount": 3, "lastSyncedAt": null}, {"storeId": "2a3c00c5-aa6c-43cb-854c-cc2066de36e4", "storeName": "Checkly D1 - Bui Vien", "avgScore": 81.7, "auditCount": 3, "lastSyncedAt": null}, {"storeId": "8d151226-1e93-42ae-bcec-79bc7ce5cf74", "storeName": "Checkly D2 - Thao Dien", "avgScore": 85.1, "auditCount": 2, "lastSyncedAt": null}, {"storeId": "fd393a99-d5d1-4038-80e3-53504057f2c2", "storeName": "Checkly D3 - Vo Van Tan", "avgScore": 86.3, "auditCount": 2, "lastSyncedAt": null}, {"storeId": "766bf35d-235b-40f0-b6d2-1940c0e2486f", "storeName": "Checkly Tan Binh - Cong Hoa", "avgScore": 86.7, "auditCount": 2, "lastSyncedAt": null}]'::jsonb
)
WHERE date = '2026-06-01';
