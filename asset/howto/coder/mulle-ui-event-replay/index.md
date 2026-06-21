<!-- keywords: mulle-ui-event-replay, replay, headless, UIEventPlayer, UINullWindow, UINullOSWindow, CI, testing, script -->
# mulle-ui-event-replay

Use this topic for scripted event replay and headless (CI-friendly) testing without a real window backend.

## Understand first

```bash
mulle-sde api apropos UIEventPlayer
mulle-sde api apropos UINullWindow
mulle-sde code search loadScriptWithContentsOfFile
mulle-sde code search UINullOSWindow
```

## Local references (MulleUIApplication)

- `src/UIEventPlayer.h`
- `src/UINullOSWindow.h`
- `src/UINullWindow.h`
- `EVENT_SCRIPT_FORMAT.md`
- `test/50-eventplayer/app-replay.m`
- `test/50-eventplayer/parse.m`

## Quick recipe: headless event replay

```objc
UINullOSWindow   *nullOSWindow;
UINullWindow     *window;
UIEventPlayer    *player;

nullOSWindow = [UINullOSWindow instance];
[nullOSWindow setEventsReceiver:logger];

window = [[[UINullWindow alloc] initWithOSWindow:nullOSWindow] autorelease];
[app addWindow:window];

player = [UIEventPlayer instance];
[player loadScriptWithContentsOfFile:"events.txt"];
[player startPlayback];
```

## Event script format

Scripts use relative monotonic time. Supported events:

```
0.0 mouseMove x=100 y=100
0.1 mouseDown button=Left x=100 y=100
0.2 mouseUp button=Left x=100 y=100
0.5 keyDown key=A
0.6 keyUp key=A
1.0 terminate
```

Multi-window: prefix with window index `N:`:

```
0: 0.0 mouseMove x=50 y=50
1: 0.1 mouseDown button=Left x=200 y=200
```

## Key facts

- Script time must stay monotonic
- Window prefixes use **application window index**, not OS handles
- Invalid window indices abort by default; use `-setAbortOnInvalidWindowIndex:NO` for sparse scripts
- `UINullWindow` strips retained-style flags — good for routing/replay tests, not retained-buffer behavior

## API spellings

The exported API is:
- `loadScriptWithUTF8String:`
- `loadScriptWithContentsOfFile:`
- `loadScriptWithFILE:`

Some older tests show `loadScriptFrom...` — prefer the exported header names.
