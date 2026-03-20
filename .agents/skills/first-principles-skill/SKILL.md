---
name: First Principles Thinking
description: This skill should be used when the user asks to "analyze from first principles", "第一性原理", "从根本分析", "think from scratch", "question this design", "is this the right approach", "why are we doing it this way", or needs to evaluate architectural decisions, design choices, or problem-solving approaches without relying on analogies or conventions. Make sure to use this skill whenever the user mentions "best practices," "industry standards," or "everyone else does it this way" as their sole justification for a complex decision.
version: 1.0.0
---

# First Principles Thinking (Software Engineering Edition)

Software engineering is prone to "analogy traps"—adopting patterns (microservices, K8s, NoSQL) because "big companies do it" rather than because the problem demands it. This skill provides a systematic framework to strip away abstractions and reason from **Engineering Ground Truths**.

## When to Use

- **Architecture Setup**: Choosing a tech stack or database model for a new project.
- **Complexity Audit**: When a solution feels "top-heavy" or harder to maintain than it should be.
- **Refactoring Strategy**: Deciding whether to fix a legacy system or rebuild it.
- **Performance/Scalability**: When conventional optimizations fail and a foundational rethink is needed.
- **"Best Practice" Conflict**: When industry standards contradict the specific constraints of the project.

## Core Process: The Zero-Based Design Loop

### Phase 1: Deconstruct (Peeling the Semantic Onion)
Peel away the layers of "How" until you reach the irreducible "What."

1. **The Analogy Layer**: Remove all references to other companies/projects ("Like Uber for X").
2. **The Framework Layer**: Remove specific technologies (e.g., "We need a React Hook").
3. **The Abstraction Layer**: Remove names of patterns (e.g., "We need a Factory").

**Fundamental Question**: "If we only had a CPU, memory, and a network socket, what is the absolute minimum sequence of bytes that must move to achieve the goal?"

### Phase 2: Identify Engineering Ground Truths
Identify the constraints that **cannot be negotiated**.

| Category | Search for These Truths |
|----------|-------------------------|
| **Data** | What is the source of truth? What is the required consistency (ACID vs. BASE)? |
| **State** | Is it ephemeral or persistent? Who owns it? How does it survive a crash? |
| **Compute** | What is the time complexity (Big O)? Is it I/O bound or CPU bound? |
| **Network** | CAP Theorem constraints: In a partition, do we favor Consistency or Availability? |
| **User** | What is the ONE action the user cares about? Everything else is secondary. |

### Phase 3: Reason Upward (Earned Complexity)
Start from a blank canvas. Every line of code, every library, and every architectural layer must **earn its way into the project**.

1. **The Minimal Viable Path (MVP)**: Design the simplest possible way to satisfy the Ground Truths.
2. **The Friction Test**: Add a layer (e.g., an ORM or a UI library) ONLY if the manual cost of living without it is higher than the maintenance cost of owning it.
3. **The Complexity Tax**: Acknowledge the "tax" for every abstraction (cognitive load, build time, dependency risk).

## SE Patterns & Anti-Patterns

### Pattern: The Analogy Trap (Cargo Culting)
- **Symptom**: "We need microservices because Netflix used them for scale."
- **First Principles Check**: Netflix had 1,000+ engineers and millions of CCU. We have 5 engineers and 1,000 users. Our ground truth is **Velocity/Maintainability**, not **Extreme Isolation**.
- **Action**: Use a monolith until the Ground Truth of "Deployment Conflict" forces a split.

### Pattern: The Legacy Trap (Sunken Cost)
- **Symptom**: "We must keep using this slow XML parser because the whole system depends on it."
- **First Principles Check**: What is the **Ground Truth cost** of maintaining the parser vs. the **one-time cost** of an automated migration?
- **Action**: If the slope of maintenance cost is > migration cost, the "compatibility" assumption is false.

### Pattern: The Resume-Driven Design (RDD)
- **Symptom**: Introducing a complex new framework for a simple CRUD app.
- **First Principles Check**: Does the framework solve a *data* problem or a *developer-experience* problem? If the latter, does it violate the project's **Timeline/Simplicity** invariants?

## Output Structure: The First Principles Brief

When a user asks for a foundational analysis, use this exact template:

```markdown
# First Principles Analysis: [Topic]

## 1. The Raw Requirement
- What is the job to be done? (Sans technical jargon)
- **Success Criteria**: [Measurable outcomes, e.g., <200ms latency, 99.9% uptime]

## 2. Challenged Assumptions
| Assumption | Source | The "Why" Challenge | Verdict |
|------------|--------|---------------------|---------|
| [e.g. Needs DB] | [Convention] | Is a file system enough? | [Discarded] |

## 3. Engineering Ground Truths
- **Data Invariant**: [e.g. Loss of record X is a total business failure]
- **Resource Constraint**: [e.g. Limited to 512MB RAM on edge devices]
- **State Ownership**: [e.g. Stateless at the edge, eventually consistent at core]

## 4. The "Zero-Based" Reconstruction
1. **The Minimal Path**: [Description of the absolute simplest fix]
2. **Justified Additions**: [What we added back and why it earned its place]

## 5. First Principles Verdict
**Recommendation**: [Clear technical direction]
**Key Insight**: [The "aha!" moment where the analogy broke]
```

## Boundaries

- **DO** be ruthless. Better to be simple and "wrong" according to industry trends than complex and "right" for a problem you don't have.
- **DO** acknowledge the "Team-Focused Development" (T*D) principle: a perfectly optimized architecture that the team can't maintain is a failure.
- **DO NOT** spend 4 hours analyzing a 10-minute feature. Reserve First Principles for "High Blast Radius" decisions.
- **DO NOT** discard libraries meant for safety (e.g., encryption, auth) unless you are an expert in that specific ground truth.

## Checklist for Technical Due Diligence
- [ ] Have I explained the "Why" behindEvery Ground Truth?
- [ ] Did I identify the "Minimal Path" before adding abstractions?
- [ ] Is my recommendation based on our specific data/state/user constraints?
- [ ] Did I name the specific analogy I am rejecting?

