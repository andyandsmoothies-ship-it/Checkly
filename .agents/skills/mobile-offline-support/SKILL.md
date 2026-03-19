---
name: mobile-offline-support
---
name: mobile-offline-support
description: >
  Implement offline-first mobile apps with local storage, sync strategies, and
  conflict resolution. Covers AsyncStorage, Realm, SQLite, and background sync
  patterns.
---

# Mobile Offline Support

## When to Use

- Building apps that must work without internet
- Implementing sync-on-reconnect strategies
- Handling data conflicts between device and server
- Optimizing responsiveness with local-first reads

## Decision Guide

| Scenario | Storage | Sync Strategy |
|----------|---------|---------------|
| Simple key-value cache | **AsyncStorage** | Stale-while-revalidate |
| Structured data, complex queries | **SQLite / Drift** | Delta sync with timestamps |
| Large datasets, relationships | **Realm** | Realm Sync (built-in) |
| Documents / JSON blobs | **WatermelonDB** | Push-based with conflict resolution |
| Binary files (photos, PDFs) | **File system + metadata in DB** | Upload queue with retry |

### Conflict Resolution Strategies

| Strategy | When to Use |
|----------|------------|
| **Last-write-wins** | Simple data, single-user editing |
| **Server-wins** | Admin-controlled data, compliance scenarios |
| **Client-wins** | Offline-first with user as authority |
| **Merge** | Collaborative editing (complex, use CRDTs) |
| **Manual resolution** | Business-critical data, show diff to user |

**Key insight:** Most apps need "last-write-wins" with a mutation queue. CRDTs and manual merge are rarely worth the complexity unless you have true multi-user collaboration.

## Reference Guides

Detailed implementations in the `references/` directory:

| Guide | Contents |
|---|---|
| [React Native Offline Storage](references/react-native-offline-storage.md) | React Native Offline Storage |
| [iOS Core Data Implementation](references/ios-core-data-implementation.md) | iOS Core Data Implementation |
| [Android Room Database](references/android-room-database.md) | Android Room Database |
