<!-- keywords: mulle-ui-event-handling, quirks, reuse, threading, routing -->
# Quirks

## Event objects are pooled and reused

- Events are pooled by default. Do not hold long-lived references to event fields.
- `UIInputEvent` has mutable `_location`/`_locationView` specifically for coordinate rewriting during dispatch.
- For leak detection, set `MULLE_UI_REUSE_EVENTS=NO`.
- If you subclass concrete event classes (`UIKeyboardEvent`, `UIMouseButtonEvent`, etc.), the header requires custom `+alloc`/`-dealloc` using `NSAllocateObject`/`NSDeallocateObject`.

## Routing is asymmetric at the application level

- Screen and gamepad events fan out to **all** windows via `receiveRetainedEvent:`.
- Window events (close, refresh, resize, move) are handled immediately on the main thread; the default application discards them.
- `receiveRetainedEvent:` is a consuming API — the receiver must release or forward.

## Responder dispatch

- Override the concrete handlers (`mouseDown:`, `mouseUp:`, `keyDown:`, etc.) before reaching for `handleEvent:` or `acceptMouseButtonEvent:`.
- Return `nil` to consume, return the event to pass upward.
- Keyboard events require the three-part contract: `canBecomeFirstResponder` → `becomeFirstResponder` → handler fires.

## Control gotchas

- `UIControl` default event mask is only `UIControlEventLeftMouseDown`. Missing callbacks are usually event-mask bugs.
- Disabled+highlighted and disabled+first-responder are impossible states — don't model visuals for them.
- `UIEventMouseButtonMiddle` is flaky in polled events; avoid depending on it in tests.
