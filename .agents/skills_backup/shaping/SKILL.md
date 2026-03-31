---
name: shaping
description: Iterate on both the problem and the solution before committing to implementation. Use the Requirements → Shapes → Fit Check workflow to evaluate solution options against constraints. Load this skill when the user mentions "shaping", "fit check", "requirements vs shapes", "decision matrix", or needs to compare alternative solutions before coding.
---

# Shaping

## Philosophy
**Iterate on both the problem and the solution before committing to implementation.**

Shaping separates *what* you need (Requirements) from *how* you might build it (Shapes). It uses a **Fit Check** to prove that a proposed solution covers all requirements without gaps.

## Core Concepts

### R: Requirements
- Define the need or constraint.
- Focus on outcomes and user goals.
- Example: `R1: Auditor must verify GPS location before starting.`

### S: Shapes (Solution Options)
- Describe the concrete mechanisms that satisfy requirements.
- Avoid tautologies (S should add information to R).
- Example: `S1: Use useGps hook to fetch coords, block Start button if accuracy > 100m.`

### Fit Check (Decision Matrix)
The single table comparing all shapes against all requirements.

| Requirement | Shape A | Shape B |
|-------------|:-------:|:-------:|
| **R1**      | ✅      | ❌      |
| **R2**      | ✅      | ✅      |

---

## Workflow

### 1. Requirements (R)
List the constraints and user needs. Be exhaustive.

### 2. Shapes (S)
Sketch out 1-3 alternative mechanisms. Each part must be a **mechanism** (how it works), not just an intent.

### 3. Fit Check
Map R to S. If a requirement is ❌, the shape is incomplete. Resume shaping or accept the gap.

### 4. Detail X
Once a shape is selected, detail its mechanisms using hierarchical notation (**S1.1**, **S1.2**...).

---

## Rules
- **Flag Unknowns (⚠️)**: If you describe WHAT but don't know HOW, flag it. Flags = ❌ in fit check.
- **Vertical Slicing**: Group mechanisms with the data they need (e.g., table + handler logic).
- **Hierarchical Notation**: Start flat (E1, E2...). Group into sub-parts (E1.1, E1.2...) only when mature.
- **No Tautologies**: If S says exactly what R says, the shape is too thin. Add concrete implementation detail.
