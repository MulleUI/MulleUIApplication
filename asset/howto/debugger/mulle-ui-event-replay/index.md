<!-- keywords: debugger, mulle-ui-event-replay, replay, UIEventPlayer, UINullWindow, script -->
# mulle-ui-event-replay

Use this when scripted event replay doesn't work, events don't arrive during playback, or headless testing fails.

## Local references (MulleUIApplication)

- `src/UIEventPlayer.h`
- `src/UINullOSWindow.h`
- `src/UINullWindow.h`
- `EVENT_SCRIPT_FORMAT.md`
- `test/50-eventplayer/app-replay.m`

## Debugging workflow

1. **Script doesn't load?** Check API spelling: use `loadScriptWithContentsOfFile:` or `loadScriptWithUTF8String:`, NOT the older `loadScriptFrom...` variants.

2. **Events don't replay?** Check:
   - Is the window added to `UIApplication`?
   - Is `startPlayback` called?
   - Are script times monotonic?

3. **Playback aborts immediately?** Default behavior aborts on invalid window indices. Use `-setAbortOnInvalidWindowIndex:NO` for sparse multi-window scripts.

4. **Events arrive but no visible effect?** `UINullWindow` strips retained-style flags and has no real graphics context. It routes events correctly but doesn't render. Check if your bug is actually a rendering issue, not a replay issue.

5. **Older test code doesn't work?** The `test/50-eventplayer/eventplayer-dispatch.m` test is intentionally obsolete. Use `test/50-eventplayer/dummy-replay.m` (MulleUIPureWindow) as the live reference.
