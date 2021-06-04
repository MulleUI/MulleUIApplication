#import "UIView.h"


struct CGFrameInfo;

typedef UIView   UIWindowPlane;

@class UIPasteboard;
@class UIEvent;
@class UIApplication;



// values for frameRate
#define UIWindowFrameRateUnsynced   0.0        // as fast as possible
#define UIWindowFrameRateAsync      INFINITY   // wait until an event hits
#define UIWindowFrameRateSynced     -INFINITY  // tied to monitor frame rate (or 1/60.0 if not available)


// mulle addition
enum MulleWindowStyleMask
{
//  MulleWindowStyleMaskClosable        = 0x1,
//  MulleWindowStyleMaskMiniaturizable  = 0x2,
  MulleWindowStyleMaskResizable         = 0x4,
  MulleWindowStyleMaskInvisible         = 0x8,
  MulleWindowStyleMaskNoEdgeAntialias   = 0x10,
  MulleWindowStyleMaskNoStencilStrokes  = 0x20
};

#define ui_window_pointer_fifo   mulle__pointerfifo128

#define ui_window_pointer_fifo_init   _mulle__pointerfifo128_init
#define ui_window_pointer_fifo_done   _mulle__pointerfifo128_done
#define ui_window_pointer_fifo_write  _mulle__pointerfifo128_write
#define ui_window_pointer_fifo_read_barrier   _mulle__pointerfifo128_read_barrier


// mulle addition
@protocol UIWindowRenderDelegate

// none of these are optional, implement them all
// call before beginRender
- (void) windowWillBeginRender:(UIWindow *) window;

// cabll before endRender
- (void) windowWillEndRender:(UIWindow *) window;

// call after endRender
- (void) windowDidEndRender:(UIWindow *) window;

@end


//
// TODO: firstResponder needed for UITextField to gain keyboard
//       focus immediately
//
@interface UIWindow : UIView
{
   void               *_window;            // GLFWwindow
   CGContext          *_context;           //
	NSUInteger         _didRender;
   CGSize             _resizeSize;
   NSUInteger         _discardEvents;      // bitfield of UIEventtypes ?
   id                 _firstResponder;
   void               *_quadtree;

   struct mulle_pointerarray   _trackingViews; // views with tracking areas
   struct mulle_pointerarray   _enteredViews;  // views with mouseEntered: sent
   struct mulle_pointerarray   _delegateViews; // views with need willRender: sent

   CGRect             _originalRect;
   CGRect             _subdivideRect;
   CGRect             _dividedRects[ 4];
   NSUInteger         _nDividedRects;
   NSUInteger         _nTest;
   NSLock             *_renderContextLock;

   //
   // 8Khz at 60fps = 133 events, 256 should be ample
   // The queue is single consumer/single producer thread. The producer is
   // ALWAYS the main thread. The consumer is _thread. (can also be the
   // main thread)
   //
   struct ui_window_pointer_fifo   _eventQueue;
   // need to setNeedsDisplay to get the renderer out of the lock and start
   // the render. The _renderContextLock still needs to be observed when
   // attempting to modify the view hierarchy ?

   NSConditionLock   *_needsDisplayLock;
   BOOL               _resizing;
   CAAbsoluteTime     _lastResizeEventTimestamp;
   CAAbsoluteTime     _lastDidFramebufferSwapTimestamp;
   CAAbsoluteTime     _lastDidProcessEventsTimestamp;
   BOOL               _shouldClose;

   struct mulle_pointerarray   _renderQueue; // layers to render

}

@property( retain) id                   userInfo;
// TODO: pasteboard is a global resource and is on Application ?
@property( retain) UIPasteboard         *pasteboard;
@property( assign) NSThread             *thread;
@property( assign, readonly) CGPoint    mouseLocation;
@property( assign, readonly) uint64_t   mouseButtonStates;
@property( assign, readonly) uint64_t   modifiers;
@property( assign) CGFloat              scrollWheelSensitivity;

@property( assign, readonly) CGFloat    primaryMonitorPPI;
@property( assign, readonly) CGFloat    primaryMonitorRefreshRate;

@property( assign, getter=isScrollWheelNatural) BOOL scrollWheelNatural;
@property( assign) CGFloat              eventFrequency;

@property( assign) CGColorRef           backgroundColor;

// as the framebufferSize via glfw calls can only be done on mainthread
// we keep a shadow, that gets updated by glfw window events
@property( assign, readonly) CGSize     framebufferSize;

