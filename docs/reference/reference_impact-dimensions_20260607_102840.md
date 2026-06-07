---
ConversationID: 98883c69-9a72-433e-88d5-9df601e48cd1
Type: Reference
Topic: Impact Dimensions Checklist
Created: 2026-06-07 10:28:40
---

[User Request]
       │
       ▼
┌──────────────┐
│  Analysis    │
└──────┬───────┘
       │
       ├─► [1. Technical Dependency & Regression Analysis]
       ├─► [2. Functional Impact Analysis]
       ├─► [3. Operational Capacity & Cost Impact]
       ├─► [4. User Friction & Cognitive Load]
       ├─► [5. Business Operational Impact]
       └─► [6. Regulatory, Privacy, & Security Compliance]

# The 6 Impact Dimensions Reference Checklist

Use this reference checklist during planning, epic analysis, and feature scoping to identify potential side effects before implementing changes.

---

## 1. Technical Dependency & Regression Analysis
*How code changes affect other code files and data structures.*

* **Database Schema**:
  * Will this change need new tables, new columns, or new indexes?
  * Do we need to migrate existing rows to fill them with a default value?
  * Are there unique indexes or foreign key rules that might cause failures?
* **API Contracts**:
  * Did we change property names in a JSON DTO that will break the mobile app?
  * Is the API endpoint backward-compatible with older client versions?
* **Common Code (UI Widgets & Helpers)**:
  * Are we editing a shared button, card, or text field used by other pages?
  * Did we change the behavior of a shared validation or calculation utility?
* **Test Coverage**:
  * Which existing tests (unit, integration, widget) will fail because of this change?
  * Do we need to write new tests to verify both success and failure cases?

---

## 2. Functional & Downstream Impact Analysis
*How new features change user behaviors or visual results in other screens.*

* **View & Filter**:
  * Does the new field need to show up in search bars, tables, or list screens?
  * Do we need to add a filter dropdown for this new field in dashboard views?
* **Access & Scope**:
  * Which user roles (Admin, Auditor, Area Manager) are allowed to view this?
  * Which roles are allowed to edit, create, or delete this data?
* **Report & Math**:
  * Does the new field change how we calculate compliance scores or averages?
  * Do dashboard charts and KPI summary widgets need to use this new data?
* **Import & Export**:
  * Do we need to add this new field to CSV/Excel export templates?
  * Does the CSV/Excel file import parser need to read this new column?
* **Legacy State**:
  * How does the system handle old database records that have a empty (`NULL`) value for this new field?
  * Does the UI render a safe fallback text (like "N/A" or "Not Provided")?

---

## 3. Operational Capacity & Cost Impact
*How the database locks, CPU usage, and hosting costs change.*

* **Database Load & Locking**:
  * Will this query require a heavy table scan or complex SQL JOINs?
  * Does this operation lock database rows and make other users wait?
* **Background Tasks**:
  * Will this trigger a slow task that should run in the background (like sending emails or syncing files)?
  * Can the background system handle a sudden burst of many tasks?
* **Cloud Storage & API Costs**:
  * Does this feature use paid third-party APIs (like Google Geocoding or SMS gateways)?
  * Will it store large, uncompressed media files in cloud storage?
* **Memory & CPU limits**:
  * Does this logic use loops over thousands of items in memory?

---

## 4. User Friction & Cognitive Load
*How simple the interface stays for users and if we need to update help documents.*

* **Form Layout**:
  * Is the new field required or optional? Is the validation error easy to understand?
  * Are there too many fields on the page now, making it look busy?
* **Onboarding & Help**:
  * Do we need to add a tooltip, placeholder text, or help banner?
  * Do we need to update user instruction manuals?
* **Workflow Steps**:
  * Does the user need to click or tap more times to finish their work?
  * Is there a way to auto-fill or suggest values to save them time?
* **Error Recovery**:
  * If a system error occurs (like going offline), does the app tell the user how to retry without losing their input?

---

## 5. Business Operational Impact
*How it affects customer support workers, sales teams, and marketing.*

* **Support Center Workload**:
  * Will customer support receive more phone calls/tickets if this feature is confusing?
  * Do we need to write a "Known Issues" guide for support agents?
* **Configuration Steps**:
  * Do admins need to configure anything manually in the backend before a customer can use this?
* **Legal & Terms**:
  * Does this feature change our user agreement or privacy policies?
* **Sales Training**:
  * Do the sales and marketing teams need training to show this feature to prospects?

---

## 6. Regulatory, Privacy, & Security Compliance
*Checking if data laws are met and if we have secure access logs.*

* **Personal Data (PII)**:
  * Are we storing personal information (like home addresses, GPS locations, or phone numbers)?
  * Are these fields encrypted or hidden from unauthorized employees?
* **Access Logging (Audit Trail)**:
  * Do we record who viewed or edited this specific data, along with a timestamp?
* **Data Deletion**:
  * Do we have a way to permanently delete this user data if they request to close their account?
* **Security Guardrails**:
  * Are all user inputs sanitized to prevent code injection?
  * Are we verifying authorization tokens on every request?
