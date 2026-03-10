# MulleUIApplication Library Documentation for AI
<!-- Keywords: application, events, responder, abstract, windowing -->

## 1. Introduction & Purpose

MulleUIApplication provides the abstract foundational classes for application lifecycle and event handling in the MulleUI framework. The library defines the singleton application controller (UIApplication), the complete event hierarchy (UIEvent and subclasses), the responder chain architecture (UIResponder), and base classes for interactive controls (UIControl). It is platform-agnostic and graphics-library-agnostic, serving as an abstract interface layer between the UI framework and concrete windowing implementations.

This library solves the problem of providing a unified, cross-platform application architecture without coupling to specific windowing systems (GLFW, SDL) or graphics libraries. Key features include singleton application management, multi-window support, threadsafe screen and gamepad enumeration, timer management, cursor abstraction, main-thread invocation queuing, and a comprehensive event type system covering keyboard, mouse, window, screen, and gamepad events.

MulleUIApplication is a core component of the MulleUI stack, depending on MulleFoundationBase (for Objective-C runtime and Foundation classes) and MulleUIBase (for geometry, colors, and basic UI types). Higher layers like MulleUIWindow and MulleGLFWWindow provide concrete implementations of the protocols defined here.

## 2. Key Concepts & Design Philosophy

### Singleton Application Pattern
UIApplication uses the singleton pattern with `+sharedInstance` and the global `UIApp` variable. This ensures a single application controller manages all windows, screens, timers, and the run loop. The singleton is thread-aware with a TAO (Thread Aware Object) strategy distinguishing main-thread-only from threadsafe methods.

### Abstract Protocol-Based Architecture
The library defines protocols rather than concrete classes for platform-specific objects. UIWindow, UIOSWindow, UIScreen, and UIGamepad are all protocols, allowing concrete implementations to be provided by higher-layer libraries without coupling MulleUIApplication to specific backends.

### Event Hierarchy and Reuse
Events are organized in a class hierarchy rooted at UIEvent, with UIInputEvent as the base for user input events (keyboard, mouse). Events are pooled and reused by default for performance (disable via `MULLE_UI_REUSE_EVENTS=NO`). The event system distinguishes between input events (tied to mouse location and modifier state) and system events (window, screen, gamepad lifecycle).

### Responder Chain
UIResponder defines the responder chain pattern where events propagate from leaf views up through the view hierarchy to window to application. Responders can handle events, pass them to the next responder, or accept events with callbacks. The responder chain enables decoupled event handling without tight coupling between UI components.

### Threading Model
UIApplication uses a strict threading model:
- **Main thread only**: Window add/remove, application lifecycle (init/terminate), run loop, OS-specific methods
- **Threadsafe**: Screen queries, gamepad queries, cursor retrieval, timer management, main-thread invocations, requestTerminate

The threading strategy is `MulleObjCTAOKnownThreadSafeMethods` - methods are main-thread-only unless explicitly marked `MULLE_OBJC_THREADSAFE_METHOD`.

### Control State Management
UIControl defines a state-based architecture for interactive controls with states (normal, highlighted, disabled, selected, firstResponder) and selection behaviors (push, release, pushSwitch, releaseSwitch). Controls translate events into target/action or click callbacks, providing a reusable pattern for buttons, switches, and custom controls.

### Window Styles
Window style flags (UIWindowStyle enum) control window behavior and rendering options. Styles include resizable, transparent, floating, bare (no decorations), antialiasing modes, stencil strokes, retained buffers, and OpenGL profile settings. These are used by concrete window implementations to configure platform-specific behavior.

## 3. Core API & Data Structures

### 3.1. `UIApplication.h`

#### `@interface UIApplication`
- **Purpose:** Singleton application controller managing windows, event distribution, run loop, timers, screens, gamepads, and cursors.
- **Key Ivars:**
  - `_screens` (mulle_array): Threadsafe screen list with lock
  - `_gamepads` (mulle_pointerarray): Threadsafe gamepad list with lock
  - `_windows` (mulle_array): Main-thread-only window list
  - `_standardCursors` (mulle_map): Standard cursor cache
  - `_customCursors` (mulle_map): Custom cursors with lock
  - `_timers` (mulle_structarray): Threadsafe timer list
  - `_invocationList` (mulle_pointermultififo): Main-thread invocation queue
- **Properties:**
  - `delegate` (assign, main-thread): Optional delegate (unused currently)
  - `returnStatus` (assign, main-thread): Exit code returned by `-runApp`
  - `debuggingFlags` (assign, threadsafe): UIApplicationDebug flags for logging
  - `eventPlayer` (retain, main-thread): Optional UIEventPlayer for event replay
  - `osKeyWindow` (retain, main-thread): Window receiving ambiguous events

#### Lifecycle Functions
- `+sharedInstance` - Get singleton (creates if needed, sets `UIApp` global)
- `-runApp` - Start event loop, returns exit code when all windows close (main-thread)
- `-runLoop` - Continuous event loop (main-thread)
- `-runLoopIteration` - Single event loop iteration (main-thread)
- `-terminate` - Shutdown all windows and cleanup (main-thread)
- `-requestTerminate` - Async termination request (threadsafe)
- `-runWindow:` - Convenience method to run single window (main-thread)
- `UIApplicationRunWindow()` - C function convenience wrapper

#### Window Management (Main Thread Only)
- `-addWindow:` - Register window with application
- `-removeWindow:` - Unregister window (does not call terminate on window)
- `-numberOfWindows` - Query window count
- `-getWindows:length:` - Fill buffer with window array
- `-windowAtIndex:` - Get window by index
- `-windowForOSWindowHandle:` - Find window by OS handle (GLFW/SDL window pointer)

#### Screen Management (Threadsafe)
- `-primaryScreen` - Get main monitor
- `-numberOfScreens` - Count connected screens
- `-screenAtIndex:` - Get screen by index (may return nil)
- `-screenForFrame:primaryIfNoneMatches:` - Find screen containing rect
- `-getScreens:maxCount:intersectingFrame:` - Get all screens intersecting rect

#### Gamepad Support (Threadsafe)
- `-gamepadAtIndex:` - Get gamepad by index (may return nil if unplugged)

#### Timer Support (Threadsafe)
- `-addTimer:forTimerReceiver:` - Schedule timer for receiver
- `-removeTimer:forTimerReceiver:` - Cancel specific timer
- `-removeAllTimersForTimerReceiver:` - Cancel all timers for receiver
- `-removeAllTimers` - Cancel all timers globally
- `-resetTimer:` - Restart timer countdown from now

