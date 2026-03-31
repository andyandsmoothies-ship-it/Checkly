# Router Gotchas

- **Gotcha: Auth Redirect Deadlock**
  - **Problem:** Combining `refreshListenable` auth redirects with explicit `context.go('/login')` commands during logout causes a silent UI hang/deadlock in GoRouter.
  - **Fix:** Rely entirely on the reactive `refreshListenable` architecture.

- **Gotcha: GoRouter "Popped the last page" AssertionError on Logout**
  - **Problem:** If a user logs out via a `Dialog` button using `Navigator.pop(true)`, the exit animation races against `refreshListenable`'s route stack replacement, often causing a crash with `AssertionError: You have popped the last page off of the stack`.
  - **Fix:** Use a **Pure Structural Logout**. Do NOT explicitly pop the dialog. Instead, call `auth.logout()` directly from the dialog button. GoRouter will synchronously destroy the entire old route stack (including the dialog) and rebuild it at `/login`, bypassing the animation race condition entirely.
