#define _GNU_SOURCE

#import "UIWindow+UIEvent.h"

#import "import-private.h"

#import "CGGeometry+CString.h"
#import "UIEvent.h"
#import "UIView+UIEvent.h"
#import "UIView+NSArray.h"
#import "UIView+CGGeometry.h"
#import "mulle-pointerarray+ObjC.h"
#include <time.h>
#include "mulle-quadtree.h"
#include "mulle-timespec.h"


//#define CALLBACK_DEBUG
//#define MOUSE_MOTION_CALLBACK_DEBUG
//#define MOUSE_BUTTON_CALLBACK_DEBUG
#define RESIZE_CALLBACK_DEBUG
#define ABORT_ON_EVENT_OVERFLOW


@implementation UIWindow( UIEvent)


//
// callbacks from window events (via GLFW). It is NOT known if the event coming
// in is a direct callback from the host OS or if it has been queued by glfw
// and released during "waitForEvents" or "pollEvents." (See glfw3 events dox)
//
// What is unknown is, if the executing thread of a callback is always the
// mainThread. It is assumed here, though.
//
- (void) _windowResizeCallback:(CGSize) size
{
   UIEvent   *event;

#if defined( CALLBACK_DEBUG) || defined( RESIZE_CALLBACK_DEBUG)
   fprintf( stderr, "%s %s w=%.1f h=%.1f\n",
                     __PRETTY_FUNCTION__,
                     [self cStringDescription],
                     size.width,
                     size.height);
#endif
   event = [[UIWindowResizeEvent alloc] initWithWindow:self
                                          mouseLocation:self->_mouseLocation
                                              modifiers:self->_modifiers
                                                   size:size];
   [self queueRetainedEvent:event];
}


- (void) _framebufferResizeCallback:(CGSize) size
{
   UIEvent   *event;

#if defined( CALLBACK_DEBUG) || defined( RESIZE_CALLBACK_DEBUG)
   fprintf( stderr, "%s %s w=%.1f h=%.1f\n",
                     __PRETTY_FUNCTION__,
                     [self cStringDescription],
                     size.width,
                     size.height);
#endif
   event = [[UIWindowFramebufferResizeEvent alloc] initWithWindow:self
                                                    mouseLocation:self->_mouseLocation
                                                        modifiers:self->_modifiers
                                                             size:size];
   [self queueRetainedEvent:event];

   // TODO: we should do this atomically
   //
   _framebufferSize = size;}


- (void) _windowCloseCallback
{
   UIEvent   *event;

#ifdef CALLBACK_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   event = [[UIWindowCloseEvent alloc] initWithWindow:self
                                        mouseLocation:self->_mouseLocation
                                            modifiers:self->_modifiers];
   [self queueRetainedEvent:event];
}


- (void) _windowRefreshCallback
{
   UIEvent   *event;

#ifdef CALLBACK_DEBUG || defined( RESIZE_CALLBACK_DEBUG)
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   event = [[UIWindowRefreshEvent alloc] initWithWindow:self
                                          mouseLocation:self->_mouseLocation
                                              modifiers:self->_modifiers];
   [self queueRetainedEvent:event];
}


- (void) _windowMoveCallback:(CGPoint) position
{
   UIEvent   *event;

#ifdef CALLBACK_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

//   fprintf( stderr, "%p moved: x=%d y=%d\n", self, xpos, ypos);

   event = [[UIWindowMoveEvent alloc] initWithWindow:self
                                       mouseLocation:self->_mouseLocation
                                           modifiers:self->_modifiers
                                              origin:position];
   [self queueRetainedEvent:event];
}


- (void) _keyCallback:(int) key
             scancode:(int) scancode
               action:(int) action
            modifiers:(int) mods
{
   UIEvent   *event;

#ifdef CALLBACK_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   self->_modifiers = mods;
   if( self->_discardEvents & UIEventTypePresses)
      return;

   event = [[[UIKeyboardEvent alloc] initWithWindow:self
                                      mouseLocation:self->_mouseLocation
                                          modifiers:mods
                                                key:key
                                           scanCode:scancode
                                             action:action] autorelease];
   if( self->_keyEventCallback)
      event = (*self->_keyEventCallback)( self, event);
   if( event)
      [self queueEvent:event];
}