#### Cursor Management
- `-cursorWithStandardShape:` - Get standard cursor (arrow, hand, text, resize) - threadsafe
- `-registerCursorBitmap:hotSpot:forKeyUTF8String:scaleToStandardSize:` - Register custom cursor (main-thread)
- `-cursorForKeyUTF8String:` - Retrieve custom cursor by key (threadsafe)
- `-standardCursorSize` - Platform cursor dimensions (typically 32x32 or 64x64)

#### Main Thread Invocations (Threadsafe)
- `-invokeOnMainThread:` - Async execution on main thread
- `-invokeOnMainThread:waitUntilDone:` - Sync execution (blocks caller until done)
- `-runInvocations` - Process pending invocations (called internally during run loop)
- `-removeAllInvocations` - Clear queue (testing only)

#### OS Integration Category (Main Thread Only)
- `+os_initialize` / `+os_deinitialize` - Global OS initialization
- `-os_init` / `-os_finalize` - Instance OS initialization
- `-os_createStandardCursor:` / `-os_destroyCursor:` - Platform cursor creation
- `-os_waitEventsWithTimeout:` - Block until event or timeout
- `-os_pollEvents` - Non-blocking event polling
- `-os_pollGamepads` - Update gamepad state
- `-os_sendEmptyEvent` - Wake up event loop (threadsafe)

#### Global Variables and Functions
- `UIApp` - Global singleton pointer set by `+sharedInstance`
- `UIApplicationRequestRunLoopBreak` - Signal to break run loop (for signal handlers)
- `UIApplicationMain()` - Standard main function wrapper
- `UIApplicationGetSpace()` - Access private storage space for SDL/GLFW state

### 3.2. `UIEvent.h`

#### `typedef NS_OPTIONS( NSUInteger, UIEventType)`
- `UIEventTypePresses` (0x01) - Physical keyboard key press/release
- `UIEventTypeUnicode` (0x02) - Interpreted unicode character input
- `UIEventTypeTouches` (0x04) - Mouse button clicks
- `UIEventTypeMotion` (0x08) - Mouse movement
- `UIEventTypeScroll` (0x10) - Mouse scroll wheel
- `UIEventTypeWindow` (0x20) - Window lifecycle (close, resize, refresh, move)
- `UIEventTypeScreen` (0x40) - Screen connect/disconnect
- `UIEventTypeGamepad` (0x80) - Gamepad connect/disconnect
- `UIEventTypeUser` (0x100) - Custom application events
- `UIEventTypeAction` (0x200) - Menu/action events
- `UIEventTypeTracking` (0x800) - Mouse tracking events
- `UIEventTypeUTF8String()` - Convert type to string for debugging

#### `@interface UIEvent`
- **Purpose:** Base class for all events. Events are pooled and reused by default.
- **Properties:**
  - `timestamp` (mulle_absolutetime_t, readonly) - Event creation time relative to execution start
- **Class Methods:**
  - `+reuseEvents` / `+setReuseEvents:` - Control event pooling (disable for leak detection)
  - `+waitForEventsTimeout:` - Wait for OS events with timeout
  - `+sendEmptyEvent` - Wake up event loop
- **Subclass Interface:**
  - `-eventType` - Return UIEventType bitmask
  - `-isInputEvent` - Returns YES for UIInputEvent subclasses

#### `@interface UIInputEvent : UIEvent`
- **Purpose:** Base for user input events tied to mouse pointer location and modifier state.
- **Key Ivars:**
  - `_inputState` (struct UIInputState) - Location in window, modifier keys, button states
  - `_location` (CGPoint) - Location in view coordinates (NOT readonly, modified by UIView)
  - `_locationView` (id, not retained) - View for location coordinates
- **Properties:**
  - `inputState` (readonly) - Full input state structure
  - `location` (readonly) - Location in current coordinate system
  - `locationInWindow` (dynamic, readonly) - Location in window coordinates
  - `keyModifiers` (dynamic, readonly) - Modifier key flags (shift, ctrl, alt, super)
  - `buttonStates` (dynamic, readonly) - Mouse button states bitmask
- **Methods:**
  - `-initWithInputState:` - Initialize with input state
  - `-isInitialEvent` - YES for mouseDown and initial touches
  - `-isPhysicalEvent` - YES for actual user actions (not simulated)

#### `@interface UIKeyboardEvent : UIInputEvent`
- **Purpose:** Physical keyboard key press/release events.
- **Properties:**
  - `key` (NSUInteger, readonly) - UIEventKey enum value (physical key)
  - `scanCode` (NSUInteger, readonly) - Platform-specific scan code
  - `action` (NSUInteger, readonly) - UIEventButtonAction (Up/Down/Repeat)
  - `isARepeat` (BOOL, readonly) - YES for key repeat events
- **Initializer:** `-initWithInputState:key:scanCode:action:isARepeat:`

#### `@interface UIUnicodeEvent : UIInputEvent`
- **Purpose:** Interpreted unicode character input (after keyboard layout processing).
- **Properties:**
  - `character` (NSUInteger, readonly) - Unicode code point
- **Initializer:** `-initWithInputState:character:`

#### `@interface UIMouseButtonEvent : UIInputEvent`
- **Purpose:** Mouse button click events.
- **Properties:**
  - `button` (NSUInteger, readonly) - UIEventMouseButton (Left/Right/Middle)
  - `action` (NSUInteger, readonly) - UIEventButtonAction (Up/Down)
- **Initializer:** `-initWithInputState:button:action:`

#### `@interface UIMouseMotionEvent : UIInputEvent`
- **Purpose:** Mouse movement events. Subclass UIMouseMotionNonPhysicalEvent for simulated events.

#### `@interface UIMouseScrollEvent : UIInputEvent`
- **Purpose:** Mouse scroll wheel events with acceleration and modifier support.
- **Properties:**
  - `scrollOffset` (CGPoint, readonly) - Raw scroll delta
- **Class Methods:**
  - `+scrollWheelAcceleration` / `+setScrollWheelAcceleration:` - Global acceleration factor
- **Methods:**
  - `-initWithInputState:scrollOffset:`
  - `-scrollOffsetWithAcceleration:useModifiers:` - Apply acceleration and modifiers (alt swaps axis, ctrl fine scroll, shift coarse)

#### `@interface UIActionEvent : UIInputEvent`
- **Purpose:** Action/menu events with target and action.
- **Properties:**
  - `action` (SEL, readonly) - Selector to invoke
  - `sender` (id, readonly) - Object sending action
- **Initializer:** `-initWithInputState:action:sender:`

#### `@interface UIWindowEvent : UIEvent`
- **Purpose:** Base for window lifecycle events.
- **Subclass Interface:**
  - `-windowEventType` - Return UIWindowEventType
