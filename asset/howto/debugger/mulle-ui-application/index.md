<!-- keywords: debugger, mulle-ui-application, uiapplication, uievent, uiwindow, invocation, timer, null-window -->
# Debugging MulleUIApplication

Use this when a bug sits in the application loop, event delivery, timer/invocation handoff, or the window/backend boundary. This repo is the abstract layer below concrete window backends, so many failures are contract or threading bugs, not drawing bugs.

## Understand first

```bash
mulle-sde code map
mulle-sde code search UIApplication
mulle-sde code search UIEventPlayer
mulle-sde code grep "invokeOnMainThread|addTimer|requestTerminate|runInvocations"
mulle-sde code grep "UIWindowStyleRetained|UIWindowFrameRate|UINullWindow"
```

## Main local surfaces

| Scenario | Start here | Then confirm with |
| --- | --- | --- |
| App never exits, exits too early, or closes windows oddly | `UIApplication` lifecycle and window list | `test/30-window/add-remove.m`, `test/10-application/window.m` |
| Cross-thread work or callbacks behave strangely | `invokeOnMainThread`, `runInvocations`, timer receiver split | `test/20-invoke/async.m`, `test/20-invoke/sync.m`, `test/10-application/timer.m` |
| Input, window, screen, or gamepad events misroute | `UIEvent` families and `UIApplication+UIEvent` | `src/UIEvent.h`, `src/UIApplication+UIEvent.h` |
| Multi-window frame pacing or retained-buffer behavior looks wrong | `UIWindowStyle` and frame-rate knobs | `demo/src/main-two-windows.m`, `README.md` |
| Need a headless repro | `UINullWindow`, `UINullOSWindow`, `UIEventPlayer` | `src/UINullWindow.h`, `src/UINullOSWindow.h`, `src/UIEventPlayer.h` |

## Local references

- `README.md`
- `asset/dox/TOC.md`
- `src/UIApplication.h`
- `src/UIApplication+UIEvent.h`
- `src/UIEvent.h`
- `src/UIControl.h`
- `src/UIWindowTypes.h`
- `src/UINullWindow.h`
- `src/UINullOSWindow.h`
- `src/UIEventPlayer.h`
- `demo/README.md`
- `demo/src/main-application-subclass.m`
- `demo/src/main-custom-cursor.m`
- `demo/src/main-gamepad.m`
- `demo/src/main-two-windows.m`
- `test/10-application/timer.m`
- `test/10-application/window.m`
- `test/20-invoke/add-run.m`
- `test/20-invoke/async.m`
- `test/20-invoke/sync.m`
- `test/30-window/add-remove.m`

## Local debugging workflow

- Split the problem by contract first: `UIApplication` owns windows on the main thread, but screens, gamepads, timers, standard cursors, and invocation enqueueing are explicitly threadsafe in `src/UIApplication.h`.
- For “nothing happened” bugs, check whether work was only queued. In this repo, queued invocations run when `-runInvocations`, `-runLoop`, or `-runApp` drains them.
- For shutdown bugs, distinguish `-removeWindow:` from termination. It only unregisters; `-requestTerminate` and `-terminate` are the shutdown paths.
- For backend-free repros, prefer `UINullWindow`/`UINullOSWindow` over ad hoc stubs. The null pair is the local headless test surface.
- When reporting a bug, include the style mask, retained/non-retained choice, frame-rate mode, single vs multi-window setup, and whether the failure happens with null windows too.
