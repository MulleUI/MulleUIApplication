#define _GNU_SOURCE

#import "UIWindow.h"

#import "UIWindow+UIEvent.h"

#import "import-private.h"

#import "UIApplication.h"
#import "UIEvent.h"
#import "UIView+CGGeometry.h"
#import "UIView+UIEvent.h"
#import "UIView+Layout.h"
#import "mulle-pointerarray+ObjC.h"


@implementation UIWindow

MULLE_OBJC_DEPENDS_ON_CLASS( UIApplication);

+ (void) initialize
{
   [UIApplication os_initialize];
}


+ (CGFloat) primaryMonitorPPI
{
   return( [self os_primaryMonitorPPI]);
}


- (void) requestClose
{
   [self os_requestClose];
}


- (void) syncFrameWithWindow
{
   [self os_syncFrameWithWindow];
}

//
// When we a create a window on Linux, the first one usually stays where
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

   _primaryMonitorPPI = [UIWindow primaryMonitorPPI];
   if( _primaryMonitorPPI == 0.0)
   {
      // no monitor connected, so lets just bail
      [self release];
      return( nil);
   }
   _primaryMonitorRefreshRate = [UIWindow os_primaryMonitorRefreshRate];

   _window = [self os_createWindowWithFrame:frame
                               titleCString:title
                                  styleMask:styleMask];
   if( ! _window)
   {
      [self release];
      return( nil);
   }

   [super initWithFrame:frame];

   // assume window has a title bar for contentRect calculation
   // (No difference to frame for me here on Linux)
   [self syncFrameWithWindow];
   assert( frame.size.height == _frame.size.height);
   assert( frame.size.width == _frame.size.width);

   _mouseLocation = CGPointMake( -1.0, -1.0);

   // initialize various plane for the future, currently only
   // _contentPlane can be used
   frame.origin = CGPointZero;

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

   _renderContextLock = [NSLock new];

   // rename to bind context to thread ?
   [self os_startRender];
   _context = [[CGContext alloc] initWithEdgeAntialiasing:!(styleMask & MulleWindowStyleMaskNoEdgeAntialias)
                                        useStencilStrokes:!(styleMask & MulleWindowStyleMaskNoStencilStrokes)];

   _framebufferSize = [self os_framebufferSize];
   [self os_endRender];

   _scrollWheelSensitivity = 20.0;
   _eventFrequency         = 60.0;

   // initially dirty with renderer 1, renderer go!
   _needsDisplayLock = [[NSConditionLock alloc] initWithCondition:1];
   [self setNeedsLayout:YES];

   ui_window_pointer_fifo_init( &_eventQueue);
   [self os_initEvents];

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   return( [self initWithFrame:frame
                  titleCString:"Demo"
                     styleMask:0]);
}


+ (instancetype) windowWithFrame:(CGRect) frame;
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


- (void) finalize
{
   [self discardPendingEvents];

   if( _context)
   {
      // get rid of textures possibly or so
      [self os_startRender];
      [_context mullePerformFinalize];
      [self os_endRender];
   }

   // TODO: delete window ?
   //       remove from screen ?
   if( _window)
      [self os_destroyWindow];

   _firstResponder = nil;
   [super finalize];
}


- (void) dealloc
{
   mulle_pointerarray_release_all( &_trackingViews);
   mulle_pointerarray_done( &_trackingViews);
   mulle_pointerarray_release_all( &_enteredViews);
   mulle_pointerarray_done( &_enteredViews);
   mulle_pointerarray_done( &_delegateViews);
   mulle_pointerarray_done( &_renderQueue);

   mulle_quadtree_destroy( _quadtree);

   [_context release];
   [_renderContextLock release];
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


- (CGColorRef) backgroundColor
{
   return( [_context backgroundColor]);
}

- (void) setBackgroundColor:(CGColorRef) color
{
   return( [_context setBackgroundColor:color]);
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


@end