- **Subclasses:**
  - `UIWindowCloseEvent` - User requested close
  - `UIWindowRefreshEvent` - Framebuffer dirty, needs repaint
  - `UIWindowResizeEvent` - Window size changed (property: `size`)
  - `UIWindowMoveEvent` - Window position changed (property: `origin`)
  - `UIWindowFramebufferResizeEvent` - Framebuffer size changed (subclass of resize)

#### `@interface UIScreenEvent : UIEvent`
- **Purpose:** Screen connect/disconnect events.
- **Properties:**
  - `screenEventType` (UIScreenEventType, readonly) - Connected/Disconnected
  - `screen` (id <UIScreen>, readonly) - Affected screen
- **Initializer:** `-initWithScreen:screenEventType:`

#### `@interface UIGamepadEvent : UIEvent`
- **Purpose:** Gamepad connect/disconnect events.
- **Properties:**
  - `gamepadEventType` (UIGamepadEventType, readonly) - Connected/Disconnected
  - `gamepad` (id <UIGamepad>, readonly) - Affected gamepad
- **Initializer:** `-initWithGamepad:gamepadEventType:`

#### `@interface UIUserEvent : UIEvent`
- **Purpose:** Custom application-specific events.
- **Properties:**
  - `eventIdentifier` (NSUInteger, readonly) - Application-defined ID
- **Initializer:** `-initWithEventIdentifier:`

#### Enums for Event Properties
- `UIEventMouseButton` - Left (0x1), Right (0x2), Middle (0x4)
- `UIEventButtonAction` - Up (0), Down (1), Repeat (2)
- `UIEventKeyModifier` - Shift, Control, Alt, Super, CapsLock, NumLock
- `UIEventKey` - Extensive enum for physical keys (Space=32, A-Z=65-90, F1-F25=290-314, etc.)
- `UIWindowEventType` - Close, Refresh, Resize, Move, FramebufferResize
- `UIScreenEventType` - Connected, Disconnected
- `UIGamepadEventType` - Connected, Disconnected

#### Helper Functions
- `UIEventTypeUTF8String()` - Event type to string
- `UIEventMouseButtonUTF8String()` - Button to string
- `UIEventButtonActionUTF8String()` - Action to string
- `UIEventKeyModifierUTF8String()` - Modifier to string
- `UIEventKeyUTF8String()` - Key to string
- `UIWindowEventTypeUTF8String()` - Window event type to string
- `UIScreenEventTypeUTF8String()` - Screen event type to string
- `UIGamepadEventTypeUTF8String()` - Gamepad event type to string

### 3.3. `UIResponder.h`

#### `PROTOCOLCLASS_INTERFACE0( UIResponder)`
- **Purpose:** Protocol defining the responder chain for event handling. Objects adopting UIResponder can receive and handle events, passing them up the chain if not handled.
- **Optional Methods:**
  - `-becomeFirstResponder` - Request to become first responder (default: NO)
  - `-resignFirstResponder` - Request to resign first responder (default: YES)
  - `-isFirstResponder` - Query first responder status (default: NO)
  - `-canBecomeFirstResponder` - Can accept first responder (default: NO)
  - `-canResignFirstResponder` - Can give up first responder (default: YES)
  - `-isFirstResponderEvent:` - Is this event targeting first responder (default: NO)
  - `-nextResponder` - Return next responder in chain (UIView→UIWindow→UIApplication)
  - `-isMouseMotionEnabled` - Should receive mouse motion events (queries for mouseDragged: implementations)

#### Event Handling Methods
- **Handle methods** - Walk responder chain until handled:
  - `-handleEvent:` - Generic event handler
  - `-handleInputEvent:` - Input event handler
  - `-handleMouseMotionEvent:` - Mouse motion handler
- **Accept methods** - Only consider receiver (do not walk chain):
  - `-willAcceptEvent:` - Query if will accept
  - `-acceptEventWithCallbacks:` - Accept and invoke appropriate callback
  - `-acceptInputEvent:` - Accept input event
  - `-acceptMouseMotionEvent:` - Accept mouse motion
  - `-acceptMouseButtonEvent:` - Accept mouse button
  - `-acceptMouseScrollEvent:` - Accept scroll wheel
  - `-acceptKeyboardEvent:` - Accept keyboard
  - `-acceptUnicodeEvent:` - Accept unicode
  - `-acceptActionEvent:` - Accept action
  - `-acceptOtherEvent:` - Accept other event types
  - `-didAcceptEvent:` - Notification after accepting event

#### `@interface NSObject ( UIFutureEvents)`
- **Purpose:** Optional event callback methods implemented by responders.
- **Keyboard:**
  - `-keyDown:` / `-keyUp:` - Keyboard events
- **Mouse Buttons:**
  - `-mouseDown:` / `-mouseUp:` - Left button
  - `-rightMouseDown:` / `-rightMouseUp:` - Right button
  - `-otherMouseDown:` / `-otherMouseUp:` - Other buttons
- **Mouse Motion:**
  - `-mouseDragged:` - Left button drag
  - `-rightMouseDragged:` - Right button drag
  - `-otherMouseDragged:` - Other button drag
- **Scroll:**
  - `-scrollWheel:` - Scroll wheel events

### 3.4. `UIControl.h`

#### `typedef NS_ENUM( NSUInteger, UIControlEvents)`
- **Purpose:** Event mask to filter which events trigger target/action callbacks.
- **Values:** LeftMouseDown/Up, RightMouseDown/Up, MiddleMouseDown/Up, OtherMouseDown/Up, MouseDragged variants, MouseEntered/Exited, KeyDown/Up, ScrollWheel, AnyEvent

#### `typedef NS_OPTIONS( NSUInteger, UIControlState)`
- **Purpose:** Control state flags for appearance and behavior.
- **Values:**
  - `UIControlStateNormal` (0x0) - Default state
  - `UIControlStateHighlighted` (0x1) - Mouse down or hover
  - `UIControlStateDisabled` (0x2) - Non-interactive
  - `UIControlStateSelected` (0x4) - Toggle on state
  - `UIControlStateSelecting` (0x8) - Temporary state during selection gesture
  - `UIControlStateFirstResponder` (0x10) - Has keyboard focus
- `UIControlStateUTF8String()` - State to string

#### `typedef NS_ENUM( NSUInteger, UIControlSelectionBehaviour)`
- **Purpose:** Defines when selection state changes occur.
- **Values:**
  - `UIControlSelectionBehaviourPush` - Select on mouseDown, deselect on mouseUp (momentary)
  - `UIControlSelectionBehaviourRelease` - Select on mouseUp (stays selecting until release)
  - `UIControlSelectionBehaviourPushSwitch` - Toggle on mouseDown
  - `UIControlSelectionBehaviourReleaseSwitch` - Toggle on mouseUp

