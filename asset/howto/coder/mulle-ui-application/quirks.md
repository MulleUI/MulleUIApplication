<!-- Keywords: quirks, threading, UIApplication, lifecycle -->
# quirks

## Threading and lifecycle

- `UIApplication` is **not** globally threadsafe. Methods are main-thread-only unless explicitly marked `MULLE_OBJC_THREADSAFE_METHOD`.
- `-addWindow:` and `-removeWindow:` are main-thread only. `-removeWindow:` does NOT terminate the window.
- `-requestTerminate` is the cross-thread shutdown request. `-terminate` is main-thread teardown.
- If you subclass `UIApplication`, do NOT override `+initialize`/`+deinitialize`. Override `+sharedInstance` only.

## Invocations

- Uses `NSInvocation`, not blocks, for cross-thread main-thread work.
- If not inside `-runApp`, you must pump `[app runInvocations]` yourself.
- `-removeAllInvocations` is a test helper; do not build normal code around it.

## Window resources

- Cursors are add-only on `UIApplication` — cannot be removed. Don't generate one-off cursor bitmaps.
- `UIPasteboard` is window-owned, not process-global.
- `UIFont` is only a name/size descriptor; it doesn't allocate backend font resources.
- `UIWindowStyleSingleBuffer` is no longer fully supported on glfw/wayland.
