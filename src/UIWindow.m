#define _GNU_SOURCE

#import "UIWindow.h"

#import "UIWindow+UIEvent.h"
#import "UIWindow+Render.h"

#import "import-private.h"

#import "UIApplication.h"
#import "UIEvent.h"
#import "UIView+CGGeometry.h"
#import "UIView+UIEvent.h"
#import "UIView+Layout.h"
#import "GLFWWindow.h"
#import "GLFWWindow+UIEvent.h"
#import "mulle-pointerarray+ObjC.h"

@interface UIWindow( GLFWWindowEventReceiver) <GLFWWindowEventReceiver>
@end 


@implementation UIWindow

MULLE_OBJC_DEPENDS_ON_CLASS( UIApplication);

+ (void) initialize
{
   [UIApplication os_initialize];
}


+ (CGFloat) primaryMonitorPPI
{
   return( [GLFWWindow os_primaryMonitorPPI]);
}


- (void) requestClose
{
   [_os_window os_requestClose];
}


- (void) syncFrameWithWindow
{
   _frame = [_os_window os_windowFrame];
}

//
// When we create a window on Linux, the first one usually stays where
// it's at, and doesn't get a refresh or move notice. But a window manager
// may reposititon the subsequent window (or even the first), so we get
// a move and refresh event. The refresh event will hit after the first
// render forcing a second render sortof immediately, as the eventloop is
// positioned byhind the renderloop.
//
- (instancetype) initWithFrame:(CGRect) frame
                  titleCString:(char *) title
                     styleMask:(NSUInteger) styleMask
{
   assert( [NSThread mulleIsMainThread]);

   _primaryMonitorPPI = [GLFWWindow os_primaryMonitorPPI];
   if( _primaryMonitorPPI == 0.0)
   {
      // no monitor connected, so lets just bail
      [self release];
      return( nil);
   }

   // not super sure that this makes sense to cache
   _primaryMonitorRefreshRate = [GLFWWindow os_primaryMonitorRefreshRate];

   _os_window = [[GLFWWindow alloc] initWithFrame:frame
                                     titleCString:title
                                        styleMask:styleMask];
   if( ! _os_window)
   {
      [self release];
      return( nil);
   }

   // buffered with offscreen window is the default, 
   if( ! (styleMask & UIWindowStyleRenderNonRetainedOnly))
   {
      _os_offscreen_window = [[GLFWWindow alloc] initWithFrame:frame
                                                  titleCString:"OffScreen"
                                                     styleMask:styleMask|UIWindowStyleInvisible];
      if( ! _os_offscreen_window)
      {
         [self release];
         return( nil);
      }
   }
   else
      _backingStore = UIWindowBackingStoreNonRetained;

   [super initWithFrame:frame];

   // assume window has a title bar for contentRect calculation
   // (No difference to frame for me here on Linux)
   [self syncFrameWithWindow];
   assert( frame.size.height == _frame.size.height);
   assert( frame.size.width == _frame.size.width);

   // initialize various plane for the future, currently only
   // _contentPlane can be used
   frame.origin     = CGPointZero;
   _framebufferSize = [_os_window os_framebufferSize];

   // its kinda pointless to inherit clipRects down for views, that are full
   // window size
   _clipsToBounds = NO;

   _contentPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_contentPlane setDebugNameCString:"Window/ContentPlane"];
   [_contentPlane setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_contentPlane setClipsToBounds:NO];
   [self addSubview:_contentPlane];

   _toolTipPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_toolTipPlane setDebugNameCString:"Window/ToolTipPlane"];
   [_toolTipPlane setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_toolTipPlane setClipsToBounds:NO];
   [self addSubview:_toolTipPlane];
   [_toolTipPlane setHidden:YES];

   _menuPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_menuPlane setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_menuPlane setDebugNameCString:"Window/MenuPlane"];
   [_menuPlane setClipsToBounds:NO];
   [self addSubview:_menuPlane];
   [_menuPlane setHidden:YES];

   _dragAndDropPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_dragAndDropPlane setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_dragAndDropPlane setDebugNameCString:"Window/DragAndDropPlane"];
   [_dragAndDropPlane setClipsToBounds:NO];
   [self addSubview:_dragAndDropPlane];
   [_dragAndDropPlane setHidden:YES];

   _alertPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_alertPlane setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
   [_alertPlane setDebugNameCString:"Window/AlertPlane"];
   [_alertPlane setClipsToBounds:NO];
   [_alertPlane setHidden:YES];
   [self addSubview:_alertPlane];

   _mulle_pointerarray_init( &_renderQueue, 128, MulleObjCInstanceGetAllocator( self));
   _mulle_pointerarray_init( &_delegateViews, 8, MulleObjCInstanceGetAllocator( self));

   _eventFrequency         = 60.0;
   _oldSwapInterval        = NSIntegerMax;

   // initially dirty with renderer 1, renderer go!
   _needsDisplayLock = [[NSConditionLock alloc] initWithCondition:1];
   [self setNeedsLayout:YES];

   ui_window_pointer_fifo_init( &_eventQueue);

   // don't initialize offscreen window for events
   [_os_window os_initEvents];
   [_os_window setWindowEventsReceiver:self];
   [_os_window setEventsReceiver:self];

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   return( [self initWithFrame:frame
                  titleCString:"Demo"
                     styleMask:UIWindowStyleResizable]);
}


+ (instancetype) windowWithFrame:(CGRect) frame;
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