#### `PROTOCOLCLASS_INTERFACE( UIControl, UIResponder)`
- **Purpose:** Base protocol for interactive controls that translate events into target/action or click callbacks.
- **Typedef:**
  - `UIControlClickHandler` - Function pointer: `UIInputEvent *(id <UIControl>, UIInputEvent *)`
- **Macros for Adopters:**
  - `UIControlIvars` - Standard ivars: selectionBehaviour, state, reflectedState, eventMask, target, action, click
  - `UIControlProperties` - Property declarations
  - `UIControlCopy()` - Support for `-copy`
  - `UIControlInit()` - Initialize with defaults
  - `UIControlDone()` - Cleanup (currently empty)
- **Properties:**
  - `selectionBehaviour` - When selection changes occur
  - `state` - Current control state flags
  - `reflectedState` - Private state for `-reflectState`
  - `eventMask` - Which events trigger callbacks
  - `target` - Target object for action
  - `action` - Selector to invoke on target
  - `click` - Alternative callback function pointer
- **Methods:**
  - `-setNeedsDisplay` - Request visual update (threadsafe)
  - `-shouldConsumeMouseEvent:` - Query if event should be consumed
  - `-mouseUp:` - Handle mouse up event
  - `-performClickAndTargetActionCallbacks:fallbackEvent:` - Invoke click/target-action, return fallback if none
  - `-performClickAndTargetActionCallbacks:` - Invoke callbacks, return nil if none

#### State Convenience Methods
- `-isHighlighted` / `-setHighlighted:` - Highlighted state
- `-isEnabled` / `-setEnabled:` - Enabled/disabled state
- `-isSelected` / `-setSelected:` - Selected state
- `-mulleToggleSelectedState` - Toggle selected bit
- `-mulleToggleHighlightedState` - Toggle highlighted bit
- `-reflectState` - Update reflectedState, returns YES if changed
- `-sendActionOn:` - Configure event mask for action

#### Utility Methods
- `-UTF8String` - Debug string representation
- `-__isUIControl` - Runtime type check (threadsafe)

### 3.5. `UICursor.h`

#### `typedef NS_ENUM( NSUInteger, UICursorStandardShape)`
- **Purpose:** Standard cursor shapes supported across platforms.
- **Values:**
  - `UICursorDefault` (0) - Arrow pointer
  - `UICursorTextInput` (1) - I-beam for text selection
  - `UICursorDrag` (2) - Hand for dragging
  - `UICursorHorizontalResize` (3) - Horizontal resize arrow
  - `UICursorVerticalResize` (4) - Vertical resize arrow
  - `UICursorDiagonalResize` (5) - Diagonal resize arrow (requires GLFW 3.4+)
  - `n_UICursorStandardShapes` (6) - Count of shapes

#### `typedef void UICursor`
- **Purpose:** Opaque cursor handle. Cursors are managed by UIApplication and must not be freed directly.

### 3.6. `UIPasteboard.h`

#### `@interface UIPasteboard`
- **Purpose:** Clipboard/pasteboard abstraction tied to a specific window (platform limitation).
- **Properties:**
  - `window` (id <UIWindow>, retain) - Associated window
- **Methods:**
  - `+pasteboardWithWindow:` - Create pasteboard for window
  - `-textUTF8String` - Get clipboard text (C string, do not free)
  - `-setTextUTF8String:` - Set clipboard text

### 3.7. `UIWindowTypes.h`

#### `typedef NS_OPTIONS( NSUInteger, UIWindowStyle)`
- **Purpose:** Window style flags controlling behavior and rendering.
- **Values:**
  - `UIWindowStyleNop` (0x40000000) - Explicit no-op to avoid defaults
  - `UIWindowStyleResizable` (0x0004) - User can resize
  - `UIWindowStyleHidden` (0x0008) - Not visible
  - `UIWindowStyleOffscreen` (0x0010) - Pure offscreen rendering
  - `UIWindowStyleSingleBuffer` (0x0020) - Single buffering (limited support)
  - `UIWindowStyleTransparent` (0x0040) - Transparent background
  - `UIWindowStyleFloating` (0x0080) - Always on top
  - `UIWindowStyleBare` (0x0100) - No window decorations
  - `UIWindowStylePlanes` (0x0200) - Plane rendering mode
  - `UIWindowStyleNoView` (0x0400) - No UIView created
  - `UIWindowStyleAntiAlias` (0x1000) - Enable MSAA or edge AA
  - `UIWindowStyleForceEdgeAntiAlias` (0x2000) - Force edge AA only
  - `UIWindowStyleStencilStrokes` (0x4000) - Stencil buffer for strokes
  - `UIWindowStyleClearType` (0x8000) - ClearType text rendering
  - `UIWindowStyleTraceDrawCalls` (0x10000) - Debug draw call tracing
  - `UIWindowStyleNoDrawing` (0x20000) - Disable drawing
  - `UIWindowStyleRetained` (0x100000) - Retained framebuffer on separate thread
  - `UIWindowStyleRetainedOnMainThread` (0x200000) - Retained framebuffer on main thread
  - `UIWindowStyleProfileQueue` (0x400000) - Profile queue performance
  - `UIWindowStyleMousePolling` (0x800000) - Poll mouse instead of events
  - `UIWindowOpenGLCoreProfile` (0x1000000) - OpenGL Core profile
  - `UIWindowOpenGLForward` (0x4000000) - Forward-compatible OpenGL
  - `UIWindowOpenGLLibraryFallback` (0x8000000) - Try fallback OpenGL libraries
  - `UIWindowOpenGLDeprecated` (0x10000000) - Include deprecated OpenGL
  - `UIWindowNotcursesMouseDisable` (0x20000000) - Disable terminal mouse
- **Functions:**
  - `UIWindowStyleUTF8String()` - Style flags to string
  - `UIWindowStyleParseUTF8String()` - Parse string to style flags
  - `UIWindowsStyleMaskByEnabling()` / `ByDisabling()` / `BySetting()` - Manipulate style masks

#### Window Style Details
- **UIWindowStyleAntiAlias**: Tries MSAA if supported, falls back to edge AA. Enabled by default.
- **UIWindowStyleStencilStrokes**: Draws strokes to stencil buffer first for higher quality (performance cost). Ensures strokes appear outside fills.
- **UIWindowStyleRetained**: Retains rendered framebuffer between frames. Back buffer rendered while front displayed, then quickly copied on refresh. Optimizes for rendering throughput, essential for X11 to avoid black borders during resize.

