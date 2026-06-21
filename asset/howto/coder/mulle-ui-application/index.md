<!-- Keywords: mulle-ui-application, UIApplication, UIEvent, UIWindow, UIEventPlayer, UINullWindow -->
# mulle-ui-application

Use this topic for `UIApplication` lifecycle, window orchestration, timers, main-thread invocations, and window-adjacent resources (cursors, pasteboard, fonts). For specific event activities, see the focused subtopics:

- **mulle-ui-event-handling** — mouse/keyboard/scroll handlers, responder chain, UIControl
- **mulle-ui-event-replay** — scripted event replay, headless testing, UIEventPlayer

## Understand first

```bash
mulle-sde code search UIApplication
mulle-sde code search UIEventPlayer
mulle-sde code grep invokeOnMainThread
```

## Main local surfaces

| Scenario | Start with |
| --- | --- |
| App lifecycle, windows, run loop | `src/UIApplication.h`, `demo/src/main-application-subclass.m`, `test/10-application/window.m` |
| Main-thread invocations | `test/20-invoke/sync.m`, `test/20-invoke/async.m` |
| Timers | `test/10-application/timer.m`, `demo/src/main-gamepad.m` |
| Cursors, pasteboard, fonts | `src/UICursor.h`, `src/UIPasteboard.h`, `src/UIFont.h` |

## Local references

- `src/UIApplication.h`
- `src/UIWindowTypes.h`
- `demo/src/main-application-subclass.m`
- `demo/src/main-two-windows.m`
- `test/10-application/window.m`
- `test/20-invoke/add-run.m`
- `test/20-invoke/async.m`
- `test/20-invoke/sync.m`
- `test/30-window/add-remove.m`

## Key patterns

### Boot an app with windows

```objc
UIApplication   *app;
id <UIWindow>    window;

app    = [UIApplication sharedInstance];
window = ...;
[app addWindow:window];
return( [app runApp]);
```

### Queue work onto main thread

```objc
NSInvocation   *invocation;

signature  = [app methodSignatureForSelector:@selector( doWork:)];
invocation = [NSInvocation invocationWithMethodSignature:signature];
[invocation setTarget:app];
[invocation setSelector:@selector( doWork:)];
[invocation setArgument:&value atIndex:2];
[app invokeOnMainThread:invocation waitUntilDone:YES];
```

### Register a timer

```objc
timer = [[[NSTimer alloc] mulleInitWithRelativeTimeInterval:0.5
                                             repeatInterval:0.75
                                                     target:window
                                                   selector:@selector( tick:)
                                                   userInfo:nil
                                 fireUsesUserInfoAsArgument:NO] autorelease];
[app addTimer:timer forTimerReceiver:window];
```
