<!-- keywords: mulleui, app-construction, framerate, continuous, animation, game, event-driven, UIWindow, UIWindowFrameRate, setFrameRate -->
# MulleUI app construction: decision tree

Use this howto when starting a new MulleUI app or when diagnosing why your app
does not render as expected. The first question to answer is: **how does your
window change over time?**

## Understand first

```bash
mulle-sde api apropos UIApplication
mulle-sde api apropos UIWindow
mulle-sde api apropos UIEvent
mulle-sde code search UIWindowFrameRate
mulle-sde code search setFrameRate
```

## Local references

- `src/UIApplication.h` — app lifecycle, window management, timers
- `src/UIWindowTypes.h` — window style flags, framerate constants, UIWindow protocol
- `src/UIEvent.h` — event hierarchy and event types
- `demo/src/main-application-subclass.m` — custom UIApplication subclass
- `demo/src/main-two-windows.m` — multi-window with framerate control
- `demo/src/main-window-timer.m` — timer-driven window updates
- `demo/src/main-gamepad.m` — timer + cursor demo
- `test/30-window/add-remove.m` — minimal add/remove/terminate contract

---

## Step 1 — Pick your app type

```
Does your window change visually only when the user interacts?
  YES → Event-driven app   (see below)
  NO  → Does the display update continuously (game, simulation, visualization)?
          YES → Continuous-rendering app   (see below)
          NO  → Are you drawing directly into the framebuffer without UIViews?
                  YES → Framebuffer-callback app   (see below)
                  NO  → Retained / offscreen rendering app   (see below)
```

---

## Event-driven app

Buttons, forms, dialogs — the window only changes when the user does something.

- Default framerate `UIWindowFrameRateAsync` is **correct**. The run loop sleeps
  until an event arrives, then wakes, renders, and sleeps again.
- Call `[view setNeedsDisplay]` (or `[window setNeedsDisplay]`) from your event
  handlers whenever visible state changes.
- Do **not** set an explicit framerate; `INFINITY` is the right value here.

```objc
[window setFrameRate:UIWindowFrameRateAsync];   // explicit, but this is already the default
```

Reference demos: `demo/src/main-window-timer.m` — the timer only changes colour
state, and calls `setNeedsDisplay` to request a redraw. `demo/src/main-gamepad.m`
is also event-driven (cursor changes on timer but rendering only on event).

---

## Continuous-rendering app (game, simulation, particle system)

Your app renders every frame at a fixed rate. The window's display loop drives
both state updates and rendering — there is no `NSTimer` involved.

**Critical:** the window has an independent display-rate gate inside
`displayFrameIfNeeded:`. If the window's display interval has not elapsed, the
frame is silently skipped.

**The default `UIWindowFrameRateAsync` (= INFINITY) means "only render when an
event arrives." Nothing will ever animate unless you set a framerate.**

You must set an explicit framerate:

```objc
// option A — lock to monitor refresh rate
[window setFrameRateSynced];

// option B — explicit Hz
[window setFrameRateHz:60.0];

// option C — explicit interval
[window setFrameRate:1.0/60.0];
```

Diagnostic question when "nothing animates":

1. What is `[window frameRate]`?
2. If the answer is `INFINITY`, that is your bug — set it explicitly.

Reference demo: `demo/src/main-two-windows.m` — configures per-window
framerate (`UIWindowFrameRateUnsynced` with vsync, or `setFrameRateHz:2.0`
for soft-sync).

---

## Framebuffer-callback app (no UIView tree)

You want to draw directly into the framebuffer on every frame without a
`UIView` hierarchy. This is done via `UIOSWindow` frame callbacks.

The callback receives `(id <UIOSWindow>, struct UIWindowDisplayBits)`.
Use `UIWindowStyleNoView` in the style mask to skip UIView creation.

```objc
styleMask = UIWindowStyleNoView;
```

Reference: `src/UIWindowTypes.h` — `UIOSWindowFrameCallback_t` type and
`UIWindowStyleNoView` flag.

---

## Retained / offscreen rendering app

You prebuild textures or draw into an offscreen context before compositing
into the window. Use `UIWindowStyleRetained` (default) or
`UIWindowStyleRetainedOnMainThread` for retained framebuffer mode.

```objc
styleMask = UIWindowStyleMaskDefault;   // retained mode is the default
```

The retained buffer copies the frame to the foreground on refresh, avoiding
redundant redraws. X11 benefits from this to avoid black borders during resize.

Reference: `src/UIWindowTypes.h` for `UIWindowStyleRetained` flag semantics
and `README.md` for retained-buffer behavior details.

---

## Quick reference

| App type | framerate | styleMask | trigger |
|---|---|---|---|
| Event-driven | `UIWindowFrameRateAsync` (default) | `UIWindowStyleMaskDefault` | `setNeedsDisplay` on event |
| Continuous-rendering | `setFrameRateSynced` or explicit Hz | `UIWindowStyleMaskDefault` (non-retained recommended for dev) | display loop at fixed rate |
| Framebuffer callback | `UIWindowFrameRateSynced` or explicit | add `UIWindowStyleNoView` | callback every frame |
| Retained / offscreen | explicit Hz | `UIWindowStyleMaskDefault` (retained is default) | offscreen draw + composite |

`UIWindowStyleMaskDefault` includes `UIWindowStyleAntiAlias` and
`UIWindowStyleRetained` by default. Remove `UIWindowStyleRetained` for
continuous-rendering during development to avoid the extra render thread
and make timing problems easier to diagnose.

## Construction checklist

- [ ] `[UIApplication sharedInstance]` called before any window is created
- [ ] Window created with appropriate `styleMask` and `frameRate`
- [ ] Window added via `[app addWindow:]` on the **main thread**
- [ ] Run loop started via `[app runApp]`, `UIApplicationRunWindow()`, or `UIApplicationMain()`
- [ ] Timers (if used) registered via `[app addTimer:forTimerReceiver:]`
- [ ] Cursors, pasteboard, fonts set up after app initialization
- [ ] `requestTerminate` used for cross-thread shutdown; `terminate` for main-thread teardown