#### `@protocol UIWindow`
- **Purpose:** Protocol for window objects managed by UIApplication.
- **Key Methods:**
  - `-OSWindow` - Return UIOSWindow (threadsafe)
  - `-os_window` - Return platform handle (GLFW/SDL window)
  - `-displayFrameIfNeeded:` - Render frame if needed (main-thread-safe)
  - `-syncOSWindowPropertyChangesIfNeeded` - Sync property changes (threadsafe)
  - `-setNeedsRefresh` / `-shouldClose` - Control window state (threadsafe)
  - `-applicationDidAddWindow:` / `-applicationDidRemoveWindow:` - Lifecycle callbacks
  - `-firstResponder` - Current first responder
  - `-pasteboardCString` / `-setPasteboardCString:` - Clipboard access

#### `@protocol UIOSWindow`
- **Purpose:** Protocol for OS-level window implementation (GLFW, SDL).
- **Key Properties:**
  - `windowEventsReceiver` / `eventsReceiver` - Event routing
  - `discardEventsMask` - Filter events
  - `parentWindow` - Owning UIWindow
  - `antiAliasing` (readonly) - Is AA enabled
  - `windowEventsCallback` / `otherRetainedEventsCallback` - Callbacks
  - `frameCallback` - Basic rendering callback
  - `inputState` (readonly) - Current input state
- **Key Methods:**
  - `-initWithFrame:titleUTF8String:styleMask:graphicsHints:sharingWindow:` - Initialize
  - `-shareID` - Context sharing identifier
  - `-setFrameRateLimiter:` / `-frameRateLimiter` - Control rate limiting (threadsafe)
  - `-setFrameRate:` / `-frameRate` - Control frame rate (threadsafe)
  - `-backend` - Graphics backend enum (threadsafe)
  - `-screenOrPrimaryScreen:` / `-screen` - Query associated screen
  - `-gamepadAtIndex:` - Get gamepad
  - `-getOSWindowInfo:` - Query window info (threadsafe)
  - OS methods: `os_setSwapInterval:`, `os_activateGraphicsContext`, `os_swapBuffers`, `os_requestClose`, `os_show`, `os_hide`, `os_setWindowPosition:`, etc.

#### `@protocol UIScreen`
- **Purpose:** Monitor/display abstraction.
- **Class Methods:**
  - `+numberOfScreens` - Count screens (threadsafe)
  - `+screenAtIndex:` - Get screen (threadsafe)
- **Methods:**
  - `-getScreenInfo:` - Get screen info struct (threadsafe)
  - `-refreshRate` / `-frame` / `-canvas` - Query properties (threadsafe)

#### `struct UIScreenInfo`
- `frame` (CGRect) - Full screen bounds
- `canvas` (CGRect) - Workarea excluding taskbar/menubar
- `contentScale` (CGVector) - DPI scaling factor
- `physicalSize` (CGSize) - Physical dimensions in mm
- `dpi` (CGFloat) - Dots per inch
- `colorBits[4]` (char) - RGBA bit depths
- `refreshRate` (mulle_relativetime_t) - Monitor refresh rate

#### `@protocol UIGamepad`
- **Purpose:** Gamepad/joystick abstraction.
- **Properties:**
  - `guidUTF8String` - GUID string
  - `isJoystick` - Is joystick vs gamepad
  - `osIndex` - OS-assigned index
- **Class Methods:**
  - `+gamepadAtOSIndex:` - Get by OS index
  - `+osIndexRange` - Range of OS indices
- **Methods:**
  - `-getGamepadInfo:` - Get button/axis state (threadsafe)
  - `-direction` - DPad direction (threadsafe)
  - `-stateOfGamepadButton:` - Button state (threadsafe)
  - `-getAnalogStickWithIndex:axes:` - Analog stick (threadsafe)
  - `-getDigitalStickWithIndex:direction:` - Digital stick (threadsafe)
  - `-os_pollGamepadInfo` - Update state

#### `struct UIGamepadInfo`
- `axes[6]` (float) - Two 3D analog sticks
- `buttons[32]` (unsigned char) - Up to 32 buttons
- `sticks[4]` (unsigned char) - Up to 4 digital sticks (CADirection)
- `numberOfSticks` / `numberOfButtons` / `numberOfAxes` - Counts
- `isJoystick` - Joystick vs gamepad
- Helper functions: `UIGamepadInfoGetButton()`, `UIGamepadInfoGetDigitalStick()`, `UIGamepadInfoGetDPad()`, `UIGamepadInfoGetAnalogStick()`

#### `@protocol UITimerReceiver`
- **Purpose:** Objects that receive timer callbacks.
- **Method:** `-handleRetainedTimer:` - Consume retained timer (threadsafe)

#### `@protocol UIEventReceiver`
- **Purpose:** Objects that receive events from UIApplication.
- **Methods:**
  - `-handleWindowEvent:` - Handle window event (threadsafe)
  - `-receiveRetainedEvent:` - Consume retained event (threadsafe)

#### Constants
- `UIWindowFrameRateUnsynced` (0.0) - Render as fast as possible
- `UIWindowFrameRateAsync` (INFINITY) - Wait for events
- `UIWindowFrameRateSynced` (-INFINITY) - Match monitor refresh rate
- `UIScreenAssumedRefreshRate` (1.0/60.0) - Default refresh rate
- `UIScreenAssumedRefreshRateHz` (60.0) - Default Hz

## 4. Performance Characteristics

### Event System
- **Event Reuse**: O(1) allocation from pool, reduces memory pressure and allocation overhead. Events are not thread-local, requiring memory barriers on reuse.
- **Event Distribution**: O(n) where n is responder chain depth, typically shallow (view → window → application).

### Responder Chain
- **Event Handling**: O(n) traversal up responder chain until handled. Typically terminates early (2-5 hops).
- **Not thread-safe**: Responder chain traversal must occur on main thread.

### Window Management
- **Add/Remove Window**: O(1) array operations with mulle_array.
- **Query Window**: O(n) linear search by handle or index.
- **Thread Safety**: Main thread only, no locking overhead.

### Screen Management
- **Screen Queries**: O(n) with lock protection for thread safety. Screen count typically small (1-3).
- **Frame Intersection**: O(n) per screen, but n is small.

### Gamepad Management
- **Gamepad Queries**: O(n) with lock protection. Hot-plug support means array may have holes (nil entries).

### Timer Management
- **Add/Remove Timer**: O(n) with lock protection, uses mulle_structarray. Holes created on removal, compacted periodically.
- **Timer Dispatch**: O(n) scan during run loop iteration.

