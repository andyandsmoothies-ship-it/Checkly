# Checkly Admin Setup Guide: Supported Audit & Checklist Use Cases

This document is the **Expert Administrator's Guide** to setting up templates in Checkly. By combining different Scoring Modes, Input Types, and Section Hierarchies, you can build templates for nearly any industry use case.

---

## Core System Capabilities

| Feature | Options |
|---------|---------|
| **Scoring Modes** | Penalty (Top-Down), Accumulation (Zero-to-Top), Checklist (Flat Deduction), Survey (No Scoring) |
| **Input Types** | Pass/Fail (e.g., Is the floor clean?), Fault Count (e.g., How many expired items?), Scored Choices (e.g., Poor/Fair/Good), Single Choice (e.g., Which shift?), Multi Choice (e.g., Select all that apply) |
| **Hierarchy** | 2-level (Section → Criteria) or 3-level (Section → Sub-section → Criteria) |
| **Critical Failure** | CCP (Zeros the section), RISK (Zeros the entire audit) |
| **Other Modifiers** | Progressive Repeat Penalty, Confirm Correct, Weighted Density |
| **Analytics** | Survey Results — aggregated option distribution per question (admin-only) |

---

## 🔴 PENALTY MODE (Top-Down Compliance)
*Start at max points. Deduct points for every fault found. Used for strict regulatory and operational compliance.*

### 1. Food Safety / HACCP Audit (F&B, Restaurants)
**Goal:** Mathematically rigorous food safety inspection where critical health violations result in immediate failure.

**Admin Setup Workflow:**
1. **Scoring Mode:** Select `Penalty (Top-Down)`.
2. **Hierarchy:** 3-Level (e.g., Section: Kitchen → Sub-section: Fridge 1 → Criteria: Temp < 4°C).
3. **Criteria Input Type:** `Fault Count` — auditor counts the number of faults found.
4. **Flags:**
   * Enable `CCP` on major health risks (e.g., pests, extreme temp). CCP triggered → Section score = 0.
   * Enable `RISK` on catastrophic failures (e.g., no running water). RISK triggered → Entire audit = 0%.
5. **Scoring Rules:**
   * Enable `Progressive Repeat Penalty` — escalates deductions if the same store fails the same criteria again.
   * Enable `Weighted Density` — kitchen sections weigh more than dining area.

### 2. Store Condition Audit (Retail)
**Goal:** Evaluate appearance, stock levels, and cleanliness of a retail location.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Penalty (Top-Down)`.
2. **Hierarchy:** 2-Level (Section: Entrance → Criteria: Windows Clean).
3. **Criteria Input Type:** `Pass / Fail`.
4. **Points:** Assign weights relative to importance (e.g., Storefront Signage = 5pts, Trash Can = 1pt).
5. **Scoring Rules:** Enable `Weighted Density` (e.g., Shop Floor = 70%, Backroom = 30%).

### 3. Construction Site Safety (Construction)
**Goal:** Strict adherence to safety protocols with zero tolerance for life-threatening violations.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Penalty (Top-Down)`.
2. **Hierarchy:** 2-Level.
3. **Criteria Input Type:** `Pass / Fail`.
4. **Flags:** Heavy use of `RISK` tags (e.g., "Workers not wearing harnesses at height" = RISK → instant audit failure).
5. **Scoring Rules:** Enable `Progressive Repeat Penalty` for recurring violations.

### 4. Mystery Shopper (F&B, Retail)
**Goal:** Grade the customer experience across service dimensions using a quality gradient.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Penalty (Top-Down)`.
2. **Criteria Input Type:** `Fault Count` — auditor records deduction per observation.
3. **Scoring Rules:** Enable `Weighted Density` (e.g., Service 40%, Food 35%, Ambiance 25%).

---

## 🟢 ACCUMULATION MODE (Zero-to-Top)
*Start at zero. Earn points for correct answers. Score = (Earned / Possible) × 100.*

### 5. Employee Training Quiz (HR, Any Industry)
**Goal:** Test a new employee's knowledge after an onboarding session.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Accumulation (Zero-to-Top)`.
2. **Hierarchy:** 2-Level (Section: Company Policy → Criteria: "When was the company founded?").
3. **Criteria Input Type:** `Pass / Fail` — trainer taps Pass if answered correctly.
4. **Points:** Assign 1 or 2 points per question.
5. **Result:** Score = (Points Earned / Total Possible) × 100.

### 6. Food Handler Certification (F&B)
**Goal:** A scored test where failing a single critical hygiene question invalidates the entire category.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Accumulation (Zero-to-Top)`.
2. **Criteria Input Type:** `Pass / Fail`.
3. **Flags:** Mark critical questions (e.g., "Hands washed after handling raw meat?") as `CCP`.
4. **Expert Note:** Even in Accumulation mode, triggering CCP wipes the earned points for that entire section to 0, correctly failing the candidate on that topic.

### 7. Warehouse Inventory Audit (Logistics)
**Goal:** Count and score items per warehouse zone, with zones weighted by value.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Accumulation (Zero-to-Top)`.
2. **Hierarchy:** 3-Level (Section: Zone A → Sub-section: Rack 1 → Criteria: Item count verified).
3. **Criteria Input Type:** `Pass / Fail`.
4. **Scoring Rules:** Enable `Weighted Density` — high-value zones weigh more.

