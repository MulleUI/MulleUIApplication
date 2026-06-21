<!-- keywords: debugger, patterns, uiapplication, invocation, timer, window, cursor, null-window -->
# Debugging patterns

## Reproduce app-loop and window-list bugs with the smallest contract

- `test/10-application/window.m` shows the minimum `UIWindow` contract the app needs: `OSWindow`, `os_window`, `displayFrameIfNeeded:`, `syncOSWindowPropertyChangesIfNeeded`, `setNeedsRefresh`, `shouldClose`, and add/remove callbacks.
- `test/30-window/add-remove.m` is the local shutdown pattern: add windows, optionally remove some, then `requestTerminate` and let `runLoop` drain.
- If a bug only appears with a real backend, compare it against a `UINullWindow` repro first. If it disappears there, the fault is likely in the OS-window/backend layer, not `UIApplication`.

## Debug main-thread handoff by watching the queue, not just the caller

- `test/20-invoke/add-run.m` is the simplest proof: enqueue an `NSInvocation`, call `runInvocations`, then read the return value back out of the invocation.
- `test/20-invoke/async.m` and `test/20-invoke/sync.m` are the important stress cases. They enqueue calls from another thread, pass stack-backed arguments, then clobber the stack immediately after enqueueing.
- When debugging a race, instrument both sides: the producer thread building the invocation and the main-thread loop calling `runInvocations`.
- Use async enqueue for fire-and-forget UI work; only use `waitUntilDone:YES` when the caller really must block.

## Keep timer debugging separate from timer target debugging

- Timers are registered on the application with an explicit timer receiver: `addTimer:forTimerReceiver:` in `src/UIApplication.h`.
- `test/10-application/timer.m` and `demo/src/main-gamepad.m` both use that split directly; do not assume the timer target is enough for app bookkeeping.
- If a timer appears lost, verify the receiver object still exists and that the app loop is still polling or waiting for events.

## Debug control-side bugs at the event-mask boundary

- `src/UIControl.h` is a mixin/protocol contract, so “button state” bugs are often in the adopting control, not in a concrete base class.
- `UIControlInit` only enables `UIControlEventLeftMouseDown` by default. If mouse-up, drag, key, or scroll callbacks never fire, inspect the control's event mask first.
- The local control levers are `selectionBehaviour`, `state`, `reflectedState`, `target`, `action`, and `click`. If the visuals change but no callback runs, trace `performClickAndTargetActionCallbacks:`.
- When highlight behavior looks wrong, distinguish physical motion from `UIMouseMotionNonPhysicalEvent`; this repo uses the non-physical variant for synthesized highlight tracking.

## Isolate frame-pacing bugs with style-mask and swap decisions

- The demos usually start from `UIWindowStyleMaskDefault & ~UIWindowStyleRetained`; see `demo/src/main-gamepad.m`, `demo/src/main-custom-cursor.m`, and `demo/src/main-two-windows.m`.
- `demo/src/main-two-windows.m` is the local reference for single-thread multi-window pacing. With VSync, two windows share the available redraw cadence; with the soft-sync path, frame rate is driven explicitly.
- When a refresh or resize bug only happens under load, capture whether retained backing is on and whether swap interval or frame-rate APIs were changed.

## Use the built-in debug helpers instead of inventing new scaffolding

- `demo/src/main-custom-cursor.m` is the cursor-registration pattern: decode a bitmap once, register it on the app, then assign the returned cursor to a window.
- `demo/src/main-gamepad.m` is the standard-cursor cycling pattern and also shows timer-driven UI changes.
- `src/UIEventPlayer.h` is the scripted replay hook. Use it when you need deterministic event sequences instead of ad hoc sleeps.
- `src/UINullWindow.h` and `src/UINullOSWindow.h` are the headless harness for event-dispatch and lifecycle debugging in CI-like environments.