- (void) finalize
{
   CGContext   *context;

   [self discardPendingEvents];

   // get rid of textures possibly or so
   context = [self activateRenderContext];
   [context mullePerformFinalize];
   [self deactivateRenderContext:context];

   context = [self activateWindowContext];
   [context mullePerformFinalize];
   [self deactivateWindowContext:context];

   // TODO: delete window ?
   //       remove from screen ?
   [_os_offscreen_window finalize];
   [_os_window finalize];

   _firstResponder = nil;
   [super finalize];
}


- (void) dealloc
{
   [_postLayoutAnimator release];
   [_preLayoutAnimator release];
   [_os_offscreen_window release];
   [_os_window release];

   mulle_pointerarray_release_all( &_trackingViews);
   mulle_pointerarray_done( &_trackingViews);
   mulle_pointerarray_release_all( &_enteredViews);
   mulle_pointerarray_done( &_enteredViews);
   mulle_pointerarray_done( &_delegateViews);
   mulle_pointerarray_done( &_renderQueue);

   mulle_quadtree_destroy( _quadtree);

   [_needsDisplayLock release];

   ui_window_pointer_fifo_done( &_eventQueue);

   // TODO: delete window ?
   [super dealloc];
}


- (void) setFrameRateHz:(CGFloat) hz
{
   assert( hz > 0.0);
   if( hz != 0.0)
      _frameRate = 1.0f / hz;
}


- (CGFloat) frameRateHz
{
   if( _frameRate == INFINITY ||
       _frameRate <= 0.0f)
      return( 0.0f);
   return( 1.0f / _frameRate);
}


- (CGFloat) pixelRatio
{
   if( ! _framebufferSize.width)
      return( 1.0);
   if( _frame.size.width == 0.0)
      return( 1.0);

   return( _frame.size.width / _framebufferSize.width);
}


- (void) setBackingStore:(NSUInteger) backingStore
{
   if( _os_offscreen_window)
   {
      _backingStore = backingStore;
      return;
   }
#if DEBUG
   if( backingStore != UIWindowBackingStoreNonRetained)
       fprintf( stderr, "Window is not configured with an offscreen. "
"Only UIWindowBackingStoreNonRetained is possible\n");
#endif  
   _backingStore = UIWindowBackingStoreNonRetained;
}

- (void) runInApplication:(UIApplication *) application
{
   // should be public ?
   [self setThread:[NSThread currentThread]];
   [self renderLoop];

   // when window closes we are here
   // should tell application that we are done, but do a finalize first
   [self mullePerformFinalize];
}


- (void) setNeedsDisplay
{
   //
   // Will not wait for the renderer to finish, if not already set.
   //
   // Problem: may "swallow" some of the changes, if the view hierarchy is
   // not properly locked... (But it should be)
   //
   if( [_needsDisplayLock tryLockWhenCondition:0])
      [_needsDisplayLock unlockWithCondition:1];
}


- (BOOL) needsDisplay
{
   //
   // if we can tryLock with 1, its dirty. unlock keeping the dirty state
   //
   if( [_needsDisplayLock tryLockWhenCondition:1])
   {
      [_needsDisplayLock unlockWithCondition:1];
      return( YES);
   }
   return( NO);
}


- (BOOL) isWindowThread
{
   if( ! _thread)
      return( [NSThread mulleIsMainThread]);
   return( [NSThread currentThread] == _thread);
}

//
// lets write a novel here:
// the problem with resizing is that on resize we need to provide content
// with in 1/60s
// Unfortunately, during resize for whatever reason most of the CPU time
// is already taken up by the window manager ? Or the event comes in the
// middle of our frame ?
// If we get isResizing, we should immediately abort, and provide a cheap
// facade for resizing. The best facade would be a resizable screenshot of
// out window.
//
// Problems: glReadPixels maybe too late (window manager already corrupted
//           framebuffer ?)
//           glReadPixels maybe too slow ?
//
// Window should re-layout because of size change. Solution: Window renders
// into a separate framebuffer. Problem: same thread, where we want to draw
// our screenshot.
// Solution: Windows creates a hidden window
// that renders with a separate thread. Problem (getting framebuffer to
// other window)
//
- (BOOL) isResizing
{
   return( _isResizing);
}

/*
 * petty accessors
 */

- (void) setAlpha:(CGFloat) value
{
   assert( 0 && "don't set alpha on window");
}


- (CGFloat) alpha
{
   return( 1.0);
}


- (CGAffineTransform) transformForRenderQueue:(CGAffineTransform) inherited
{
   return( CGAffineTransformMakeIdentity());
}


- (void) setFrame:(CGRect) frame
{
   if( CGRectEqualToRect( _frame, frame))
      return;

   _frame = frame;
}


- (CGRect) frame
{
   return( _frame);
}


- (CGRect) bounds
{
   return( CGRectMake( 0.0, 0.0, _frame.size.width, _frame.size.height));
}


- (void) addLayer:(CALayer *) layer
{
   abort();
}


- (void) addToDelegateViews:(UIView *) view
{
   assert( _mulle_pointerarray_find( &_delegateViews, view) == mulle_not_found_e);

   _mulle_pointerarray_add( &_delegateViews, view);
}


- (void) removeFromDelegateViews:(UIView *) view
{
   extern void   mulle_pointerarray_remove( struct mulle_pointerarray *, void *);

   // defined in UIView
   mulle_pointerarray_remove( &_delegateViews, view);
}


- (CAAnimator *) preLayoutAnimator
{
   if( ! _preLayoutAnimator)
      _preLayoutAnimator = [CAAnimator new];
   return( _preLayoutAnimator);
}


- (CAAnimator *) postLayoutAnimator
{
   if( ! _postLayoutAnimator)
      _postLayoutAnimator = [CAAnimator new];
   return( _postLayoutAnimator);
}


@end