// used for MulleUIPerformance
@property( assign) id <UIWindowRenderDelegate>   renderDelegate;

@property( assign) CGFloat              frameRate;
@property( assign) NSUInteger           swapInterval;

// nanovg will be done here, here is good time to do plain
// OpenGL calls, endRender won't have happened yet

// Rendercallbacks. If the renderer is in its own thread, then all these
//                  callbacks will appear on the render thread. This thread
//                  will possibly conflict with events from the main thread.
//
// These callbacks will be called in this sequence for every frame.
// It should be obvious, that you don't do any system calls in these callbacks
// and finish ASAP. The CAAbsoluteTime is the time the render started it will
// be the same through all callbacks.
//
@property void   (*willRenderCallback)( UIWindow *window,
                                        struct CGFrameInfo *info);
@property void   (*willLayoutCallback)( UIWindow *window,
                                        struct CGFrameInfo *info);
@property void   (*didLayoutCallback)( UIWindow *window,
                                       struct CGFrameInfo *info);
@property void   (*didCreateRenderQueueCallback)( UIWindow *window,
                                       struct CGFrameInfo *info);

@property void   (*didAnimateCallback)( UIWindow *window,
                                        struct CGFrameInfo *info);
//
// useful to add custom drawing stuff on top. There is no willRenderCallback
// as anything draw in it would be clobbered by the window clearing itself
//
@property void   (*didRenderCallback)( UIWindow *window,
                                       struct CGFrameInfo *info);
@property void   (*didSwapCallback)( UIWindow *window,
                                     struct CGFrameInfo *info);


@property UIEvent  *(*eventCallback)( UIWindow *window, UIEvent *event);

@property( readonly, assign) UIWindowPlane   *alertPlane;
@property( readonly, assign) UIWindowPlane   *dragAndDropPlane;
@property( readonly, assign) UIWindowPlane   *menuPlane;
@property( readonly, assign) UIWindowPlane   *toolTipPlane;
@property( readonly, assign) UIWindowPlane   *contentPlane;

- (instancetype) initWithFrame:(CGRect) frame;
// default visible: closable, non-resizable, non-maximizable
- (instancetype) initWithFrame:(CGRect) frame
                  titleCString:(char *) title
                     styleMask:(NSUInteger) styleMask;

+ (instancetype) windowWithFrame:(CGRect) frame;

// does not deal with focus of events
//- (void) show;
//- (void) hide;

- (void) setNeedsDisplay;

+ (CGFloat) primaryMonitorPPI;

- (BOOL) isWindowThread;

- (void) runInApplication:(UIApplication *) application;

- (void) setFrameRateHz:(CGFloat) hz;
- (CGFloat) frameRateHz;

@end


@interface UIWindow( Dump)

- (void) dump;

@end

@interface UIWindow( OS)

+ (CGFloat) os_primaryMonitorPPI;

- (void) os_syncFrameWithWindow;
- (void *) os_createWindowWithFrame:(CGRect) frame
                       titleCString:(char *) title
                          styleMask:(NSUInteger) styleMask;
- (void) os_destroyWindow;

- (void) os_initEvents;
- (CGSize) os_windowSize;
- (CGSize) os_framebufferSize;
- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

// sets and locks the current openGL context
- (void) os_startRender;
- (void) os_endRender;

+ (void) os_setSwapInterval:(NSUInteger) value;
- (void) os_swapBuffers;

- (void) os_show;
- (void) os_hide;

+ (CGFloat) os_primaryMonitorRefreshRate;

@end


@interface UIWindow( OSWindowEvents)

- (void) _framebufferResizeCallback:(CGSize) size;
- (void) _windowResizeCallback:(CGSize) size;
- (void) _windowCloseCallback;
- (void) _windowRefreshCallback;
- (void) _windowMoveCallback:(CGPoint) position;

@end


@interface UIWindow( Render)

- (void) renderLoop;
- (BOOL) renderUpToNumberOfFrames:(NSUInteger) maxFrames;
- (void) renderFrame:(struct CGFrameInfo *) info;
- (BOOL) renderFrameWaitForNeedsDisplay;

- (void) addToDelegateViews:(UIView *) view;
- (void) removeFromDelegateViews:(UIView *) view;

- (void) requestClose;

- (void) getFrameInfo:(struct CGFrameInfo *) info;

- (CGContext *) context;

@end