- (void) _charCallback:(unsigned int) codepoint
{
   UIEvent    *event;

#ifdef CALLBACK_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   if( self->_discardEvents & UIEventTypeUnicode)
      return;

   event = [[UIUnicodeEvent alloc] initWithWindow:self
                                    mouseLocation:self->_mouseLocation
                                        modifiers:self->_modifiers
                                        character:codepoint];
   [self queueRetainedEvent:event];
}


- (void) _mouseButtonCallback:(int) button
                       action:(int) action
                    modifiers:(int) mods
{
   UIEvent    *event;
   uint64_t   bit;

#if defined( CALLBACK_DEBUG) || defined( MOUSE_BUTTON_CALLBACK_DEBUG)
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   bit = 1LL << button;
   self->_mouseButtonStates &= ~bit;
   if( action == GLFW_PRESS)
      self->_mouseButtonStates |= bit;
   self->_modifiers = mods;

   if( self->_discardEvents & UIEventTypeTouches)
      return;

   event = [[UIMouseButtonEvent alloc] initWithWindow:self
                                        mouseLocation:self->_mouseLocation
                                            modifiers:mods
                                               button:button
                                               action:action];
   [self queueRetainedEvent:event];

   // [self dump];
}


- (void) _mouseMotionCallback:(CGPoint) pos
{
   UIEvent    *event;
   CGRect     frame;

#if defined( CALLBACK_DEBUG) || defined( MOUSE_MOTION_CALLBACK_DEBUG)
   fprintf( stderr, "%s %s (%.1f, %.1f)\n", __PRETTY_FUNCTION__, [self cStringDescription], pos.x, pos.y);
#endif

   //
   // Observed behaviour on linux: Depending on mouse sensitivity, it may
   // become obvious that there is a rounding bug in the Linux mouse handling
   // where certain integer values are never returned. In my case this
   // turned out to be 200,200. So don't expect the mouse to provide all
   // possible integer coordinates for every pixel on the screen.
   //
   if( self->_discardEvents & UIEventTypeMotion)
      return;

   //
   // Coordinates are window relative! So for screen coordinates we'd need
   // to add the window frame.x/y.
   //
   // we get not events for the window title bar
   // TODO: we might need to scale the values for DPI or ?
	self->_mouseLocation.x = pos.x;
	self->_mouseLocation.y = pos.y;

   // TODO: wrap in autorelease pool ?
   //       + event don't leak if someone throws
   //       - latency
   event = [[UIMouseMotionEvent alloc] initWithWindow:self
                                        mouseLocation:self->_mouseLocation
                                            modifiers:self->_modifiers
                                         buttonStates:self->_mouseButtonStates];
   [self queueRetainedEvent:event];
}


- (void) _mouseScrollCallback:(CGPoint) offset
{
   UIEvent    *event;
   uint64_t   bit;
   CGPoint    scrollOffset;
   CGFloat    sensitivity;

#ifdef CALLBACK_DEBUG
   fprintf( stderr, "%s %s\n", __PRETTY_FUNCTION__, [self cStringDescription]);
#endif

   if( self->_discardEvents)
      return;

   sensitivity = [self scrollWheelSensitivity];
   if( sensitivity != 0.0)
   {
      offset.x *= sensitivity;
      offset.y *= sensitivity;
   }

   if( [self isScrollWheelNatural])
      scrollOffset = CGPointMake( offset.x, offset.y);
   else
      scrollOffset = CGPointMake( -offset.x, -offset.y);

   event = [[UIMouseScrollEvent alloc] initWithWindow:self
                                        mouseLocation:self->_mouseLocation
                                            modifiers:self->_modifiers
                                         scrollOffset:scrollOffset];
   [self queueRetainedEvent:event];
}


- (id) _firstResponder
{
   return( _firstResponder);
}


# pragma mark - tracking rects