### 8. ISO Maturity Assessment (Manufacturing, IT)
**Goal:** Assess process maturity across departments using a capability scale.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Accumulation (Zero-to-Top)`.
2. **Hierarchy:** 3-Level (Department → Process Area → Individual Capability).
3. **Criteria Input Type:** `Pass / Fail` (see limitation below).

> [!TIP]
> **Scored Choices input fully supported.** Both the client-side scoring engine and the server-side `FinalizeSubmission` verifier correctly handle `inputType: "scale"` in Accumulation mode. Scored Choices criteria award partial credit based on the selected option's `numericValue`. Verified by client test V16 and server `ScoringVerifier` backward-compatible dispatch.

---

## 🔵 CHECKLIST MODE (Flat Deduction)
*Start at 100%. Each fault deducts (faults × point weight) from the total. No section weighting.*

### 9. Daily Opening / Closing Checklist (Retail, F&B)
**Goal:** Ensure staff complete all required operational tasks before opening or leaving.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Checklist (Pass/Fail)`.
2. **Hierarchy:** 2-Level for speed.
3. **Criteria Input Type:** `Pass / Fail`.
4. **Points:** Set all weights to `1` for a simple tally where each fault deducts equally.
5. **Expert Note:** Points weights still affect deduction magnitude in this mode. If you want all failures to count equally, ensure all criteria have the same weight.

### 10. Shift Handover Checklist (Manufacturing, Hospitals)
**Goal:** Chain of custody where a manager explicitly verifies critical tasks before changing shifts.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Checklist (Pass/Fail)`.
2. **Criteria Input Type:** `Fault Count` — use when they need to input a value (e.g., "Fridge Temperature").
3. **Scoring Rules:** Enable `Confirm Correct` — forces the user to explicitly tap a "Standard Verified" button for every passing item, ensuring physical interaction with the checklist.

### 11. Safety Equipment Verification (Any Industry)
**Goal:** Routine daily walk-around to check fire extinguishers, first aid kits, etc.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Checklist (Pass/Fail)`.
2. **Criteria Input Type:** `Pass / Fail`.
3. **Flags:** Mark "Fire Extinguisher Valid" as `RISK` — if failed, entire audit becomes 0%, flagging it immediately.

### 12. Pre-Flight Aircraft Checklist (Aviation, Transport)
**Goal:** Mandatory pre-departure check where any single failure grounds the vehicle.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Checklist (Pass/Fail)`.
2. **Criteria Input Type:** `Pass / Fail`.
3. **Flags:** Apply `RISK` to every critical item (engine, brakes, lights). Any failure = immediate 0%.

---

## 🟣 SURVEY MODE (No Scoring)
*Collect qualitative feedback without numerical scoring. Answers are aggregated into response analytics.*

### 13. Employee Satisfaction Survey (HR)
**Goal:** Gather anonymous feedback on workplace conditions, management, and culture.

**Admin Setup Workflow:**
1. **Scoring Mode:** Select `Survey (No Scoring)`.
2. **Hierarchy:** 2-Level (Section: Work Environment → Criteria: "How satisfied are you with your workspace?").
3. **Criteria Input Type:** `Single Choice` — options like "Very Satisfied", "Satisfied", "Neutral", "Dissatisfied".
4. **Result:** No score is calculated. Admin views aggregated response distribution via **Survey Results** page.

### 14. Customer Feedback Form (Retail, F&B)
**Goal:** Collect customer opinions across multiple service dimensions.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Survey (No Scoring)`.
2. **Hierarchy:** 2-Level (Section: Service → Criteria: "What aspects did you enjoy?").
3. **Criteria Input Type:** `Multi Choice` — options like "Friendly Staff", "Fast Service", "Clean Environment", "Good Value".
4. **Analytics:** Admin navigates to Template Detail → **View Survey Results** to see option distribution with percentages.

### 15. Post-Training Feedback (HR, Any Industry)
**Goal:** Collect trainee reactions after a training session.

**Admin Setup Workflow:**
1. **Scoring Mode:** `Survey (No Scoring)`.
2. **Criteria Input Type:** Mix of `Single Choice` (rating questions) and `Multi Choice` ("Which topics were most useful?").
3. **Choice Options:** Configure 3-5 options per question in the Template Builder's "Choice Options" editor.
4. **Expert Note:** Survey submissions appear on the History page with a purple **SURVEY** badge instead of a score. Points weight is hidden for choice-type criteria.

---

## ✅ Resolved: Scale Scoring (Client + Server)

| Component | Fix | Verified |
|-----------|-----|----------|
| **Client** (`scoring_engine.dart`) | `_calculateAccumulation()` branches on `inputType == 'scale'` to treat `numericValue` as earned points | Test V16 |
| **Server** (`ScoringVerifier.cs`) | `VerifyAccumulation()` mirrors client logic — `inputType == "scale"` → `numericValue` as earned points | `dotnet build` ✅ |
| **Server** (`FinalizeSubmission.cs`) | Parses `scoringMode` from `template.ScoringLogicConfig` JSON, passes to `scorer.Verify()` | Backward-compatible default: `"penalty"` |

> [!NOTE]
> Source: [Sentinel Audit Findings #3 and #5](file:///C:/Users/HP/.gemini/antigravity/brain/1625bb51-f67a-4822-aaa2-2998d745d964/audit_infra_report_20260317.md.resolved) — both resolved.

