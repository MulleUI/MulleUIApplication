#define _GNU_SOURCE

#import "UIWindow.h"

#import "UIWindow+UIEvent.h"

#import "import-private.h"

#import "CAAnimation.h"
#import "CALayer.h"  // for color
#import "CALayer+CAAnimation.h"  // for color
#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "UIApplication.h"
#import "UIEvent.h"
#import "UIView+CGGeometry.h"
#import "UIView+NSArray.h"
#import "UIView+UIEvent.h"
#import "UIView+Layout.h"
#import "UIView+Yoga.h"
#import "mulle-pointerarray+ObjC.h"
#include <time.h>
#include "mulle-quadtree.h"
#include "mulle-timespec.h"

#import "CALayer.h"  // debugging tmp


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
- (id) initWithFrame:(CGRect) frame
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

   // assume window has a title bar for contentRect calculation
   // (No difference to frame for me here on Linux)
   [self syncFrameWithWindow];
   assert( frame.size.height == _frame.size.height);
   assert( frame.size.width == _frame.size.width);

   _mouseLocation = CGPointMake( -1.0, -1.0);

   // initialize various plane for the future, currently only
   // _contentPlane can be used
   frame.origin = CGPointZero;

   _contentPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_contentPlane setDebugNameCString:"Window/ContentPlane"];
   [self addSubview:_contentPlane];

   _toolTipPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_toolTipPlane setDebugNameCString:"Window/ToolTipPlane"];
   [self addSubview:_toolTipPlane];
   [_toolTipPlane setHidden:YES];

   _menuPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_menuPlane setDebugNameCString:"Window/MenuPlane"];
   [self addSubview:_menuPlane];
   [_menuPlane setHidden:YES];

   _dragAndDropPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_dragAndDropPlane setDebugNameCString:"Window/DragAndDropPlane"];
   [self addSubview:_dragAndDropPlane];
   [_dragAndDropPlane setHidden:YES];

   _alertPlane = [[[UIView alloc] initWithFrame:frame] autorelease];
   [_alertPlane setDebugNameCString:"Window/AlertPlane"];
   [_alertPlane setHidden:YES];
   [self addSubview:_alertPlane];

   _windowSize      = [self os_windowSize];
   _framebufferSize = [self os_framebufferSize];

   _renderContextLock = [NSLock new];

   _scrollWheelSensitivity = 20.0;

   // initially dirty with renderer 1, renderer go!
   _needsDisplayLock = [[NSConditionLock alloc] initWithCondition:1];
   [self setNeedsLayout:YES];

   _mulle__pointerfifo4_init( &_eventQueue);
   [self os_initEvents];

   return( self);
}


- (id) initWithFrame:(CGRect) frame
{
   return( [self initWithFrame:frame
                  titleCString:"Demo"
                     styleMask:0]);
}


- (void) finalize
{
   [self discardPendingEvents];

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

   mulle_quadtree_destroy( _quadtree);

   [_renderContextLock release];

   _mulle__pointerfifo4_done( &_eventQueue);

   // TODO: delete window ?
   [super dealloc];
}


- (void) runInApplication:(UIApplication *) application 
{
   CGContext   *context;

   context = [self createContext];
   // should be public ?
   [self setThread:[NSThread currentThread]];
   [self renderLoopWithContext:context];

   // when window closes we are here
   // should tell application that we are done, but do a finalize first
   [context mullePerformFinalize];
   [self mullePerformFinalize];
}


- (void) setNeedsDisplay
{
   //
   // will not wait for the renderer to finish, if not already set
   // problem: may "swallow" some of the changes if the view hierarchy is
   // not properly locked... (But it should be)
   //
   if( [_needsDisplayLock tryLockWhenCondition:0])
      [_needsDisplayLock unlockWithCondition:1];
}


- (BOOL) needsDisplay
{
   //
   // if we can tryLock with 1, its dirty unlock keeping the dirty state
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



- (void) layoutSubviews
{
   CGRect     frame;

   assert( [_contentPlane layer]);

   frame.origin = CGPointZero;
   frame.size   = _frame.size;

   [_contentPlane setFrame:frame];
   [_menuPlane setFrame:frame];
   [_dragAndDropPlane setFrame:frame];
   [_toolTipPlane setFrame:frame];
   [_alertPlane setFrame:frame];

   // don't use setNeedsLayout as we are inside a layout already
   [_contentPlane setNeedsLayout:YES];
   [_menuPlane setNeedsLayout:YES];
   [_dragAndDropPlane setNeedsLayout:YES];
   [_toolTipPlane setNeedsLayout:YES];
   [_alertPlane setNeedsLayout:YES];
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



@end

