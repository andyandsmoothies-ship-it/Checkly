# Project Gotchas & Lessons
description: Continuous log of critical project-specific lessons, gotchas, and patterns.
trigger: always_on
---

## Project: VoucherSender (Blazor Server Web App — .NET 10)
A web app that reads voucher codes from XLSX and sends them to employees via email.

---

## CRITICAL GOTCHAS (Curation Rules Enforced)

| # | Category | Description |
|---|----------|-------------|
| 1 | IDE Quirks | **Script tags in `App.razor`:** The IDE will show warnings about script tags lacking dynamic update capability, but they compile and work perfectly fine for the static root document. Ignore the warnings. |
| 2 | ClosedXML | **Excel Number Types:** Excel stores all numeric values as `double` internally. Always use `double.TryParse` fallback when `int.TryParse` fails to extract cell data. |
| 3 | SignalR / JS | **Blocking JS Interop:** NEVER use `window.confirm()`, `window.alert()`, or `window.prompt()` via `JS.InvokeAsync`. These popups block the JS main thread, killing the SignalR WebSocket keepalive. The circuit drops and the modal auto-dismisses. Always use a Blazor-rendered modal instead. |
| 4 | Architecture | **Routing NavMenu Orphans:** `NavMenu.razor` is designed to render exactly ONE root link per `IToolPlugin`. Sub-pages (like `/vouchers/history`) become orphans with no navigation entry. You must build an in-tool tab bar (`<MudLink>`) to allow users to reach sub-pages. |
| 5 | SignalR / Lock | **Stale Lock Recovery:** If a SignalR circuit drops ungracefully during a send operation, the file lock remains held. Implement an `OnInitialized` check: if the current user owns a lock but `Session.Sending == false` (meaning they just restarted), auto-release their stale lock. |
| 6 | Architecture | **Render Mode on Layouts:** NEVER add `@rendermode InteractiveServer` to a layout component like `MainLayout.razor`. The `@Body` parameter is a `RenderFragment` delegate, which cannot be serialized across static/interactive boundaries (`InvalidOperationException`). Set global interactivity on `<Routes @rendermode="InteractiveServer" />` in `App.razor` instead. |
| 7 | MudBlazor | **Provider Contexts:** `MudPopoverProvider`, `MudDialogProvider`, etc., must exist in the **same interactive context** as the components using them. If a page uses interactive render mode but the layout is static SSR, `MudSelect` will crash with `Missing <MudPopoverProvider />`. |
| 8 | MudBlazor | **Inline Dialog Crashing:** `<MudDialog @bind-Visible>` (inline declaration) crashes the Blazor render tree. Replace it with `MudOverlay` + `MudPaper` having `role="dialog" aria-modal="true"`, or invoke dialogs programmatically via `IDialogService.ShowAsync()`. |
| 9 | Email Delivery | **CID Image Embedding:** Never use base64 data URIs for images (like Barcodes) in emails because most clients block them. Generate barcodes in-memory, attach as `LinkedResources` with a `ContentId`, and reference via `<img src="cid:...">`. |
| 10 | Architecture | **Event Handler Lookup Pattern:** When handling a Singleton event (`OnBatchProgressChanged`), NEVER use a filtered query (`GetActiveJob`) to find the event's subject. Use the event key for direct lookup (`GetJob(key)`). A filtered query can miss state changes (e.g., `IsCompleted`) that were applied before the event fired, causing a race condition. |

## Project: Checkly (Flutter Mobile App)

| # | Category | Description |
|---|----------|-------------|
| 1 | Layout | **Nested Scaffold + FAB invisibility:** `_MainShell` (ShellRoute) wraps pages in a Scaffold with `extendBody: true` and a 96px bottom nav bar. Child pages (DashboardPage, HistoryPage) have their OWN inner Scaffold. Any `floatingActionButton` in the inner Scaffold MUST have `Padding(bottom: 80)` or it renders behind the nav bar and is invisible. |
| 2 | Gesture | **FloatingActionButton inside PopupMenuButton:** Do NOT wrap a `FloatingActionButton(onPressed: ...)` inside `PopupMenuButton.child`. The FAB's InkResponse absorbs tap events, preventing PopupMenuButton from firing. Use `showMenu()` programmatically from the FAB's `onPressed` instead. |
