# Router Gotchas

- **Gotcha: Auth Redirect Deadlock**
  - **Problem:** Combining `refreshListenable` auth redirects with explicit `context.go('/login')` commands during logout causes a silent UI hang/deadlock in GoRouter.
  - **Fix:** Rely entirely on the reactive `refreshListenable` architecture.

- **Gotcha: GoRouter "Popped the last page" AssertionError on Logout**
  - **Problem:** If a user logs out via a `Dialog` button using `Navigator.pop(true)`, the exit animation races against `refreshListenable`'s route stack replacement, often causing a crash with `AssertionError: You have popped the last page off of the stack`.
  - **Fix:** Use a **Pure Structural Logout**. Do NOT explicitly pop the dialog. Instead, call `auth.logout()` directly from the dialog button. GoRouter will synchronously destroy the entire old route stack (including the dialog) and rebuild it at `/login`, bypassing the animation race condition entirely.

- **Gotcha R-01: Router `/admin` Guard Uses `admin:access` — NOT Granular Capabilities** *(2026-04-10)*
  - **Problem:** Guarding `state.matchedLocation.startsWith('/admin')` with a granular capability (e.g., `admin:manage_roles`) causes the **Group Policy Trap**: a valid admin with `stores:write` but not `manage_roles` is permanently locked out of the Admin Console.
  - **Fix:** `authRedirect()` MUST check only `PolicyManager.can('admin:access')` at the router level. Granular capability checks belong **inside the specific admin page widget** using `PermissionGuard`.
  - **Rule:** `admin:access` is the UI-Signal gate for the router prefix. It is the ONLY capability permitted in the `/admin` guard block.

