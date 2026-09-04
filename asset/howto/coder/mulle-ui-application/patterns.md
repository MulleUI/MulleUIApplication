<!-- Keywords: patterns, UIApplication, timers, invocations, cursors -->
# patterns

## Boot an app and hand it windows

```objc
UIApplication   *app;
id <UIWindow>    window;

app = [UIApplication sharedInstance];
window = ...;
[app addWindow:window];
return( [app runApp]);
```

- `demo/src/main-two-windows.m` — multi-window example.
- `demo/src/main-application-subclass.m` — override `+sharedInstance` for subclass.
- `test/30-window/add-remove.m` — minimal add/remove/terminate contract.

## Queue work onto the main thread with `NSInvocation`

```objc
signature  = [app methodSignatureForSelector:@selector( callMeWithInteger:textUTF8String:)];
invocation = [NSInvocation invocationWithMethodSignature:signature];
[invocation setTarget:app];
[invocation setSelector:@selector( callMeWithInteger:textUTF8String:)];
[invocation setArgument:&value atIndex:2];
[invocation setArgument:&s atIndex:3];
[app invokeOnMainThread:invocation waitUntilDone:YES];
```

- `test/20-invoke/async.m` — async pattern.
- `test/20-invoke/sync.m` — synchronous pattern with stack-backed arguments.
- If not inside `-runApp`, pump `[app runInvocations]` yourself.

## Register timers through the application

```objc
timer = [NSTimer mulleTimerWithRelativeTimeInterval:0.5
                                     repeatInterval:0.75
                                             target:window
                                           selector:@selector( changeCursor:)
                                           userInfo:nil
                         fireUsesUserInfoAsArgument:NO];
[app addTimer:timer forTimerReceiver:window];
```

- Use `-resetTimer:` to restart a timer's next fire time from now.

## Window-bound resources

- Register custom cursors once on `UIApplication`, apply to windows. `demo/src/main-custom-cursor.m`.
- Standard cursors: `[UIApp cursorWithStandardShape:...]`.
- `UIPasteboard` is per-window: `+pasteboardWithWindow:`.
- `UIFont` is name+size only here; the render backend resolves the actual font later.
