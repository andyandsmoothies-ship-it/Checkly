---
---
name: frontend-state-management
description: >
  Manage application state using Redux, MobX, Zustand, and Context API. Use when
  centralizing state for complex applications with multiple components.
---

# Frontend State Management

## When to Use

- Complex application state shared across many components
- Predictable state mutations with time-travel debugging
- Server state synchronization and caching

## Decision Guide

| Scenario | Tool | Why |
|----------|------|-----|
| Simple shared state (theme, auth) | **Context API** | No extra dependency, built into React |
| Medium app, few global states | **Zustand** | Tiny API, no boilerplate, hooks-based |
| Large app, complex state graph | **Redux Toolkit** | Devtools, middleware, time-travel debugging |
| Observable/reactive patterns | **MobX** | Auto-tracking, minimal boilerplate, OOP-friendly |
| Server state (fetching, caching) | **TanStack Query** | Not a state manager — handles server state separately |
| Form state | **React Hook Form** | Don't put form state in global store |

**Key insight:** Most apps need both a *server state* tool (TanStack Query) and a *client state* tool (Zustand/Context). Putting everything in Redux is the most common mistake.

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [Redux with Redux Toolkit (React)](references/redux-with-redux-toolkit-react.md) | Redux with Redux Toolkit (React) |
| [Zustand (Lightweight State Management)](references/zustand-lightweight-state-management.md) | Zustand (Lightweight State Management) |
| [Context API + useReducer](references/context-api-usereducer.md) | Context API + useReducer |
| [MobX (Observable State)](references/mobx-observable-state.md) | MobX (Observable State) |
