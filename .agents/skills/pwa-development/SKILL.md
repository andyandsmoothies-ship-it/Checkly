---
name: pwa-development
description: Load this skill whenever building or debugging PWA features, offline capabilities, service workers, web app manifests, or Workbox caching strategies.
---

# PWA Development Skill

*Load with: base.md*

**Purpose:** Build Progressive Web Apps that work offline, install like native apps, and deliver fast, reliable experiences across all devices.

---

## Core PWA Requirements

```
┌─────────────────────────────────────────────────────────────────┐
│  THE THREE PILLARS OF PWA                                       │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  1. HTTPS                                                       │
│     Required for service workers and security.                  │
│     localhost allowed for development.                          │
│                                                                 │
│  2. SERVICE WORKER                                              │
│     JavaScript that runs in background.                         │
│     Enables offline, caching, push notifications.               │
│                                                                 │
│  3. WEB APP MANIFEST                                            │
│     JSON file describing app metadata.                          │
│     Enables installation and app-like experience.               │
├─────────────────────────────────────────────────────────────────┤
│  INSTALLABILITY CRITERIA (Chrome)                               │
│  ─────────────────────────────────────────────────────────────  │
│  • HTTPS (or localhost)                                         │
│  • Service worker with fetch handler                            │
│  • Web app manifest with: name, icons (192px + 512px),          │
│    start_url, display: standalone/fullscreen/minimal-ui         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Web App Manifest

The Web App Manifest is a JSON file that tells the browser how your PWA should behave when installed on the user's desktop or mobile device.

► **[View Required Fields & Examples](references/manifests.md)**

---

## Service Worker Patterns & Caching Strategies

Service workers are at the core of PWAs, enabling offline experiences, periodic background syncs, and push notifications.

► **[View Service Worker & Caching Examples](references/service-workers.md)**

---

## Workbox (Recommended)

Workbox is a set of libraries that can power a production-ready service worker for your PWA.

► **[View Workbox Setup Guides](references/workbox.md)**

---

## Offline Experience

Handling network states gracefully and providing offline fallbacks.

► **[View Offline Detection & Background Sync Guides](references/offline.md)**

---

## App-Like Features & Performance Optimization

Install prompts, push notifications, and Web Vitals optimizations.

► **[View Install, Push, & Performance Guides](references/app-features.md)**

---

## Testing PWA

### Lighthouse Audit

```bash
# Run Lighthouse from CLI
npx lighthouse https://your-app.com --view

# Key metrics to check:
# - PWA badge (installable, offline-ready)
# - Performance score
# - Best practices
# - Accessibility
```

### Manual Testing Checklist

- [ ] **Installability**
  - [ ] Install prompt appears on desktop Chrome
  - [ ] Can be added to home screen on mobile
  - [ ] App opens in standalone mode after install

- [ ] **Offline Support**
  - [ ] App loads when offline (airplane mode)
  - [ ] Cached pages display correctly
  - [ ] Offline fallback page shows for uncached routes
  - [ ] Background sync works when coming back online

- [ ] **Performance**
  - [ ] First Contentful Paint < 1.8s
  - [ ] Largest Contentful Paint < 2.5s
  - [ ] Time to Interactive < 3.8s
  - [ ] Cumulative Layout Shift < 0.1

- [ ] **Service Worker**
  - [ ] SW registers successfully
  - [ ] Static assets cached on install
  - [ ] SW updates correctly (new version)
  - [ ] No stale cache issues

- [ ] **Manifest**
  - [ ] All required fields present
  - [ ] Icons display correctly
  - [ ] Theme color applied
  - [ ] Splash screen shows on launch

### Testing Service Worker Updates

```javascript
// Force update check
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.ready.then((registration) => {
    registration.update();
  });
}