### Main Thread Invocations
- **Enqueue**: O(1) with lock, uses mulle_pointermultififo (lock-free multi-producer, single-consumer when consumed on main thread).
- **Dequeue**: O(n) where n is pending invocations, processed in batch during run loop.
- **Blocking Sync**: Caller blocks until invocation completes on main thread, adds synchronization overhead.

### Cursor Management
- **Standard Cursors**: O(1) lookup, created once on initialization.
- **Custom Cursors**: O(n) map lookup with lock protection.

## 5. AI Usage Recommendations & Patterns

### Best Practices

1. **Always use `-initWithInputState:` constructors for events** rather than `+alloc` followed by property setters. The input state must be provided at initialization.

2. **Respect threading constraints strictly**:
   - Call window management methods only from main thread
   - Use threadsafe methods for screen/gamepad queries from any thread
   - Use `-invokeOnMainThread:` to execute window operations from background threads

3. **Use factory methods and convenience constructors**:
   - `[UIApplication sharedInstance]` not `[[UIApplication alloc] init]`
   - `[UIEvent instance]` not `[UIEvent alloc]`
   - `+pasteboardWithWindow:` not `[[UIPasteboard alloc] initWithWindow:]`

4. **Adopt protocols correctly**:
   - UIWindow and UIOSWindow implementors must implement all required methods
   - UIResponder adopters should implement specific event methods (keyDown:, mouseDown:) rather than generic handleEvent:
   - UIControl adopters must use `UIControlIvars` and `UIControlProperties` macros

5. **Handle event ownership correctly**:
   - Events returned from event methods are typically autoreleased
   - Methods taking `NS_CONSUMED` events take ownership (e.g., `-receiveRetainedEvent:`)
   - Do not retain events unnecessarily; they are reused

6. **Use debugging flags for troubleshooting**:
   ```objective-c
   [app setDebuggingFlags:UIApplicationDebugEvent];
   ```
   Set `UIApplicationDebuggingFlags` environment variable to enable logging during initialization.

7. **Disable event reuse during leak detection**:
   ```objective-c
   [UIEvent setReuseEvents:NO];
   ```
   Or set `MULLE_UI_REUSE_EVENTS=NO` environment variable.

8. **Use `UIApp` global for convenience in event handlers** where you already know the singleton exists.

9. **Always process `-runInvocations` during custom run loops** if you implement your own event loop instead of using `-runApp`.

10. **Use `-requestTerminate` from background threads**, not `-terminate`. The latter must be called from main thread only.

### Common Pitfalls

1. **Do not call `-alloc`/`-init` on UIApplication**. Always use `+sharedInstance` to get or create the singleton.

2. **Do not access UIEvent `_location` or `_locationView` ivars directly**. These are internal and modified by UIView during event routing. Use the location property.

3. **Do not retain standard cursors returned by `-cursorWithStandardShape:`**. They are owned by UIApplication and persist for the app lifetime.

4. **Do not free C strings returned by `-textUTF8String` or `-nameUTF8String`**. These are autoreleased or owned by the object.

5. **Do not assume gamepad at index N is stable**. Gamepads can be unplugged, causing nil returns. Always check for nil.

6. **Do not mix UIWindow `-addWindow:` and `-removeWindow:` calls across threads**. Both must be main thread only.

7. **Do not implement custom `+initialize` or `+deinitialize` in UIApplication subclasses**. These are reserved for the framework.

8. **Do not override UIEvent `-alloc` unless you understand the pooling mechanism**. If subclassing UIKeyboardEvent, UIUnicodeEvent, UIMouseButtonEvent, UIMouseMotionEvent, UIMouseScrollEvent, or UIActionEvent, you must override both `+alloc` and `-dealloc` to use `NSAllocateObject` and `NSDeallocateObject` for proper pooling.

9. **Do not assume `-runLoopIteration` returns immediately**. It may block waiting for events depending on frame rate settings.

10. **Do not query `-numberOfWindows` from background threads**. Window management is main thread only, even for queries.

### Idiomatic Usage

**Creating and Running an Application:**
```objective-c
int   main( int argc, char **argv)
{
   UIApplication   *app;
   id <UIWindow>   window;
   
   app    = [UIApplication sharedInstance];
   window = [ConcreteWindow windowWithFrame:CGRectMake( 100, 100, 800, 600)
                               titleUTF8String:"My Window"
                                     styleMask:UIWindowStyleResizable
                                 graphicsHints:0];
   
   return( UIApplicationRunWindow( window));
}
```

**Custom Application Subclass:**
```objective-c
@interface MyApplication : UIApplication
@end

@implementation MyApplication

- (void) runInvocations
{
   [super runInvocations];
   // custom main-thread work
}

@end

int   main( int argc, char **argv)
{
   return( UIApplicationMain( argc, argv, [MyApplication class], nil));
}
```

**Handling Events in UIResponder:**
```objective-c
@implementation MyView

- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   NSUInteger   key;
   
   key = [event key];
   if( key == UIEventKeyEscape)
   {
      [[self window] performClose:self];
      return( nil);  // consumed
   }
   
   return( [[self nextResponder] keyDown:event]);  // pass to next
}

- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint   location;
   
   location = [event location];
   mulle_printf( "Click at %s\n", CGPointUTF8String( location));
   
   [self setNeedsDisplay];
   return( nil);  // consumed
}

@end
```

**Using Timers:**
```objective-c
@implementation MyWindow

- (void) applicationDidAddWindow:(UIApplication *) app
{
   NSInvocation   *invocation;
   NSTimer        *timer;
   
   invocation = [NSInvocation invocationWithTarget:self
                                           selector:@selector( timerFired:)];
   
   timer = [NSTimer mulleTimerWithRelativeTimeInterval:0.0
                                       repeatInterval:1.0
                                           invocation:invocation];
   
   [app addTimer:timer
forTimerReceiver:self];
}

- (void) timerFired:(NSTimer *) timer
{
   mulle_printf( "Timer fired!\n");
}

- (void) applicationDidRemoveWindow:(UIApplication *) app
{
   [app removeAllTimersForTimerReceiver:self];
}

@end
```

**Screen Queries (Threadsafe):**
```objective-c
- (void) backgroundThreadMethod
{
   UIApplication   *app;
   NSUInteger      i;
   NSUInteger      n;
   id <UIScreen>   screen;
   
   app = UIApp;
   n   = [app numberOfScreens];
   
   for( i = 0; i < n; i++)
   {
      screen = [app screenAtIndex:i];
      if( screen)
         mulle_printf( "Screen %ld: %s\n", i, [[screen nameUTF8String]);
   }
}
```

**Main Thread Invocations:**
```objective-c
- (void) backgroundThreadSetWindowTitle:(NSString *) title
{
   NSInvocation   *invocation;
   
   invocation = [NSInvocation invocationWithTarget:self
                                           selector:@selector( setTitleUTF8String:)
                                          argument:[title UTF8String]];
   
   [UIApp invokeOnMainThread:invocation];
}
```