- (void) addTrackingView:(UIView *) view
{
   assert( view);
   assert( [view isKindOfClass:[UIView class]]);
   assert( [view window] == self || ! [view window]);

   assert( _mulle_pointerarray_find( &_trackingViews, view) == mulle_not_found_e);
   [view retain];
   _mulle_pointerarray_add( &_trackingViews, view);
}


- (void) removeTrackingView:(UIView *) view
{
   assert( [view isKindOfClass:[UIView class]]);

   if( _mulle_pointerarray_find( &_trackingViews, view) != mulle_not_found_e)
   {
        abort();
      //mulle_pointerarray_remove( &_trackingViews, view);
      [view autorelease];
   }
}


- (void) addTrackingAreasOfView:(UIView *) view
{
   NSUInteger                 i;
   NSUInteger                 n;
   struct MulleTrackingArea   *area;
   CGRect                     rect;
   CGRect                     converted;

   assert( ! view || [view isKindOfClass:[UIView class]]);
   assert( [view window] == self || ! [view window]);

   // don't track hidden view ..
   if( [view mulleIsEffectivelyHidden])
      return;

   n = [view numberOfTrackingAreas];
   for( i = 0; i < n; i++)
   {
      area      = [view trackingAreaAtIndex:i];
      rect      = MulleTrackingAreaGetRect( area);
      converted = [self convertRect:rect
                           fromView:view];
      assert( _quadtree);
      mulle_quadtree_insert( _quadtree, converted, view);
   }
}


- (void) setupQuadtree
{
   CGRect                                rect;
   CGRect                                bounds;
   NSUInteger                            i;
   NSUInteger                            level;
   NSUInteger                            extent;
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;

   bounds = [self bounds];
   extent = round( bounds.size.width < bounds.size.height ? bounds.size.width : bounds.size.height);
   level  = 0;
   while( extent > 2)
   {
      level++;
      extent >>= 1;
   }

   //
   // 1. create quadtree only, when we get an event ?
   // 2. create quadtree for every frame ?
   // 3. create quadtree only when scene (views with tracking rects change ?)
   // 4. do not create quadtree when scrolling ?
   // 5. cache freed quadtree nodes in a mulle_pointerarray ?
   //
   if( ! _quadtree)
      _quadtree = mulle_quadtree_create( bounds, 10, 10, MulleObjCInstanceGetAllocator( self));
   else
      mulle_quadtree_reset( _quadtree, bounds);

   rover = mulle_pointerarray_enumerate( &_trackingViews);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      [self addTrackingAreasOfView:view];
   mulle_pointerarrayenumerator_done( &rover);
}


static void   collect_hit_views( CGRect rect, void *payload, void *userinfo)
{
   struct mulle_pointerarray   *array = userinfo;
   UIView                      *view = payload;

   _mulle_pointerarray_add( array, view);
}