// Listen for updates
navigator.serviceWorker.addEventListener('controllerchange', () => {
  // New service worker activated
  window.location.reload();
});
```

---

## Project Structure

```
project/
├── public/
│   ├── manifest.json           # Web app manifest
│   ├── sw.js                   # Service worker (if not bundled)
│   ├── offline.html            # Offline fallback page
│   ├── robots.txt
│   └── icons/
│       ├── icon-72.png
│       ├── icon-96.png
│       ├── icon-128.png
│       ├── icon-144.png
│       ├── icon-152.png
│       ├── icon-192.png
│       ├── icon-384.png
│       ├── icon-512.png
│       ├── icon-maskable.png   # For adaptive icons
│       ├── apple-touch-icon.png
│       └── favicon.ico
├── src/
│   ├── sw.js                   # Service worker source (if bundled)
│   ├── pwa/
│   │   ├── install.js          # Install prompt handling
│   │   ├── offline.js          # Offline detection
│   │   └── push.js             # Push notification handling
│   └── ...
└── tests/
    └── pwa/
        ├── manifest.test.js
        ├── sw.test.js
        └── offline.test.js
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing maskable icon | Add icon with `"purpose": "maskable"` |
| No offline fallback | Create `offline.html` and cache it |
| Cache never expires | Use `ExpirationPlugin` with Workbox |
| SW caches too aggressively | Use appropriate strategies per resource type |
| No update mechanism | Implement `skipWaiting()` + reload prompt |
| Broken install prompt | Ensure manifest meets all criteria |
| No HTTPS in production | Configure SSL certificate |
| Large cache size | Set `maxEntries` and `maxAgeSeconds` |
| Stale API responses | Use `NetworkFirst` for dynamic data |
| Missing start_url tracking | Add query param: `/?source=pwa` |

---

## UDAT Project: Hard-Won Lessons (MANDATORY READING)

> These patterns were discovered during a P0 production incident where all existing users were bricked by a Dexie schema upgrade + stale Service Worker. They are project-specific rules that supplement the generic guidance above.

### The 3 Pillars of Offline PWA Complexity

When implementing offline features in a PWA that uses **IndexedDB + Service Worker + Auth**, three independent failure domains can each block the app:

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  SERVICE WORKER   │    │    IndexedDB      │    │  AUTH HYDRATION  │
│                  │    │                  │    │                  │
│  • Cache Strategy│    │  • Schema Version│    │  • Async → Sync  │
│  • Dev/Build SW  │    │  • Multi-Tab Lock│    │  • Hydration Gate│
│  • Chunk Hashing │    │  • onversionchg  │    │  • Timeout Safety│
└────────────────┬─┘    └────────┬─────────┘    └─────┬────────────┘
                 │               │                     │
                 └───────────────┼─────────────────────┘
                                 ▼
                    ┌─────────────────────┐
                    │  AUTH LOADING = TRUE │  ← App is BRICKED
                    │  (infinite spinner) │
                    └─────────────────────┘
