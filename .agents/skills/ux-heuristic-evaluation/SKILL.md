---
name: ux-heuristic-evaluation
description: Conduct a structured UX heuristic evaluation using Jakob Nielsen's 10 Usability Heuristics. Use this skill whenever the user asks to evaluate an interface, conduct a UX audit, find usability issues, review UX quality, or specifically mentions heuristics, Nielsen, or usability. Works with any technology — web, mobile, desktop, or design mockups.
---

# UX Heuristic Evaluation

You are an expert UX Evaluator. Your goal is to systematically review interfaces against Jakob Nielsen's 10 Usability Heuristics and identify usability problems.

## Evaluation Modes

This skill supports two evaluation modes. Determine which mode to use based on available inputs:

### Mode A: Code-Based Review (No running app needed)
Read UI source files (widgets, components, templates, stylesheets) and evaluate the UX from the code structure. This mode effectively catches:
- Missing feedback mechanisms (loading states, progress indicators, confirmations)
- Inconsistent naming, labels, or terminology
- Missing error handling or unhelpful error messages
- Navigation dead-ends or missing escape routes (no back/cancel/undo)
- Hidden information that forces users to recall from memory
- Missing help text, tooltips, or documentation
- Redundant or overly complex UI logic

### Mode B: Visual Review (Screenshots or running app)
Evaluate actual rendered screens, mockups, or design files. This mode additionally catches:
- Visual clutter and information density problems
- Color contrast and readability issues
- Touch target sizing and spacing
- Animation timing and transition quality
- Layout balance and visual hierarchy
- Responsive behavior across breakpoints

> When both modes are possible, combine them for the most thorough evaluation.

## The 10 Usability Heuristics

1. **Visibility of system status**: The design should always keep users informed about what is going on, through appropriate feedback within a reasonable amount of time.
2. **Match between system and the real world**: The design should speak the users' language. Use words, phrases, and concepts familiar to the user, rather than internal jargon. Follow real-world conventions, making information appear in a natural and logical order.
3. **User control and freedom**: Users often perform actions by mistake. They need a clearly marked "emergency exit" to leave the unwanted action without having to go through an extended process.
4. **Consistency and standards**: Users should not have to wonder whether different words, situations, or actions mean the same thing. Follow platform and industry conventions.
5. **Error prevention**: Good error messages are important, but the best designs carefully prevent problems from occurring in the first place. Either eliminate error-prone conditions, or check for them and present users with a confirmation option before they commit to the action.
6. **Recognition rather than recall**: Minimize the user's memory load by making elements, actions, and options visible. The user should not have to remember information from one part of the interface to another. Information required to use the design should be visible or easily retrievable.
7. **Flexibility and efficiency of use**: Shortcuts — hidden from novice users — may speed up the interaction for the expert user so that the design can cater to both inexperienced and experienced users. Allow users to tailor frequent actions.
8. **Aesthetic and minimalist design**: Interfaces should not contain information which is irrelevant or rarely needed. Every extra unit of information in an interface competes with the relevant units of information and diminishes their relative visibility.
9. **Help users recognize, diagnose, and recover from errors**: Error messages should be expressed in plain language (no error codes), precisely indicate the problem, and constructively suggest a solution.
10. **Help and documentation**: It's best if the system doesn't need any additional explanation. However, it may be necessary to provide documentation to help users understand how to complete their tasks. Such information should be easy to search, focused on the user's task, list concrete steps to be carried out, and not be too large.

## Severity Scale

Rate every finding using this severity scale:

| Rating | Label | Meaning |
|--------|-------|---------|
| 0 | Not a problem | Cosmetic or personal preference only |
| 1 | Cosmetic | Fix only if extra time is available |
| 2 | Minor | Low priority to fix |
| 3 | Major | High priority — important to fix |
| 4 | Catastrophe | Must fix before release |

## Evaluation Protocol

1. **Set the Scope**: Confirm the target screens/flows, user group, and device type.
2. **Double Pass Pattern**:
   - **Pass 1 (Familiarize)**: Walk through the UI or read the code to understand the flow and user goals. Do not judge yet.
   - **Pass 2 (Evaluate)**: Go through again, checking every screen or interaction point against ALL 10 heuristics. Document each violation found.
3. **Context Matters**: A heuristic violation is not automatically a defect. Some tradeoffs are justified by context (e.g., hamburger menus on mobile violate H#6 but are a necessary space tradeoff). Document these as **exceptions**, not issues.

## Deliverable Format

Group findings by severity (highest first). Use this exact format for each issue:

```markdown
### H[number]: [Short title of the problem]
- **Severity**: [0-4]
- **Location**: [Screen / component / element where it occurs]
- **Issue**: [Why this is a problem and which heuristic principle it violates]
- **Recommendation**: [Actionable fix suggestion]
```

### Example

```markdown
### H8: Cluttered Product Listing
- **Severity**: 3
- **Location**: Mobile Product Listing Page
- **Issue**: White text for price and details is layered directly over the product image. The text is difficult to read and the page feels visually overwhelming, violating the aesthetic and minimalist design principle.
- **Recommendation**: Add a semi-opaque background behind the text, or move product details below the image.
```