**Custom Cursors:**
```objective-c
- (void) registerCustomCursor
{
   struct CGBitmap   bitmap;
   CGPixelPoint      hotSpot;
   UICursor          *cursor;
   
   bitmap  = CGBitmapMake( 32, 32, CGPixelFormatRGBA32);
   // ... fill bitmap data ...
   hotSpot = CGPixelPointMake( 16, 16);
   
   cursor = [UIApp registerCursorBitmap:bitmap
                                hotSpot:hotSpot
                       forKeyUTF8String:"my-cursor"
                    scaleToStandardSize:YES];
   
   CGBitmapRelease( bitmap, NULL);
}

- (void) useCustomCursor
{
   UICursor   *cursor;
   
   cursor = [UIApp cursorForKeyUTF8String:"my-cursor"];
   if( cursor)
      [[self OSWindow] os_setCursor:cursor];
}
```

**UIControl Implementation:**
```objective-c
@interface MyButton : NSObject <UIControl>
{
   UIControlIvars;
}

UIControlProperties;

@end

@implementation MyButton

- (instancetype) init
{
   if( (self = [super init]))
   {
      UIControlInit( self);
      _selectionBehaviour = UIControlSelectionBehaviourRelease;
      _eventMask          = UIControlEventLeftMouseDown | UIControlEventLeftMouseUp;
   }
   return( self);
}

- (void) dealloc
{
   UIControlDone( self);
   [super dealloc];
}

- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   [self setHighlighted:YES];
   [self setNeedsDisplay];
   return( nil);
}

- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   [self setHighlighted:NO];
   [self setSelected:YES];
   [self setNeedsDisplay];
   
   return( [self performClickAndTargetActionCallbacks:event]);
}

@end
```

## 6. Integration Examples

### Example 1: Basic Application with Single Window

```c
#import <MulleUIApplication/MulleUIApplication.h>

// Minimal UIWindow implementation for testing
@interface TestWindow : NSObject <UIWindow>
{
   BOOL   _shouldClose;
}
@end

@implementation TestWindow

- (id <UIOSWindow>) OSWindow
{
   return( nil);
}

- (void *) os_window
{
   return( NULL);
}

- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now
{
   return( INFINITY);  // No animation, wait for events
}

- (void) syncOSWindowPropertyChangesIfNeeded
{
}

- (void) setNeedsRefresh
{
}

- (BOOL) shouldClose
{
   return( _shouldClose);
}

- (void) applicationDidAddWindow:(UIApplication *) app
{
   mulle_printf( "Window added to application\n");
}

- (void) applicationDidRemoveWindow:(UIApplication *) app
{
   mulle_printf( "Window removed from application\n");
}

- (void) requestClose
{
   _shouldClose = YES;
}

@end


int   main( void)
{
   UIApplication   *app;
   TestWindow      *window;
   
   app    = [UIApplication sharedInstance];
   window = [TestWindow instance];
   
   [app addWindow:window];
   
   // Simulate some work
   mulle_printf( "Application has %ld window(s)\n", [app numberOfWindows]);
   
   [window requestClose];
   
   return( [app terminate]);
}
```

### Example 2: Event Creation and Inspection

```c
#import <MulleUIApplication/MulleUIApplication.h>

int   main( void)
{
   UIKeyboardEvent         *keyEvent;
   UIMouseButtonEvent      *mouseEvent;
   UIMouseScrollEvent      *scrollEvent;
   struct UIInputState     inputState;
   CGPoint                 scrollOffset;
   
   // Create keyboard event
   inputState = UIInputStateMake( CGPointMake( 100, 200),
                                 UIEventKeyModifierShift | UIEventKeyModifierControl,
                                 0);
   
   keyEvent = [[[UIKeyboardEvent alloc] initWithInputState:&inputState
                                                       key:UIEventKeyEscape
                                                  scanCode:1
                                                    action:UIEventButtonActionDown
                                                 isARepeat:NO] autorelease];
   
   mulle_printf( "Key Event:\n");
   mulle_printf( "  Type: %s\n", UIEventTypeUTF8String( [keyEvent eventType]));
   mulle_printf( "  Key: %s\n", UIEventKeyUTF8String( [keyEvent key]));
   mulle_printf( "  Action: %s\n", UIEventButtonActionUTF8String( [keyEvent action]));
   mulle_printf( "  Location: %s\n", CGPointUTF8String( [keyEvent locationInWindow]));
   mulle_printf( "  Modifiers: %s\n", UIEventKeyModifierUTF8String( [keyEvent keyModifiers]));
   
   // Create mouse button event
   inputState = UIInputStateMake( CGPointMake( 50, 75), 0, UIEventMouseButtonLeft);
   
   mouseEvent = [[[UIMouseButtonEvent alloc] initWithInputState:&inputState
                                                         button:UIEventMouseButtonLeft
                                                         action:UIEventButtonActionDown] autorelease];
   
   mulle_printf( "\nMouse Event:\n");
   mulle_printf( "  Type: %s\n", UIEventTypeUTF8String( [mouseEvent eventType]));
   mulle_printf( "  Button: %s\n", UIEventMouseButtonUTF8String( UIEventMouseButtonLeft));
   mulle_printf( "  Location: %s\n", CGPointUTF8String( [mouseEvent locationInWindow]));
   
   // Create scroll event with acceleration
   inputState    = UIInputStateMake( CGPointMake( 150, 150), 0, 0);
   scrollOffset  = CGPointMake( 0.0, 10.0);
   
   scrollEvent = [[[UIMouseScrollEvent alloc] initWithInputState:&inputState
                                                    scrollOffset:scrollOffset] autorelease];
   
   mulle_printf( "\nScroll Event:\n");
   mulle_printf( "  Type: %s\n", UIEventTypeUTF8String( [scrollEvent eventType]));
   mulle_printf( "  Offset: %s\n", CGPointUTF8String( [scrollEvent scrollOffset]));
   mulle_printf( "  Accelerated: %s\n",
                CGPointUTF8String( [scrollEvent scrollOffsetWithAcceleration:YES
                                                                useModifiers:NO]));
   
   return( 0);
}
```

### Example 3: Threadsafe Screen and Gamepad Queries

