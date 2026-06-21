<!-- keywords: debugger, quirks, threading, event-reuse, uiwindowstyle, cursor, event-player -->
# Debugging quirks

## Threading and lifecycle

- `UIApplication` itself is **not** generally threadsafe; the header marks the exceptions. Treat unmarked app/window lifecycle methods as main-thread-only.
- `-addWindow:` and `-removeWindow:` are main-thread operations. The add/remove callbacks in `test/10-application/window.m` assert that expectation.
- `-removeWindow:` does not terminate the window. If you debug a “removed but still alive” object, that is the documented local contract in `src/UIApplication.h`.
- If you subclass `UIApplication`, do not override `+initialize` or `+deinitialize`. `demo/src/main-application-subclass.m` only customizes `+sharedInstance` so the global `UIApp` stays typed correctly.

## Invocation and event objects

- Event reuse is on by default. `src/UIEvent.h` explicitly documents `MULLE_UI_REUSE_EVENTS=NO` as the leak-hunting switch.
- `UIInputEvent` instances are not fully immutable: `_location` is mutated during view-side coordinate mapping. Do not treat reused input events as persistent snapshots.
- If you subclass `UIKeyboardEvent`, `UIUnicodeEvent`, `UIMouseButtonEvent`, `UIMouseMotionEvent`, `UIMouseScrollEvent`, or `UIActionEvent`, the header requires custom `+alloc` and `-dealloc` using `NSAllocateObject`/`NSDeallocateObject`.
- `UIMouseMotionNonPhysicalEvent` is a synthesized motion event, not hardware input. Do not file those as backend mouse bugs until you confirm a physical path.
- Scroll behavior is modifier-sensitive here: `alt` swaps axes, `ctrl` makes scrolling fine-grained, and `shift` makes it coarse in `UIMouseScrollEvent`.
- `removeAllInvocations` is a test helper, not normal runtime cleanup. The header and `test/20-invoke/add-remove-no-invoke.m` both frame it that way.

## Control debugging gotchas

- `UIControl` is a protocol/mixin surface, not a ready-made concrete widget. State transitions often depend on the adopter's code shape.
- The header explicitly says the control does not generally change selection state for you; it mainly translates events into target/action or click callbacks.
- Default setup is narrow: `UIControlInit` only arms left-mouse-down delivery. Missing callbacks are often an event-mask bug, not a responder-chain bug.

## Window/backend details that often explain “weird rendering” reports

- `UIWindowStyleNop` means “explicitly no defaults”, not “same as zero”. Zero style bits can still pick up default behavior.
- `UIWindowStyleSingleBuffer` is called out as no longer fully supported on glfw/wayland in `src/UIWindowTypes.h`; do not chase single-buffer artifacts as if they were a stable primary path.
- Retained backing exists for fast refresh servicing; the README specifically ties it to avoiding ugly black borders during X11 refresh/resize.
- `UIWindowStyleAntiAlias` is a policy bit, not a guarantee of one exact backend technique. README and `src/UIWindowTypes.h` describe the MSAA-or-edge-AA fallback behavior.

## Headless helpers and replay helpers

- `UINullOSWindow` creates no real OS window or graphics context. Use it for logic and event-flow debugging, not for proving backend rendering correctness.
- `UINullWindow` wraps a `UINullOSWindow` and forwards `UIEventReceiver` traffic; it is the local “minimal window” debug surface, not just a dummy object.
- `UIEventPlayer` aborts on invalid window indices by default. Disable that only when you intentionally want replay to skip bad script entries.
- Standard cursors are safe to fetch cross-thread, but custom cursor registration is main-thread-only and cursors are effectively add-only here. `src/UIApplication.h` explicitly warns against churn-heavy cursor creation.
