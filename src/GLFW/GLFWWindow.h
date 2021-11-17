//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"

#import "UIWindowStyle.h"


@class UIEvent;
@class CGContext;


@protocol GLFWWindowEventReceiver

- (void) handleWindowEvent:(UIEvent *) event;
- (void) queueRetainedEvent:(UIEvent *) event;

@end

//
// The GLFWWindow has the GLFW window handle and implicitly the
// drawing context. A UIWindow will have possibly two GLFWWindows
// associated with it. One for drawing offscreen and one for display onscreen.
// Events for the window are forwarded from here.
//
// If you create GLFWWindow manually, be sure to finalize them before
// UIApplication terminate, otherwise the context are gone and finalization
// can't happen.
//
@interface GLFWWindow : NSObject
{
   void        *_window;   // GLFWwindow

   NSLock      *_renderContextLock;

   CGPoint     _mouseLocation;
   uint64_t    _mouseButtonStates;
   uint64_t    _modifiers;

   GLFWWindow  *_sharingWindow;
   NSInteger   _shareId;
}

// window events are called via -handleEvent:
@property( assign) id <GLFWWindowEventReceiver>  windowEventsReceiver;

// window events are called via -queueRetainedEvent:
@property( assign) id <GLFWWindowEventReceiver>  eventsReceiver;

@property( assign) NSUInteger  discardEventsMask;
@property( assign) CGFloat     scrollWheelSensitivity;
@property( assign, getter=isScrollWheelNatural) BOOL scrollWheelNatural;

@property( retain, readonly) CGContext   *context;

- (NSInteger) shareId;

+ (CGFloat) os_primaryMonitorPPI;
+ (void) os_setSwapInterval:(NSUInteger) value;
+ (CGFloat) os_primaryMonitorRefreshRate;

- (instancetype) initWithFrame:(CGRect) frame
                  titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask;

// sharingWindow is retained. We will be able to share textures with it
- (instancetype) initWithFrame:(CGRect) frame
                  titleUTF8String:(char *) title
                    styleMask:(NSUInteger) styleMask
                sharingWindow:(GLFWWindow *) sharingWindow;

- (void) os_destroyWindow;

- (CGSize) os_windowSize;
- (CGRect) os_windowFrame;


// bind GL context of the window to the current thread
// synonymous with activate
- (void) os_startRender;
- (void) os_endRender;
- (struct CGBitmapSize) os_framebufferSize;
- (void) os_swapBuffers;

- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

- (void) os_show;
- (void) os_hide;


//
// OS Pasteboard
// prefix with os ?
- (char *) pasteboardCString;
- (void) setPasteboardCString:(char *) s;

@end