- (UIEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
{
   CGRect                                rect;
   CGPoint                               point;
   struct mulle_pointerarray             views;
   struct mulle_pointerarray             remaining;
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   unsigned int                          n;
   BOOL                                  isDrag;

   _mulle_pointerarray_init( &views, 16, NULL);

   point = [event locationInWindow];

   //
   // this could be a dragging event though, which needs to be handled
   // without tracking areas (...). But we only handle these events if
   // a button is pressed. We don't send mouseMoved: then though (useful ?)
   //
   isDrag = [(UIMouseMotionEvent *) event buttonStates] != 0;
   n      = mulle_quadtree_find_point( _quadtree,
                                       point,
                                       collect_hit_views,
                                       &views);
   //
   // if we have no entered views and nothing is hit, then there is nothing
   // to do
   //
   if( n || mulle_pointerarray_get_count( &_enteredViews))
   {
      // first remove all views from enteredViews which are not in views
      // and send them a MouseExited event
      // send MouseMoved: events to all remaining enteredViews

      _mulle_pointerarray_init( &remaining, 16, _mulle_pointerarray_get_allocator( &_enteredViews));

      rover = mulle_pointerarray_enumerate( &_enteredViews);
       while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      {
         if( _mulle_pointerarray_find( &views, view) == mulle_not_found_e)
         {
            [view mouseExited:event];
         }
         else
         {
            // will be sent later by regular event handling code anyway
            if( ! isDrag)
               [view mouseMoved:event];
            _mulle_pointerarray_add( &remaining, view);
         }
      }
      mulle_pointerarrayenumerator_done( &rover);

      // remaining are now the remaining active enteredViews

      rover = mulle_pointerarray_enumerate( &views);
      while( _mulle_pointerarrayenumerator_next( &rover, (void **) &view))
      {
         if( _mulle_pointerarray_find( &remaining, view) == mulle_not_found_e)
         {
            [view mouseEntered:event];
            _mulle_pointerarray_add( &remaining, view);
         }
      }
      mulle_pointerarrayenumerator_done( &rover);

      // now move remaining to _enteredViews and switch to remaining
      mulle_pointerarray_done( &_enteredViews);
      memcpy( &_enteredViews, &remaining, sizeof( struct mulle_pointerarray));
   }
   mulle_pointerarray_done( &views);

   if( ! isDrag)
      return( nil);

   return( event);
}

/*
 * Window events
 */
- (UIEvent *) handleWindowEvent:(UIWindowEvent *) event
{
   CGRect  frame;

   switch( [event windowEventType])
   {
   case UIWindowEventTypeClose :
      _shouldClose = YES;
      return( nil);

   case UIWindowEventTypeMove :
      _frame.origin = [(UIWindowMoveEvent *) event origin];
      // delegate method ?
      return( nil);

   case UIWindowEventTypeFramebufferResize :
      // ignore size, polled during next redraw anyway
      // and we are getting a refresh anyway next
#ifdef RESIZE_CALLBACK_DEBUG
   fprintf( stderr, "%s %s handled UIWindowEventTypeFramebufferResize\n",
                     __PRETTY_FUNCTION__,
                     [self cStringDescription]);
#endif
      _resizing = YES;
      [self setNeedsDisplay];
      return( nil);

   case UIWindowEventTypeResize :
      _frame.size  = [(UIWindowResizeEvent *) event size];
      _resizing = YES;

      [self setNeedsLayout:YES];
      [self setNeedsDisplay];
#ifdef RESIZE_CALLBACK_DEBUG
   fprintf( stderr, "%s %s handled UIWindowEventTypeResize\n",
                     __PRETTY_FUNCTION__,
                     [self cStringDescription]);
#endif
      return( nil);

   // on linux we always get refresh event, so it's not necessary to
   // call this all the time for the other events (which could lead
   // to duplicate redraws)
   case UIWindowEventTypeRefresh :
      [self setNeedsDisplay];
      return( nil);
   }

   return( event);
}


- (UIEvent *) handleEvent:(UIEvent *) event
{
   CGRect                                rect;
   CGPoint                               point;
   struct mulle_pointerarray             views;
   struct mulle_pointerarray             remaining;
   struct mulle_pointerarrayenumerator   rover;
   UIView                                *view;
   unsigned int                          n;
   BOOL                                  isDrag;

   switch( [event eventType])
   {
   case UIEventTypePresses :
#ifdef DEBUG
      if( [event eventType] == UIEventTypePresses && [event action] == GLFW_PRESS)
      {
         UIKeyboardEvent   *keyEvent;

         keyEvent = (UIKeyboardEvent *) event;

         // F12 key: 301
         if( [keyEvent key] == 301)
         {
            [self dump];
            return( nil);
         }
         if( [keyEvent key] == 300)
         {
            [self dumpRenderQueue:&_renderQueue];
            return( nil);
         }
      }
#endif
      break;

   case UIEventTypeMotion :
      event = [self handleMouseMotionEvent:(UIMouseMotionEvent *) event];
      break;

   case UIEventTypeWindow :
      event = [self handleWindowEvent:(UIWindowEvent *) event];
      break;
   }


   if( ! event)
      return( event);

//   if( [event isKindOfClass:[UIMouseScrollEvent class]])
//      [self dump];
   return( [super handleEvent:event]);
}


/*
 * Event handling of the window. Events undergo the following cycle
 * ----- [main thread]
 * glfw ->
 *    UIWindow C callback ->
 *       UIEvent alloc/reuse ->
 *          UIWindow queueEvent: ->
 * ----- [window thread]
 *             UIWindow pollEvents ->
 *                UIWindow handleEvent: ->
 *                   UIEvent release ->
 *                       UIEvent reuse/dealloc
 * -----
 */

- (BOOL) willDiscardEvent:(UIEvent *) event
{
   return( YES);
}

- (BOOL) willDiscardOverflowEvent:(UIEvent *) event
{
   fprintf( stderr, "*** windows %p (%p) discards event due to queue overflow\n", self, self->_thread);
#ifdef ABORT_ON_EVENT_OVERFLOW
   abort();
#endif
   return( [self willDiscardEvent:event]);
}


- (BOOL) willDiscardPendingEvent:(UIEvent *) event
{
   return( [self willDiscardEvent:event]);
}


- (void) queueRetainedEvent:(UIEvent *) event
{
   assert( [NSThread mulleIsMainThread]);

   //
   // events that can not be queued will have to be discarded
   //
   if( ui_window_pointer_fifo_write( &_eventQueue, event))
   {
      if( [self willDiscardOverflowEvent:event]) // window can figure out something
      {                                          // for super important events
         [event autorelease];
      }
   }
}

- (void) queueEvent:(UIEvent *) event
{
   [self queueRetainedEvent:[event retain]];
}


//
// Discard events queue for the window. This has to be called by the window
// thread.
//
- (void) discardPendingEvents
{
   NSUInteger   old;

   assert( [self isWindowThread]);

   old = _discardEvents;
   _discardEvents = ~0;  // discard all
   {
      UIEvent   *event;

      @autoreleasepool
      {
         for(;;)
         {
            event = ui_window_pointer_fifo_read_barrier( &_eventQueue);
            if( ! event)
               break;

            if( [self willDiscardPendingEvent:event]) // window can figure out something
               [event autorelease];
         }
      }
   }
   _discardEvents = old;
}


//
// Execute all events in the queue until empty. This has to be called by the
// Windows thread
//
- (NSUInteger) pollEvents
{
   UIEvent   *event;
   BOOL      mask;

   assert( [self isWindowThread]);

   mask = 0;
   if( [NSThread mulleIsMainThread])
      [UIEvent os_pollEvents];

   for(;;)
   {
      event = ui_window_pointer_fifo_read_barrier( &_eventQueue);
      if( ! event)
         break;

      @autoreleasepool
      {
         // could time event time spent and then complain if it's too long
         [self handleEvent:event];
         mask |= [event eventType];
      }
      [event release];
   }
   return( mask);
}


// in terms of rendering, we are hopefully say in the middle of the frame
// the frame as rendered and now we do the events. We want to do also events
// coming in in the second half of the frame, but we do not want to busy wait
// nor do we want to sleep long, because of latency.
//
#ifdef ns
# undef ns
#endif
#ifdef us
# undef us
#endif

#define us( x)    (long) ((x) * 1000)
#define ms( x)    (long) (us(x) * 1000)


- (NSUInteger) waitForEvents:(CARelativeTime) timeout
                         now:(CAAbsoluteTime) now
                returnsEarly:(BOOL) returnsEarly
{
   struct timespec   delay;
   CAAbsoluteTime    now;
   CAAbsoluteTime    then;
   NSUInteger        mask;

   now  = CAAbsoluteTimeNow();
   then = now + timeout;
   mask = 0;

   for(;;)
   {
      mask |= [self pollEvents];
      if( mask && returnsEarly)
         break;

      // could also check here, if events took too much time
      if( CAAbsoluteTimeNow() >= then)
         break;

      delay.tv_sec  = 0;
      delay.tv_nsec = ms( 0.5);
      nanosleep( &delay, NULL);
   }
   return( mask);
}


- (NSUInteger) waitForEventsHz:(double) hz
{
   return( [self waitForEvents:hz > 0.0 ? 1.0/hz : 0.0
                           now:CAAbsoluteTimeNow()
                  returnsEarly:YES]);
}


- (NSUInteger) waitForEvents:(CARelativeTime) timeout
{
   return( [self waitForEvents:timeout
                           now:CAAbsoluteTimeNow()
                  returnsEarly:YES]);
}

@end

