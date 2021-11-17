#import "UIView.h"

#import "UIWindowStyle.h"

struct CGFrameInfo;

typedef UIView   UIWindowPlane;

@class UIPasteboard;
@class UIEvent;
@class UIApplication;
@class GLFWWindow;  // move to private some time



// values for frameRate
#define UIWindowFrameRateUnsynced   0.0        // as fast as possible
#define UIWindowFrameRateAsync      INFINITY   // wait until an event hits
#define UIWindowFrameRateSynced     -INFINITY  // tied to monitor frame rate (or 1/60.0 if not available)


#define ui_window_pointer_fifo   mulle__pointerfifo128

#define ui_window_pointer_fifo_init   _mulle__pointerfifo128_init
#define ui_window_pointer_fifo_done   _mulle__pointerfifo128_done
#define ui_window_pointer_fifo_write  _mulle__pointerfifo128_write
#define ui_window_pointer_fifo_read_barrier   _mulle__pointerfifo128_read_barrier


// mulle addition
@protocol UIWindowRenderDelegate

// none of these are optional, implement them all
// call before beginRender
- (void) windowWillBeginRender:(UIWindow *) window
                       context:(CGContext *) context;

// cabll before endRender
- (void) windowWillEndRender:(UIWindow *) window
                     context:(CGContext *) context;

// call after endRender
- (void) windowDidEndRender:(UIWindow *) window;

@end

// When the window manager (or whoever) sends a window refresh message
// the window has to act immediately and repaint. If the repaint is too
// slow there will be bad and ugly flicker.
//
// The strategies are
//   * render        - this is the default and best if fast enrough
//   * screenshot    - use a screenshot of previous frame scaled or fixed
//   * hidden render - use a separate window to render into a screenshot
//
enum UIWindowRefreshStrategy
{
   UIWindowRefreshStrategyRender                  = 0, // default
   UIWindowRefreshStrategyPresentScreenshot       = 1,
   UIWindowRefreshStrategyPresentScaledScreenshot = 2,
   UIWindowRefreshStrategyHiddenRender            = 3
};

//
// TODO: firstResponder needed for UITextField to gain keyboard
//       focus immediately
//
@interface UIWindow : UIView
{
   id                 _os_window;             // our GLFW Window
   id                 _os_offscreen_window;   // our drawing Window

   CGSize             _resizeSize;
   id                 _firstResponder;
   void               *_quadtree;

   struct mulle_pointerarray   _trackingViews;   // views with tracking areas
   struct mulle_pointerarray   _enteredViews;    // views with mouseEntered: sent
   struct mulle_pointerarray   _delegateViews;   // views with need willRender: sent

   CGRect             _originalRect;
   CGRect             _subdivideRect;
   CGRect             _dividedRects[ 4];
   NSUInteger         _nDividedRects;
   NSUInteger         _nTest;

   CAAnimator         *_preLayoutAnimator;
   CAAnimator         *_postLayoutAnimator;

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
   NSConditionLock             *_needsDisplayLock;
   BOOL                        _isResizing;
   CAAbsoluteTime              _lastResizeEventTimestamp;
   CAAbsoluteTime              _lastDidFramebufferSwapTimestamp;
   CAAbsoluteTime              _lastDidProcessEventsTimestamp;
   BOOL                        _shouldClose;
   BOOL                        _needsWindowRefresh;
   NSInteger                   _oldSwapInterval;
   struct mulle_pointerarray   _renderQueue; // layers to render
}

@property( retain) id                   userInfo;
// TODO: pasteboard is a global resource and is on Application ?
@property( retain) UIPasteboard         *pasteboard;
@property( assign) NSThread             *thread;

@property( assign, readonly) CGFloat    primaryMonitorPPI;
@property( assign, readonly) CGFloat    primaryMonitorRefreshRate;

@property( assign) CGFloat              eventFrequency;

@property( assign) CGColor              backgroundColor;

// as the framebufferSize via glfw calls can only be done on mainthread
// we keep a shadow, that gets updated by glfw window events
@property( assign, readonly) struct CGBitmapSize   framebufferSize;

// used for MulleUIPerformance
@property( assign) id <UIWindowRenderDelegate>   renderDelegate;

