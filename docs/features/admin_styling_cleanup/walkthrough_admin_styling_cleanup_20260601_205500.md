---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
Date: 2026-06-01
Topic: Administrative List-View Styling Cleanup & Modernization
---

# Administrative Visual Style Standardisation

```
[Admin Page]
    |
    +--> [Search Bar] -------> (Enabled/Focused Borders = 16px, swan/featherGreen, Nunito)
    |
    +--> [StoreCard Badge] --> (Circular 100px, 2px border AppColors.turtle, seaSponge bg)
    |
    +--> [ReviewCard Badge] -> (Circular 100px, 2px border scoreColor alpha 0.35)
```

We have audited and aligned the administrative list-view styles across **Store Management**, **Audit Approvals**, and **System Logs** to deliver the same premium, clean, modern look of the **System Management** dashboard and **Home** pages, maintaining the core high-contrast "Duolingo spirit".

---

## 1. Scope of Changes

### A. Store Management (`StoreCard`)
* **File**: `lib/features/admin/pages/widgets/store_card.dart`
* **Changes**:
  * Upgraded the leading store icon container from a generic `8px` rounded-corner container with a solid background to a **premium circular icon badge** with a high-contrast `2px` thick border side.
  * Mapped colors to the illustrative green palette: `AppColors.seaSponge` (background), `AppColors.turtle` (border), and primary green `Color(0xFF388E3C)` (icon), perfectly matching the `Store Management` dashboard menu item and stats card.

### B. Audit Approval Search Input (`AuditApprovalPage`)
* **File**: `lib/features/admin/pages/audit_approval_page.dart`
* **Changes**:
  * Redesigned the search input `TextField` from a plain, blocky standard material style to the premium high-contrast design.
  * Added custom `enabledBorder` and `focusedBorder` utilizing `BorderRadius.circular(16)` with a `2px` thickness (color `AppColors.swan` / `AppColors.featherGreen`).
  * Enforced standard `Nunito` body and hint text styling and colors.
  * Refined search bar padding to `EdgeInsets.fromLTRB(16, 12, 16, 8)` to establish a clean, consistent vertical rhythm.

### C. System Logs Search Input (`SystemLogsPage`)
* **File**: `lib/features/admin/pages/system_logs_page.dart`
* **Changes**:
  * Redesigned the search input `TextField` to replace the unpolished `OutlineInputBorder` with the premium rounded high-contrast theme.
  * Enforced `BorderRadius.circular(16)` with `2px` border sides, `Nunito` typography, custom hint colors, and clear action button icons (`AppColors.wolf`).
  * Adjusted search bar padding to `EdgeInsets.fromLTRB(16, 12, 16, 8)` to eliminate visual crowding.

### D. Audit Approval Review Card (`ReviewCard`)
* **File**: `lib/features/admin/pages/widgets/review_card.dart`
* **Changes**:
  * Enhanced the circular score badge in `ReviewCard` to feature a beautiful `2px` outer border using a high-contrast tint of the status-based score color (`scoreColor.withValues(alpha: 0.35)`). This matches all other leading circular badges perfectly.

---

## 2. Verification & Automated Testing

All modified files compile successfully and satisfy the strict vertical boundary constraints. The widget test suite for `AuditApprovalPage` was executed, verifying search filtration and list behaviors run seamlessly:

* **Command Run**: `rtk flutter test test/features/admin/pages/audit_approval_page_test.dart`
* **Results**: `All tests passed! (4/4 tests)`

---

> [!NOTE]
> The style cleanup was fully implemented using native primitives and design system tokens. No magic strings or custom layout hacks were introduced, preserving maximum maintenance leverage!
