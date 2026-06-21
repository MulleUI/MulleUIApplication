<!-- keywords: debugger, mulle-ui-event-handling, events, mouse, keyboard, responder, control, routing -->
# mulle-ui-event-handling

Use this when events don't arrive, arrive at the wrong target, or control callbacks never fire.

## Local references (MulleUIApplication)

- `src/UIEvent.h`
- `src/UIResponder.h`
- `src/UIControl.h`
- `src/UIApplication+UIEvent.h`
- `src/UIApplication+UIEvent.m`

## Debugging workflow

1. **Events never arrive at all?** Check application-level routing. Screen/gamepad events fan out to all windows; window events are handled immediately and discarded by default.

2. **Event arrives at wrong view?** This is likely a hit-testing bug (see `mulle-ui-hit-testing` topic in MulleUIView). Check z-order, hidden/disabled state, alpha.

3. **Keyboard events don't fire?** Check the three-part contract:
   - Does the object return YES from `canBecomeFirstResponder`?
   - Did something call `becomeFirstResponder` on it?
   - Is the handler named correctly (`keyDown:`, not `keyPressed:`)?

4. **Control callback never fires?** Check event mask. `UIControlInit` only arms `UIControlEventLeftMouseDown`. Missing mouse-up, drag, key, or scroll delivery is usually an event-mask bug.

5. **Event seems corrupted or stale?** Events are pooled/reused by default. Check if you're holding a reference across frames. Set `MULLE_UI_REUSE_EVENTS=NO` for leak hunting.

## Key diagnostic

For "nothing happens" bugs, disable event reuse first:
```bash
export MULLE_UI_REUSE_EVENTS=NO
```

Then check the responder chain: is the event being consumed (return nil) lower in the chain before it reaches your handler?
