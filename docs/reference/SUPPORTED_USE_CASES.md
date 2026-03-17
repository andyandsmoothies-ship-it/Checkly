# Checkly Admin Setup Guide: Supported Audit & Checklist Use Cases

This document is the **Expert Administrator's Guide** to setting up templates in Checkly. By combining different Scoring Modes, Input Types, and Section Hierarchies, you can build templates for nearly any industry use case.

---

## Core System Capabilities

| Feature | Options |
|---------|---------|
| **Scoring Modes** | Penalty (Top-Down), Accumulation (Zero-to-Top), Checklist (Flat Deduction) |
| **Input Types** | Pass/Fail (Binary), Numeric (Fault counting + Repeats), Scale (Admin-defined gradient) |
| **Hierarchy** | 2-level (Section → Criteria) or 3-level (Section → Sub-section → Criteria) |
| **Critical Failure** | CCP (Zeros the section), RISK (Zeros the entire audit) |
| **Other Modifiers** | Progressive Repeat Penalty, Confirm Correct, Weighted Density |

---

## 🔴 PENALTY MODE (Top-Down Compliance)
*Start at max points. Deduct points for every fault found. Used for strict regulatory and operational compliance.*

### 1. Food Safety / HACCP Audit (F&B, Restaurants)
**Goal:** Mathematically rigorous food safety inspection where critical health violations result in immediate failure.

**Admin Setup Workflow:**
1. **Scoring Mode:** Select `Penalty (Top-Down)`.
2. **Hierarchy:** 3-Level (e.g., Section: Kitchen → Sub-section: Fridge 1 → Criteria: Temp < 4°C).
3. **Criteria Input Type:** `Numeric (Faults)` — auditor counts the number of faults found.
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
2. **Criteria Input Type:** `Numeric (Faults)` — auditor records deduction per observation.
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

> [!CAUTION]
> **Scale input type + Accumulation has a known scoring gap.** The engine currently treats `numericValue` as fault count, not earned points, so Scale criteria with partial credit (e.g., "Good = 5pts") will score incorrectly. Use Pass/Fail input type with Accumulation until the engine fix is applied. See [Engine Fix Required](#engine-fix-required) below.

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
2. **Criteria Input Type:** `Numeric (Faults)` — use when they need to input a value (e.g., "Fridge Temperature").
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

## Engine Fix Required

### Accumulation + Scale Partial Credit Bug

**Problem:** When a Scale criterion sets `numericValue: 5` (meaning "earned 5 points"), the Accumulation engine misreads it as "5 faults" and awards 0 points.

**Root Cause:** [_calculateAccumulation()](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/_shared/services/scoring_engine.dart#L312-393) line 356-360 checks `faults == 0` to award full points. Scale's `numericValue` (earned) is indistinguishable from Numeric's `numericValue` (faults).

**Impact:** Use Cases using Accumulation + Scale (Performance Reviews, ISO Maturity) will produce incorrect scores.

**Fix:** Update `_calculateAccumulation()` to check the criterion's `inputType`. If `scale`, treat `numericValue` as earned points directly instead of checking for zero faults.

```dart
// Current (broken for scale):
if (faults == 0 && !isNonConform && answer.repeatedFaults == 0) {
  sectionEarned += c.pointsWeight;
}

// Fixed:
if (c.inputType == 'scale' && answer.numericValue != null) {
  sectionEarned += answer.numericValue!;  // Use selected option's points
} else if (faults == 0 && !isNonConform && answer.repeatedFaults == 0) {
  sectionEarned += c.pointsWeight;  // Binary: full or nothing
}
```

**Requires:** Adding `inputType` field to `CriterionInput` model in `scoring_engine.dart`.