```

### Pillar 1: Service Worker Rules

| Rule | Pattern | File |
|------|---------|------|
| **ALWAYS unregister SW in dev mode** | `import.meta.env.DEV` → `navigator.serviceWorker.getRegistrations().forEach(r => r.unregister())` | `src/main.tsx` |
| **NEVER change JS cache to `NetworkFirst`** | Breaks offline. JS bundles MUST use `StaleWhileRevalidate` | `vite.config.ts` |
| **`controllerchange` MUST reload** | Without it, SWR updates cache but page shows old code | `UpdatePrompt.tsx` |
| **Detect orphaned SW** | Symptom: "Works in incognito, hangs in normal tab" + `workbox: Router is responding to:` in console | — |

### Pillar 2: IndexedDB / Dexie Rules

| Rule | Pattern | File |
|------|---------|------|
| **ALWAYS add `onversionchange` handler** | `offlineDb.on('versionchange', () => offlineDb.close())` — without it, schema upgrades block if ANY tab/SW has old version | `db.ts:116-118` |
| **Version data separately from DB schema** | `CURRENT_SCHEMA_VERSION` (mutations) ≠ Dexie version (tables) ≠ `AUDIT_DRAFT_VERSION` (draft structure) | `db.ts` |
| **Never `await` IndexedDB without timeout** | Use `Promise.race` with a timeout (3s for auth, longer for data) | `authStorageAdapter.ts:84-96` |
| **Detect blocked upgrades** | Symptom: infinite auth spinner for existing users, fresh/incognito works | — |

### Pillar 3: Auth Hydration Rules

| Rule | Pattern | File |
|------|---------|------|
| **Await hydration BEFORE `getSession()`** | Supabase storage adapter is sync, but IndexedDB is async → race | `useAuth.tsx:73` |
| **Await `fetchUserData()` BEFORE `setLoading(false)`** | Fire-and-forget causes redirect to `/pending` on slow networks | `useAuth.tsx` |
| **Session-aware Logger** | Logger DB writes without session → 401 spam on `/auth` page | `logger.ts:90` |

### Diagnostic Quick Reference

| Symptom | Most Likely Cause | Diagnostic |
|---------|-------------------|------------|
| "Works in incognito, hangs in normal tab" | Stale SW or blocked IndexedDB upgrade | Check console for `workbox: Router is responding to:` |
| "Works after clearing site data" | SW serving stale JS chunks | DevTools → Application → Service Workers |
| Infinite auth spinner, console quiet | `getHydrationPromise()` hanging | Check if hydration timeout log appears after 3s |
| 401 spam to `system_logs` | Logger calling Supabase without auth session | Logger should skip DB writes when `session === null` |
| `React.lazy()` silent failure | Old SW serving cached chunks with wrong hashes | Check Network tab for chunk 404s |

### Implementation Order for Offline Features

> Always build infrastructure BEFORE features.

```
1. Service Worker config       ← Cache strategies, skipWaiting, dev guard
2. IndexedDB setup             ← With onversionchange from DAY ONE
3. Auth storage adapter        ← With hydration timeout from DAY ONE
4. Feature code                ← Audit drafts, photo storage, sync queue
```

---

## PWA Development Checklist

### Before Launch

- [ ] HTTPS configured (production)
- [ ] Manifest complete with all required fields
- [ ] Icons in all required sizes (192, 512, maskable)
- [ ] Service worker registered and working
- [ ] Offline page created and cached
- [ ] Cache strategies defined for all resource types
- [ ] Install prompt handling implemented
- [ ] Lighthouse PWA audit passes

### After Launch

- [ ] Monitor cache sizes
- [ ] Test SW updates don't break app
- [ ] Track PWA installs via analytics
- [ ] Test on multiple devices/browsers
- [ ] Monitor Core Web Vitals
- [ ] Set up push notification flow (if needed)

---

## Framework-Specific Guides

### Next.js

```bash
npm install next-pwa
```

```javascript
// next.config.js
const withPWA = require('next-pwa')({
  dest: 'public',
  disable: process.env.NODE_ENV === 'development'
});

module.exports = withPWA({
  // Your Next.js config
});
```

### Create React App

```bash
# CRA 4+ has PWA support built-in
npx create-react-app my-pwa --template cra-template-pwa
```

### Vite (Any Framework)

```bash
npm install vite-plugin-pwa -D
```

See Workbox with Vite section above for configuration.

---

## Quick Reference

### Caching Strategy Cheat Sheet

```
Static Assets (CSS, JS, images)     → Cache First
API Responses                        → Network First
User-generated content              → Stale While Revalidate
Analytics, non-cacheable            → Network Only
Offline-only assets                 → Cache Only
```

### Manifest Minimum Requirements

```json
{
  "name": "App Name",
  "short_name": "App",
  "start_url": "/",
  "display": "standalone",
  "icons": [
    { "src": "/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/icon-512.png", "sizes": "512x512", "type": "image/png" }
  ]
}
```

### Service Worker Lifecycle

```
1. Register → 2. Install → 3. Activate → 4. Fetch
     ↓              ↓            ↓           ↓
  Load app    Cache assets  Clean old   Serve requests
                            caches      from cache/network
```
