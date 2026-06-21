<!-- keywords: uiapplication, uieventplayer, debuggingFlags, null-window, event-reuse, timers, invocations -->
# Verifying MulleUIApplication integrations

Use this when user code hangs in the app loop, drops events or timers, misroutes control input, or behaves differently headless versus on a real backend. This repo does have local debug hooks and headless helpers, so prefer them over ad hoc logging first.

## Understand first

```bash
mulle-sde api apropos UIApplication
mulle-sde api apropos UIEventPlayer
mulle-sde api apropos UIControl
mulle-sde api cat UIApplication
mulle-sde api cat UIEventPlayer
mulle-sde code search DebuggingFlags
```

## Main local surfaces

| Scenario | Start here | Then confirm with |
| --- | --- | --- |
| App exits early, never exits, or window ownership looks wrong | `src/UIApplication.h` | `test/10-application/window.m`, `test/30-window/add-remove.m` |
| Cross-thread callbacks, queued work, or timers appear lost | `src/UIApplication.h` | `test/20-invoke/async.m`, `test/20-invoke/sync.m`, `test/10-application/timer.m` |
| Input or control callbacks never fire | `src/UIEvent.h`, `src/UIControl.h` | `src/UIControl+DebugPrivate.h`, `src/UIApplication+UIEvent.h` |
| Need a deterministic or headless repro | `src/UIEventPlayer.h`, `src/UINullOSWindow.h` | `test/50-eventplayer/parse.m` |
| Refresh, pacing, retained-buffer, or multi-window behavior looks odd | `README.md`, `src/UIWindowTypes.h` | `demo/README.md`, `demo/src/main-two-windows.m` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/UIApplication.h`
- `src/UIApplication+UIEvent.h`
- `src/UIApplication+DebugPrivate.h`
- `src/UIEvent.h`
- `src/UIEventPlayer.h`
- `src/UIEventPlayer+DebugPrivate.h`
- `src/UIControl.h`
- `src/UIControl+DebugPrivate.h`
- `src/UINullOSWindow.h`
- `src/UIOSWindow+DebugPrivate.h`
- `demo/README.md`
- `demo/src/main-gamepad.m`
- `demo/src/main-two-windows.m`
- `test/10-application/timer.m`
- `test/10-application/window.m`
- `test/20-invoke/async.m`
- `test/20-invoke/sync.m`
- `test/30-window/add-remove.m`
- `test/50-eventplayer/parse.m`
- `test/50-eventplayer/TIMER-STARVATION-REPORT.md`

## Local verifier workflow

- Start with the smallest contract first. `test/10-application/window.m` shows the minimum `UIWindow` surface the app loop expects, and `UINullOSWindow` gives you a backend-free reproduction surface without inventing stubs.
- Split main-thread bugs from threadsafe bugs early. `addWindow:`, `removeWindow:`, `runLoop`, `runApp`, and termination are main-thread-only; timer registration, cursor lookup, `invokeOnMainThread:`, and `requestTerminate` are the threadsafe escape hatches in `src/UIApplication.h`.
- For “nothing happened” failures, decide whether the work only got queued. The invocation tests enqueue from another thread, clobber stack-backed arguments immediately, and rely on `runInvocations` to drain the queue; if your app never drains the queue, the work never runs.
- For control/input debugging, inspect the event mask before the responder chain. `UIControlInit` only enables `UIControlEventLeftMouseDown`, so missing mouse-up, drag, key, or scroll callbacks are often configuration bugs in user code, not dispatcher bugs.
- Treat event objects as reusable transport, not durable snapshots. `src/UIEvent.h` documents pooled events and notes that `UIInputEvent` location is mutated during view mapping; set `MULLE_UI_REUSE_EVENTS=NO` when chasing leaks or stale-event assumptions.
- When replaying scripted input, remember that `UIEventPlayer` aborts on invalid window indices by default. Use `setAbortOnInvalidWindowIndex:NO` only when you intentionally want replay to skip bad script entries.
- If a timer or replay bug only appears with retained windows or threaded backends, capture that explicitly. `test/50-eventplayer/TIMER-STARVATION-REPORT.md` documents a real cross-thread wakeup failure that does not show up in single-threaded or purely headless cases.

## Local debug switches

| Switch | Use |
| --- | --- |
| `UIApplicationDebuggingFlags=<mask>` or `UIDebuggingFlags=<mask>` | Enable application, event, and motion logging. Bit meanings are local to `src/UIApplication+DebugPrivate.h`. |
| `UIEventPlayerDebuggingFlags=<mask>` | Trace replay loading and event dispatch. See `src/UIEventPlayer+DebugPrivate.h`. |
| `UIResponderDebuggingFlags=<mask>` | Trace responder-chain event flow. Initialized in `src/UIResponder.m`. |
| `UIOSWindowDebuggingFlags=<mask>` | Trace backend/null-window setup, swap, and event flow. Read by `src/UINullOSWindow.m`; bit meanings live in `src/UIOSWindow+DebugPrivate.h`. |
| `MULLE_UI_REUSE_EVENTS=NO` | Disable event pooling for leak hunting and stale-event debugging. |
| `MULLE_OBJC_TRACE_DEPENDENCY=YES` | Use when `UIApplication` aborts during init because runtime classes were not all loaded. |

You can also set `debuggingFlags` directly on `UIApplication` and `UIEventPlayer` from code when a targeted repro is easier than exporting environment variables.

## What to report

- Window style mask, retained vs non-retained mode, frame-rate or swap-interval changes, and single-window vs multi-window setup.
- Whether the bug reproduces with `UINullOSWindow`/headless replay or only with a real backend.
- Which debugging flags or environment variables were enabled, especially `MULLE_UI_REUSE_EVENTS`.
- Whether the failure still reproduces when you manually drain `runInvocations` and when you reduce the repro to the test-style window contract.