```c
#import <MulleUIApplication/MulleUIApplication.h>

static void   print_screen_info( id <UIScreen> screen, NSUInteger index)
{
   struct UIScreenInfo   info;
   
   [screen getScreenInfo:&info];
   
   mulle_printf( "Screen %ld:\n", index);
   mulle_printf( "  Frame: %s\n", CGRectUTF8String( info.frame));
   mulle_printf( "  Canvas: %s\n", CGRectUTF8String( info.canvas));
   mulle_printf( "  DPI: %.1f\n", info.dpi);
   mulle_printf( "  Refresh Rate: %.3f Hz\n", 1.0 / info.refreshRate);
}

static void   print_gamepad_info( id <UIGamepad> gamepad, NSUInteger index)
{
   struct UIGamepadInfo   info;
   NSUInteger             i;
   
   [gamepad getGamepadInfo:&info];
   
   mulle_printf( "Gamepad %ld:\n", index);
   mulle_printf( "  GUID: %s\n", [gamepad guidUTF8String]);
   mulle_printf( "  Joystick: %s\n", info.isJoystick ? "YES" : "NO");
   mulle_printf( "  Buttons: %d\n", info.numberOfButtons);
   mulle_printf( "  Axes: %d\n", info.numberOfAxes);
   
   for( i = 0; i < info.numberOfButtons && i < 8; i++)
   {
      if( info.buttons[ i])
         mulle_printf( "    Button %ld: pressed\n", i);
   }
}

int   main( void)
{
   UIApplication     *app;
   NSUInteger        i;
   NSUInteger        n;
   id <UIScreen>     screen;
   id <UIGamepad>    gamepad;
   
   app = [UIApplication sharedInstance];
   
   // Query screens (threadsafe)
   n = [app numberOfScreens];
   mulle_printf( "Found %ld screen(s)\n\n", n);
   
   for( i = 0; i < n; i++)
   {
      screen = [app screenAtIndex:i];
      if( screen)
         print_screen_info( screen, i);
   }
   
   // Query gamepads (threadsafe)
   mulle_printf( "\n");
   for( i = 0; i < 16; i++)
   {
      gamepad = [app gamepadAtIndex:i];
      if( gamepad)
         print_gamepad_info( gamepad, i);
   }
   
   return( 0);
}
```

### Example 4: Timer Management

```c
#import <MulleUIApplication/MulleUIApplication.h>

@interface TimerReceiver : NSObject <UITimerReceiver>
{
   NSUInteger   _count;
}
@end

@implementation TimerReceiver

- (void) handleRetainedTimer:(NSTimer *) timer
{
   _count++;
   mulle_printf( "Timer fired %ld times\n", _count);
   
   if( _count >= 5)
   {
      [UIApp requestTerminate];
   }
   
   [timer release];
}

@end

@interface MinimalWindow : NSObject <UIWindow>
@end

@implementation MinimalWindow

- (id <UIOSWindow>) OSWindow         { return( nil); }
- (void *) os_window                 { return( NULL); }
- (BOOL) shouldClose                 { return( NO); }
- (void) setNeedsRefresh             { }
- (void) syncOSWindowPropertyChangesIfNeeded  { }

- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now
{
   return( INFINITY);
}

- (void) applicationDidAddWindow:(UIApplication *) app     { }
- (void) applicationDidRemoveWindow:(UIApplication *) app  { }

@end

int   main( void)
{
   UIApplication   *app;
   TimerReceiver   *receiver;
   NSInvocation    *invocation;
   NSTimer         *timer;
   
   app      = [UIApplication sharedInstance];
   receiver = [TimerReceiver instance];
   
   // Add dummy window so app doesn't terminate immediately
   [app addWindow:[MinimalWindow instance]];
   
   // Create timer that fires every 0.5 seconds
   invocation = [NSInvocation invocationWithTarget:receiver
                                           selector:@selector( handleRetainedTimer:)];
   
   timer = [NSTimer mulleTimerWithRelativeTimeInterval:0.5
                                       repeatInterval:0.5
                                           invocation:invocation];
   
   [app addTimer:timer
forTimerReceiver:receiver];
   
   mulle_printf( "Starting timer (will fire 5 times)\n");
   
   return( [app runApp]);
}
```

### Example 5: Implementing UIResponder for Event Handling

```c
#import <MulleUIApplication/MulleUIApplication.h>

@interface EventLogger : NSObject <UIResponder>
@end

@implementation EventLogger

- (id <UIResponder>) nextResponder
{
   return( nil);  // Top of responder chain
}

- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   mulle_printf( "keyDown: %s (scan:%ld, mods:0x%lx)\n",
                UIEventKeyUTF8String( [event key]),
                [event scanCode],
                [event keyModifiers]);
   
   if( [event key] == UIEventKeyEscape)
   {
      mulle_printf( "Escape pressed, terminating\n");
      [UIApp requestTerminate];
      return( nil);
   }
   
   return( [[self nextResponder] keyDown:event]);
}

- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint   location;
   
   location = [event locationInWindow];
   
   mulle_printf( "mouseDown: %s at %s (mods:0x%lx)\n",
                UIEventMouseButtonUTF8String( [event button]),
                CGPointUTF8String( location),
                [event keyModifiers]);
   
   return( [[self nextResponder] mouseDown:event]);
}

- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event
{
   CGPoint   location;
   
   location = [event locationInWindow];
   
   mulle_printf( "mouseDragged: %s (buttons:0x%lx)\n",
                CGPointUTF8String( location),
                [event buttonStates]);
   
   return( [[self nextResponder] mouseDragged:event]);
}

- (UIInputEvent *) scrollWheel:(UIMouseScrollEvent *) event
{
   CGPoint   offset;
   
   offset = [event scrollOffset];
   
   mulle_printf( "scrollWheel: %s\n", CGPointUTF8String( offset));
   
   return( [[self nextResponder] scrollWheel:event]);
}

- (BOOL) isMouseMotionEnabled
{
   return( YES);  // Enable mouse motion tracking
}

@end

int   main( void)
{
   EventLogger   *logger;
   
   logger = [EventLogger instance];
   
   mulle_printf( "Event logger ready\n");
   mulle_printf( "Press Escape to exit\n\n");
   
   // In real application, logger would be set as first responder
   // and events would be routed through it
   
   return( 0);
}
```

## 7. Dependencies

Direct mulle-sde library dependencies:

- **MulleObjCTimeFoundation** - Provides NSTimer, NSInvocation, NSThread, NSLock, and time handling from MulleFoundation stack
- **MulleUIBase** - Provides geometry types (CGRect, CGPoint, CGSize), color types, UIInputState, and basic UI protocols
- **mulle-objc-list** - Build-time tool for listing Objective-C runtime information (no-link dependency)

MulleUIApplication sits above MulleFoundation and MulleUIBase in the dependency hierarchy, and below MulleUIWindow which provides concrete window implementations (MulleGLFWWindow, MulleSDLWindow, etc.).
