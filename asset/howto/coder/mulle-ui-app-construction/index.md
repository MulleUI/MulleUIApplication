<!-- keywords: mulleui, app-construction, framerate, continuous, animation, game, event-driven, UIWindow, UIWindowFrameRate, setFrameRate -->
# MulleUI app construction: decision tree

Use this howto when starting a new MulleUI app or when diagnosing why your app
does not render as expected. The first question to answer is: **how does your
window change over time?**

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

Reference demos: `demo/src/main-window-timer.m` (the timer there only changes
colour state, and it calls `setNeedsDisplay` to request a redraw).

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

For game development, also see `mulle-sde howto cat mulle-ui-game` which
covers input handling, drawing patterns, and collision detection.

Reference demos:
- `demo/src/main-backend-volatile.m` — `#define FRAMERATE 0.5` passed to `setFrameRate:`
- `demo/src/main-accumulate.m` — `[window setFrameRateHz:60.0]`
- `demo/src/main-context-retained-keep.m` — `[window setFrameRateHz:FPS]`

---

## Framebuffer-callback app (no UIView tree)

You want to draw directly into the framebuffer on every frame without a
`UIView` hierarchy.

```objc
styleMask = UIWindowStyleMaskDefault | UIWindowStyleNoView;
[window setFrameCallback:display];
[window setFrameRate:UIWindowFrameRateSynced];   // or explicit Hz
```

The callback receives `(UIPureWindow *, id<UIGraphicsContext>, struct CGFrameInfo *, UIWindowDisplayBits)`.

Reference demos:
- `demo/src/main-backend.inc` — the canonical callback pattern
- `demo/src/main-backend-volatile.m` — same with volatile (non-retained) style

---

## Retained / offscreen rendering app

You prebuild textures or draw into an offscreen context before compositing
into the window.

```objc
styleMask = UIWindowStyleMaskDefault;   // retained mode is the default
[window activateRenderGraphicsContext];
// ... draw into offscreen context ...
[window deactivateRenderGraphicsContextKeepState:YES];
```

Reference demos:
- `demo/src/main-context-retained-keep.m`
- `demo/src/main-context-nonretained-keep.m`

---

## Quick reference

| App type | framerate | styleMask | trigger |
|---|---|---|---|
| Event-driven | `UIWindowFrameRateAsync` (default) | `UIWindowStyleMaskDefault` | `setNeedsDisplay` on event |
| Continuous-rendering | `setFrameRateSynced` or explicit Hz | `UIWindowStyleMaskNonRetained` or default | display loop at fixed rate |
| Framebuffer callback | `UIWindowFrameRateSynced` or explicit | add `UIWindowStyleNoView` | callback every frame |
| Retained / offscreen | explicit Hz | `UIWindowStyleMaskDefault` | offscreen draw + composite |

`UIWindowStyleMaskNonRetained` is recommended for continuous-rendering apps
during development; it avoids the extra render thread and makes timing problems
easier to diagnose.
