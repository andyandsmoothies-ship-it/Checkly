# Walkthrough: BOD Analytics Slice 6 & 7 Implementation

## Overview

This walkthrough documents the technical details and visual specifications for the implementation of **Slice 6 (AP Aging TTR Indicator & Drill-Down Sheet)** and **Slice 7 (Smooth Trend Curve with 3-Month SMA)** in the Checkly Boardroom Analytics Dashboard.

---

## Slice 6: Action Plan (AP) Aging & Drill-Down UI

We added premium visual components and microinteractions to make the Action Plan card incredibly rich:

1. **AP Aging TTR (Time to Resolve) Badge**:
   - Computes average resolution time (`averageResolutionTimeHours`).
   - Standard 48-hour SLA threshold.
   - Dynamic colors: Sleek pastel green (`#E8F5E9` background, `#2E7D32` text) if average resolution is $\le 48\text{h}$, and Warning Amber/Orange (`#FFF3E0` background, `#EF6C00` text) if $> 48\text{h}$.
   - Displays a clock icon next to the resolution text.

2. **AP Drill-Down Sheet (Bottom Sheet Modal)**:
   - When the user taps the Action Plan card, a beautiful styled modal pops up using Flutter's native `showModalBottomSheet`.
   - Incorporates **StrokeCard** and **PillChip** design primitives.
   - Shows detailed metrics: Total Active Plans, Avg Resolution, Overdue count.
   - A scrollable list of recent/relevant Action Plans with their status pill.

---

## Slice 7: Smooth Trend Curve (3-Month Simple Moving Average)

To help managers observe trend changes without short-term volatility, we implemented an overlay trend line:

1. **3-Month Simple Moving Average (SMA)**:
   - Evaluated dynamically in Dart from the retrieved trends array.
   - For each month, calculates the moving average of the current month and the past 2 months (window of 3).
   - Gracefully handles cold-start scenarios: if fewer than 3 months of data exist, averages whatever is available.

2. **UI Integration**:
   - The boardroom trend line chart displays the raw weekly/monthly trend as a primary color line.
   - Installs an elegant dashed secondary line representing the 3-Month SMA overlay.
   - A mini interactive legend enables toggling the SMA overlay visibility.

---

## Verification and Quality Checks

All integration and widget tests were run and validated:
- **Total Backend Tests**: 544 Passed, 0 Failed, 7 Skipped.
- **Flutter Widget/Integration Tests**: Compile and pass without errors.
- **Performance**: High performance with zero UI lag, compliance with reduced-motion media query checks.
