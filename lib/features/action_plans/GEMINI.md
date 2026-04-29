# GEMINI.md — Action Plans Feature

## Gotcha: Never call Navigator.pop() immediately after setState() when PopScope is present

**Problem:** `PopScope(canPop: !isDirty)` reads `canPop` from the CURRENT (rendered) widget.
`setState()` only SCHEDULES a rebuild on the next frame — it does NOT flush synchronously.
If you call `Navigator.pop()` in the same synchronous frame as `setState()`, PopScope still
reads the OLD `canPop = false` value and silently blocks the close. The user sees a freeze.

**The trap sequence:**
```
setState(() { _isDirty = false; })   // rebuild SCHEDULED, not yet run
Navigator.pop(context)               // fires NOW — PopScope reads OLD canPop=false → BLOCKED
```

**Fix:** Defer the pop to the next frame using `addPostFrameCallback`:
```dart
setState(() {
  _isDirty = false;
  _photoPath = null;
  _correctionCtrl.clear();
});
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) Navigator.pop(context);  // runs AFTER rebuild → canPop=true ✓
});
```

**Applies to:** ANY widget using `PopScope(canPop: !isDirty)` that pops programmatically after a successful async operation.