@property( assign) CGFloat                       frameRate;
@property( assign) NSUInteger                    swapInterval;

// default is UIWindowBackingStoreBuffered, this is more expensive. If your
// event/drawing code is very fast (within a frame), you can get by with
// UIWindowBackingStoreNonRetained
@property( assign) UIWindowBackingStoreType      backingStore;
@property( assign) enum UIWindowRefreshStrategy  refreshStrategy;

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
@property void   (*willLayoutCallback)( UIWindow *window,
                                        CGContext *context,
                                        struct CGFrameInfo *info);
@property void   (*didLayoutCallback)( UIWindow *window,
                                       CGContext *context,
                                       struct CGFrameInfo *info);
@property void   (*didCreateRenderQueueCallback)( UIWindow *window,
                                                  CGContext *context,
                                                  struct CGFrameInfo *info);

//
// stage #0: after _preLayoutAnimator
// stage #1: after _postLayoutAnimator
// stage #2: after CALayer "privat" animations
//
@property void   (*didAnimateCallback)( UIWindow *window,
                                        CGContext *context,
                                        struct CGFrameInfo *info,
                                        NSInteger stage);


//
// This is useful to add custom drawing stuff on the bottom.
//
@property void   (*willRenderCallback)( UIWindow *window,
                                        CGContext *context,
                                        struct CGFrameInfo *info);

//
// This is useful to add custom nanovg drawing stuff on top.
//
@property void   (*willEndRenderCallback)( UIWindow *window,
                                           CGContext *context,
                                           struct CGFrameInfo *info);
//
// This is useful to add custom Open GL drawing stuff on top of nanovg.
//
@property void   (*didRenderCallback)( UIWindow *window,
                                       CGContext *context,
                                       struct CGFrameInfo *info);

//
// At the time "willSwapCallback" is called, all nanovg drawing calls will
// have been flushed. And the graphics context is not usable anymore without
// another setup.
//
@property void   (*willSwapCallback)( UIWindow *window);
@property void   (*didSwapCallback)( UIWindow *window);


@property UIEvent  *(*eventCallback)( UIWindow *window, UIEvent *event);

// the resize plane is shown, when the window is resizing
// the other planes are then not shown

@property( readonly, assign) UIWindowPlane   *alertPlane;
@property( readonly, assign) UIWindowPlane   *dragAndDropPlane;
@property( readonly, assign) UIWindowPlane   *menuPlane;
@property( readonly, assign) UIWindowPlane   *toolTipPlane;
@property( readonly, assign) UIWindowPlane   *contentPlane;

+ (instancetype) windowWithFrame:(CGRect) frame;

+ (instancetype) windowWithFrame:(CGRect) frame
                 titleUTF8String:(char *) title
                       styleMask:(NSUInteger) styleMask;

// Convenience for quick hacks
// Window will be resizable if the view is resizable
// margins will be observed to create spacing around the view
// if any axis is < 32 in size, 32 will be used
//
+ (instancetype) windowWithView:(UIView *) view
                 titleUTF8String:(char *) title;

// even more convenient, even less configurable, for even more
// convenience checkout UIApplication+UIWindow
+ (instancetype) windowWithLayer:(CALayer *) layer
                 titleUTF8String:(char *) title;

- (instancetype) initWithGLFWWindow:(GLFWWindow *) window
                offscreenGLFWWindow:(GLFWWindow *) offscreenWindow;

- (instancetype) initWithFrame:(CGRect) frame;
// default visible: closable, non-resizable, non-maximizable
- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask;

// does not deal with focus of events
//- (void) show;
//- (void) hide;

- (void) setNeedsDisplay;

+ (CGFloat) primaryMonitorPPI;

- (BOOL) isWindowThread;
- (BOOL) isResizing;

- (void) runInApplication:(UIApplication *) application;

- (void) setFrameRateHz:(CGFloat) hz;
- (CGFloat) frameRateHz;
- (CGFloat) pixelRatio;

- (CAAnimator *) preLayoutAnimator;
- (CAAnimator *) postLayoutAnimator;

- (void) requestClose;

@end


@interface UIWindow( Dump)

- (void) dump;

@end

