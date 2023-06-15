#import "UIApplication.h"

#import "UIEvent.h"

#import "import-private.h"

#include <errno.h>

#define MAX_TIMERHOLES    8
//#define RUN_DEBUG

static uintptr_t   object_hash( struct mulle_container_keycallback *callback,
                               void * obj)
{
   return( (uintptr_t) [(id) obj hash]);
}


static int   object_is_equal( struct mulle_container_keycallback *callback,
                             void *obj,
                             void *other)
{
   return( [(id) obj isEqual:(id) other]);
}


static void   *object_retain( struct mulle_container_keycallback *callback,
                              void *obj,
                              struct mulle_allocator *allocator)
{
   return( [(id) obj retain]);
}


static void   object_autorelease( struct mulle_container_keycallback *callback,
                                  void *obj,
                                  struct mulle_allocator *allocator)
{
   [(id) obj autorelease];
}


static char   *object_describe( struct mulle_container_keycallback *callback,
                                void *obj,
                                struct mulle_allocator **p_allocator)
{
   *p_allocator = NULL;
   return( mulle_objc_object_call( (id) obj, @selector( UTF8String), (id) obj));
}


static const struct mulle_container_keycallback   key_retain_callback =
{
   object_hash,
   object_is_equal,
   object_retain,
   object_autorelease,
   object_describe,

   nil,
   NULL
};


struct UIApplicationTimer
{
   mulle_absolutetime_t   timestamp;
   NSTimer                *timer;
   id <UITimerReceiver>   receiver;
};


enum application_state
{
   Idle,
   CheckWindows,
   CloseWindows,
   DrawAndSwap,
   FireTimers,
   InvokeMethods,
   PollEvents,
   WindowPropertyChanges,
   ProcessEvents,
   Finished
};


@interface NSObject( Declare)

- (void) _setPrimary:(BOOL) flag;

@end


UIApplication   *UIApp;

@interface UIApplication( Declare)

// don't call these yourself
- (void) loadStandardCursors;
- (void) removeStandardCursors;
- (void) removeAllTimers;
- (void) removeAllWindows;
- (void) removeAllInvocations;

@end 


@implementation UIApplication

+ (void) initialize
{
   [super initialize];  // call singleton initialize ?
   if( [self respondsToSelector:@selector( os_initialize)])
      [self os_initialize];
}


+ (void) deinitialize
{
   if( [self respondsToSelector:@selector( os_deinitialize)])
      [self os_deinitialize];
}


#pragma clang diagnostic ignored "-Wobjc-method-access"
+ (instancetype) sharedInstance
{
   UIApp = [super sharedInstance];
   return( UIApp);
}


- (instancetype) init
{
   struct mulle_allocator   *allocator;


   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
   {
      MulleUILog( "Not all classes have been loaded by the runtime.\nUse MULLE_OBJC_TRACE_DEPENDENCY=YES for debugging.\n");
      abort();
   }

   assert( [NSThread mulleIsMainThread]);

   [self _initResourceStorage:&_resourceStorage];

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_array_init( &_screens,
                     2,
                     (struct mulle_container_keycallback *) &key_retain_callback,
                     allocator);
   _screensLock = [NSLock new];

   mulle_array_init( &_windows,
                     4,
                     (struct mulle_container_keycallback *) &key_retain_callback,
                     allocator);

   mulle_structarray_init( &_timers,
                           sizeof( struct UIApplicationTimer),
                           alignof( struct UIApplicationTimer),
                           0,
                           allocator);
   _timersLock = [NSLock new];

   _mulle_pointermultififo_init( &_invocationList, 128, allocator);

   _bouncerSignature = [[self methodSignatureForSelector:@selector( _synchronousInvoke:conditionLock:)] retain];

   if( [self respondsToSelector:@selector( os_init)])
      [self os_init];

   [self loadStandardCursors];

   return( self);
}


// assume all windows thread are quiescent now... else why call terminate :)


- (int) terminate
{
   assert( [NSThread mulleIsMainThread]);

   [self removeAllInvocations];
   [self removeAllTimers];
   [self removeAllWindows];

   if( [self respondsToSelector:@selector( os_finalize)])
      [self os_finalize];

   [self removeStandardCursors];

   return( _returnStatus);
}


- (void) finalize
{
   [self terminate];

   [self _finalizeResourceStorage:&_resourceStorage];

   if( UIApp == self)
      UIApp = nil;

   [super finalize];
}


- (void) dealloc
{
   assert( [NSThread mulleIsMainThread]);

   [self _doneResourceStorage:&_resourceStorage];

   [_bouncerSignature release];

   assert( _mulle_pointermultififo_get_count( &_invocationList) == 0);
   _mulle_pointermultififo_done( &_invocationList);

   [_timersLock release];
   mulle_structarray_done( &_timers);
   mulle_array_done( &_windows);

   [_screensLock release];
   mulle_array_done( &_screens);

   [super dealloc];
}


- (struct MulleUIResourceStorage *) _resourceStorage
{
   return( &_resourceStorage);
}

/*
 *
 */

- (void) _synchronousInvoke:(NSInvocation *) invocation
              conditionLock:(NSConditionLock *) lock
{
   [lock lockWhenCondition:0];  // this can not not work
   [invocation invoke];
   [invocation mulleRetainReturnValue];
   [lock unlockWithCondition:1]; // this will not block either
}


//
// if waitUntilDone is set to YES, you can get the return value
// from the invocation!!!
//
- (void) invokeOnMainThread:(NSInvocation *) invocation
              waitUntilDone:(BOOL) flag
{
   NSConditionLock   *lock;
   NSInvocation      *bouncer;

   if( ! flag)
   {
      [self invokeOnMainThread:invocation];
      return;
   }

   // a special case, if we are the main thread we would deadlock ourself
   if( [NSThread mulleIsMainThread])
   {
      [invocation invoke];
      return;
   }

   // we lock the condition lock and as long as its locked with condition
   // 0, the invocation is running... Need a new lock for every caller..
   // TODO: pool them
   lock = [[NSConditionLock alloc] initWithCondition:0];
   {
      // so we create a second invocation that will wrap the first one

      // TODO: can't we "just" call NSInvocationConstructor which would be an
      // empty root class with an unknown method and then NSInvocationConstructor
      // could figure everything out by itself and construct a NSInvocation by
      // itself ?
      //
      bouncer = [NSInvocation invocationWithMethodSignature:_bouncerSignature];

      [bouncer setTarget:self];
      [bouncer setSelector:@selector( _synchronousInvoke:conditionLock:)];
      [bouncer setArgument:&invocation
                  atIndex:2];
      [bouncer setArgument:&lock
                  atIndex:3];

      // we can't really catch exceptions with this though.. without extending
      // NSInvocation
      [self invokeOnMainThread:bouncer];
   }
   [lock lockWhenCondition:1];  // block until invocation is through

   // rare that we don't autorelease here, but
   // we can't get exceptions from the invocation anyway, and I want the
   // lock to be gone ASAP, because there could be OS limits...
   [lock release];
}


- (void) invokeOnMainThread:(NSInvocation *) invocation
{
   if( ! invocation)
      return;

   // TODO: use -mulleImmutableCopyArguments, which doesn't exist yet
   [invocation retainArguments];
   [invocation retain];

   for(;;)
   {
      if( ! _mulle_pointermultififo_write( &_invocationList, invocation))
         break;

      switch( errno)
      {
      case EAGAIN :  // just busy, we wait... this should happen really rarely
         mulle_thread_yield();
         break;

      default :
         abort();
      }
   }
}


- (void) runInvocations
{
   NSInvocation   *invocation;

   assert( [NSThread mulleIsMainThread]);

   // maybe name "extract"
   while( (invocation = _mulle_pointermultififo_read_barrier( &_invocationList)))
   {
      [invocation autorelease];
      [invocation invoke];
   }
}


- (void) removeAllInvocations
{
   NSInvocation   *invocation;

   assert( [NSThread mulleIsMainThread]);

   // maybe name "extract"
   while( (invocation = _mulle_pointermultififo_read_barrier( &_invocationList)))
   {
      [invocation autorelease];
   }
}



/*
 * UIScreen
 */
- (NSInteger) _indexOfScreen:(id <UIScreen>) screen
{
   uintptr_t   found;

   assert( [NSThread mulleIsMainThread]);

   found = mulle_array_find_in_range_identical( &_screens,
                                                screen,
                                                mulle_range_make_all());
   return( found == mulle_not_found_e ? NSNotFound : (NSInteger) found);
}


- (NSUInteger) numberOfScreens
{
   NSUInteger   count;

   [_screensLock lock];
   {
      count = mulle_array_get_count( &_screens);
   }
   [_screensLock unlock];

   return( count);
}


- (id <UIScreen>) screenAtIndex:(NSUInteger) i
{
   NSUInteger      n;
   id <UIScreen>   screen;

   screen = nil;
   [_screensLock lock];
   {
      n = mulle_array_get_count( &_screens);
      if( i < n)
      {
         screen = mulle_array_get( &_screens, i);
         screen = [[screen retain] autorelease];
      }
   }
   [_screensLock unlock];

   return( screen);
}


- (id <UIScreen>) primaryScreen
{
   return( [self screenAtIndex:0]);
}


- (void) _addScreen:(id <UIScreen>) screen
{
   assert( screen);
   assert( [NSThread mulleIsMainThread]);

   [_screensLock lock];
   {
      assert( [self _indexOfScreen:screen] == NSNotFound);
      mulle_array_add( &_screens, screen);
   }
   [_screensLock unlock];
}


- (void) _removeScreen:(id <UIScreen>) screen
{
   NSInteger   found;

   [_screensLock lock];
   {
      found = [self _indexOfScreen:screen];
      if( found != NSNotFound)
         mulle_array_remove_in_range( &_screens, mulle_range_make( found, 1));
   }
   [_screensLock unlock];
}


- (id <UIScreen>) screenForFrame:(CGRect) frame
            primaryIfNoneMatches:(BOOL) primaryIfNoneMatches
{
   id <UIScreen>   screen;
   id <UIScreen>   best;
   double          largestArea;
   double          area;
   CGRect          intersection;
   CGRect          canvas;
   NSUInteger      i, n;

   best        = nil;
   largestArea = 0.0;

   [_screensLock lock];
   {
      n = mulle_array_get_count( &_screens);
      for( i = 0; i < n; i++)
      {
         screen       = mulle_array_get( &_screens, i);
         canvas       = [screen canvas];
         intersection = CGRectIntersection( frame, canvas);
         area         = intersection.size.width * intersection.size.height;
         if( area > largestArea || (i == 0 && primaryIfNoneMatches))
         {
            largestArea = area;
            best        = screen;
         }
      }
      best = [[best retain] autorelease];
   }
   [_screensLock unlock];

   return( best);
}


- (NSUInteger) getScreens:(id <UIScreen> *) screens
                 maxCount:(NSUInteger) maxCount
        intersectingFrame:(CGRect) frame
{
   id <UIScreen>   screen;
   CGRect          canvas;
   NSUInteger      i, n;
   NSUInteger      count;

   assert( screens || ! maxCount);

   count = 0;
   [_screensLock lock];
   {
      n = mulle_array_get_count( &_screens);
      for( i = 0; i < n; i++)
      {
         screen = mulle_array_get( &_screens, i);
         canvas = [screen canvas];
         if( CGRectIntersectsRect( frame, canvas))
         {
            if( count < maxCount)
               screens[ count] = [[screen retain] autorelease];
            ++count;
         }
      }
   }
   [_screensLock unlock];

   return( count);
}


/*
 * UIWindow
 */
- (NSInteger) _indexOfWindow:(id <UIWindow>) window
{
   uintptr_t   found;

   assert( [NSThread mulleIsMainThread]);

   found = mulle_array_find_in_range_identical( &_windows,
                                                window,
                                                mulle_range_make_all());
   return( found == mulle_not_found_e ? NSNotFound : (NSInteger) found);
}


- (NSUInteger) numberOfWindows
{
   assert( [NSThread mulleIsMainThread]);

   return( mulle_array_get_count( &_windows));
}


- (NSUInteger) getWindows:(id <UIWindow> *) buf
                   length:(NSUInteger) length
{
   NSUInteger   n;

   assert( [NSThread mulleIsMainThread]);

   n = mulle_array_get_count( &_windows);
   if( length >= n)
      mulle_array_get_in_range( &_windows, mulle_range_make( 0, n), buf);
   return( n);
}


- (void) addWindow:(id <UIWindow>) window
{
   assert( window);
   assert( [self _indexOfWindow:window] == NSNotFound);
   assert( [NSThread mulleIsMainThread]);

   mulle_array_add( &_windows, window);
   [window applicationDidAddWindow:self];
}


- (void) removeWindow:(id <UIWindow>) window
{
   NSInteger   found;

   assert( _state != DrawAndSwap && "don't remove windows during a frame, "
                                    "instead use something like "
                                    "glfwSetWindowShouldClose");
   assert( [NSThread mulleIsMainThread]);

   found = [self _indexOfWindow:window];
   if( found == NSNotFound)
   {
      assert( 0);
      return;
   }

   mulle_array_remove_in_range( &_windows, mulle_range_make( found, 1));
   [window applicationDidRemoveWindow:self];
}


- (void) removeAllWindows
{
   id <UIWindow>        window;
   struct mulle_array   tmp;

   tmp = _windows;
   mulle_array_init( &_windows,
                     0,
                     tmp.callback,
                     tmp.allocator);

   mulle_array_for( &tmp, window)
   {
      [window applicationDidRemoveWindow:self];
   }

   mulle_array_done( &tmp);
}


- (void) _closeWindows
{
   id <UIWindow>        window;
   struct mulle_array   tmp;

   mulle_array_init( &tmp,
                     mulle_array_get_count( &_windows),
                     mulle_array_get_callback( &_windows),
                     NULL);
   mulle_array_add_array( &tmp, &_windows, mulle_range_make( 0, -1));

   mulle_array_for( &tmp, window)
   {
      if( [window shouldClose])
      {
#ifdef RUN_DEBUG
         MulleUILog( "remove Window %#@ and finalize", window);
#endif
         [self removeWindow:window];
      }
   }

   mulle_array_done( &tmp);
}


- (id <UIWindow>) windowForOSWindowHandle:(void *) os_window
{
   id <UIWindow>   window;

   assert( [NSThread mulleIsMainThread]);

   mulle_array_for( &_windows, window)
   {
      if( [window os_window] == os_window)
         break;
   }

   return( window);
}


//
//
//
- (UICursor *) cursorWithStandardShape:(UICursorStandardShape) shape
{
   assert( shape < n_UICursorStandardShapes);
   assert( ! shape || _standardCursors[ shape]);

   return( _standardCursors[ shape]);
}


- (void) loadStandardCursors
{
   NSUInteger   shape;

   assert( [NSThread mulleIsMainThread]);

   // convenient for tests
   if( ! [self respondsToSelector:@selector( os_createStandardCursor:)])
   {
      MulleUILog( "Cursor shapes not available, as \
-[UIApplication os_createStandardCursor:] is undefined");
      return;
   }

   for( shape = 1; shape < n_UICursorStandardShapes; shape++)
   {
      assert( ! _standardCursors[ shape]);
      _standardCursors[ shape] = [self os_createStandardCursor:shape];
   }
}


- (void) removeStandardCursors
{
   NSUInteger   shape;

   assert( [NSThread mulleIsMainThread]);

   for( shape = 1; shape < n_UICursorStandardShapes; shape++)
   {
      if( _standardCursors[ shape]) // can happen in tests
         [self os_destroyCursor:_standardCursors[ shape]];
      _standardCursors[ shape] = NULL;
   }
}


//
//
//

- (void) requestTerminate
{
   NSInvocation   *invocation;

   invocation = [NSInvocation mulleInvocationWithTarget:self
                                               selector:@selector( terminate)];
   [self invokeOnMainThread:invocation];
}


- (void) handleRetainedTimer:(NSTimer *) timer
{
   [timer autorelease];
   [timer fire];
}


- (void) removeTimerHoles
{
   struct mulle_structarrayenumerator   rover;
   struct UIApplicationTimer            *appTimer;
   struct mulle_structarray             tmp;
   NSUInteger                           n;

   [_timersLock lock];
   {
      if( _timerHoles)
      {
         n = mulle_structarray_get_count( &_timers);
         // old array in tmp, wipe _timers.

         tmp = _timers;
         mulle_structarray_init( &_timers,
                                 sizeof( struct UIApplicationTimer),
                                 alignof( struct UIApplicationTimer),
                                 n,
                                 mulle_structarray_get_allocator( &_timers));
         _timerHoles = 0;

         rover = mulle_structarray_enumerate( &tmp);
         while( mulle_structarrayenumerator_next( &rover, (void **) &appTimer))
            mulle_structarray_add( &_timers, appTimer);
         mulle_structarrayenumerator_done( &rover);

         // now remove tmp
         mulle_structarray_done( &tmp);
      }
   }
   [_timersLock unlock];
}



// if timer is nil, this will remove all timers of the receiver
// if receiver is nil, it will ignore receiver for check
- (void) removeTimer:(NSTimer *) timer
    forTimerReceiver:(id <UITimerReceiver>) receiver
{
   struct UIApplicationTimer   *appTimer;
   struct mulle_structarray    tmp;
   NSUInteger                  n;

   [_timersLock lock];
   {
      n = mulle_structarray_get_count( &_timers);
      if( n)
      {
         // old array in tmp, wipe _timers.
         tmp = _timers;
         mulle_structarray_init( &_timers,
                                 sizeof( struct UIApplicationTimer),
                                 alignof( struct UIApplicationTimer),
                                 n,
                                 mulle_structarray_get_allocator( &_timers));
         _timerHoles = 0;

         // move stuff over to _timers, that's not "timer"
         mulle_structarray_for( &tmp, appTimer)
         {
            if( (! timer || appTimer->timer == timer) &&
                (! receiver || appTimer->receiver == receiver))
            {
               [appTimer->timer  autorelease];
               continue;
            }
            mulle_structarray_add( &_timers, appTimer);
         }

         // now remove tmp
         mulle_structarray_done( &tmp);
      }
   }
   [_timersLock unlock];
}


// if receiver is nil, it will ignore receiver for check therefore removing
// all timers
- (void) removeAllTimersForTimerReceiver:(id <UITimerReceiver>) receiver
{
   [self removeTimer:nil
    forTimerReceiver:receiver];
}


- (void) removeAllTimers
{
   return( [self removeTimer:nil
            forTimerReceiver:nil]);
}


- (void) addTimer:(NSTimer *) timer
 forTimerReceiver:(id <UITimerReceiver>) receiver
{
   struct UIApplicationTimer   appTimer;

   assert( [timer isKindOfClass:[NSTimer class]]);
   assert( receiver);

   [_timersLock lock];
   {
      // when we have too many holes compact
      if( _timerHoles >= MAX_TIMERHOLES)
          [self removeTimerHoles];

      assert( [timer mulleIsRelativeTimer]);

      appTimer.timestamp = mulle_absolutetime_now() + [timer mulleRelativeTimeInterval];
      appTimer.timer     = [timer retain];
      appTimer.receiver  = receiver; // not retained!

      mulle_structarray_add( &_timers, &appTimer);
   }
   [_timersLock unlock];

#ifdef RUN_DEBUG
   MulleUILog( "add Timer %@ (%.3f)", timer, appTimer.timestamp);
#endif
}


- (void) resetTimer:(NSTimer *) timer
{
   struct UIApplicationTimer            appTimer;
   struct mulle_structarrayenumerator   rover;

   assert( [timer isKindOfClass:[NSTimer class]]);

   [_timersLock lock];
   {
      assert( [timer mulleIsRelativeTimer]);

      rover = mulle_structarray_enumerate( &_timers);
      while( mulle_structarrayenumerator_next( &rover, (void **) &appTimer))
      {
         if( appTimer.timer == timer)
         {
            appTimer.timestamp = mulle_absolutetime_now() + [timer mulleRelativeTimeInterval];
#ifdef RUN_DEBUG
            MulleUILog( "reset Timer %@ (%.3f)", timer, appTimer.timestamp);
#endif
            break;
         }
      }
      mulle_structarrayenumerator_done( &rover);
   }
   [_timersLock unlock];
}


//
// returns timeinterval until next timer wants to fire
//
- (mulle_relativetime_t) fireTimersIfNeeded:(mulle_absolutetime_t) now
{
   struct UIApplicationTimer   *appTimer;
   struct mulle_structarray    fireTimers;
   mulle_absolutetime_t        then;
   mulle_relativetime_t        min;
   mulle_relativetime_t        diff;
   mulle_relativetime_t        repeatInterval;
   NSTimer                     *timer;

   // if capacity is 0, nothing is malloced yet, which is good
   // because presumably most of the times there won't be timers at all
   //
   mulle_structarray_init( &fireTimers,
                           sizeof( struct UIApplicationTimer),
                           alignof( struct UIApplicationTimer),
                           0,
                           NULL);

   [_timersLock lock];
   {
      // because firing times may add or remove times, we first need to
      // collect all the timers in another array, then fire them

      min   = INFINITY;
      mulle_structarray_for( &_timers, appTimer)
      {
         timer = appTimer->timer;
         then  = appTimer->timestamp;
         diff  = then - now;

#ifdef RUN_DEBUG
         MulleUILog( "Timer %@ %.3f (%.3f)",timer, then, now);
#endif
         if( diff > 0.0) // time to fire
         {
            if( diff < min)
               min = diff;
            continue;
         }

         // add timer to fire list
         mulle_structarray_add( &fireTimers, appTimer);

         // check if we want to invalidate
         repeatInterval = [timer mulleRepeatTimeInterval];
         if( repeatInterval > 0.0)
         {
            // change to "then" + repeatInterval to avoid accumulating errors
            appTimer->timestamp = then + repeatInterval;

            diff = appTimer->timestamp - now;
            if( diff < min)
               min = diff;

            continue;
         }

         // get rid of timer
         [timer autorelease];

         // make this a hole, to be reclaimed sometime later
         appTimer->timer     = nil;
         appTimer->timestamp = INFINITY;
         _timerHoles++;
      }
   }
   [_timersLock unlock];

   //
   // fire all the timers that were accumulated, very often this will
   // be none...
   //
   mulle_structarray_for( &fireTimers, appTimer)
   {
#if defined( RUN_DEBUG)
       MulleUILog( "Fire Timer %@",timer);
#endif
      timer = [appTimer->timer retain];
      [appTimer->receiver handleRetainedTimer:timer];

      min = 0;  // event may have caused changes (like an event)
                // event processing should not wait
   }

   mulle_structarray_done( &fireTimers);

   // return the time until the next time needs to fire (from now)
   return( min);
}


//
// The frameRate of a window gives a "hint", when to call "draw" again. "draw"
// may be called earlier though, it's the windows task to check, if it wants
// to redraw. If it doesn't, it returns the amount of time it wants to wait
// for the next frame. The decoupling of "game" code that runs at fixed
// intervals, will be done with NSTimers, that sort of act like a window.
// We also put them into the loop, query them for when they want to run.
//
- (void) runLoop
{
   id <UIWindow>          window;
   BOOL                   closeWindows;
   mulle_absolutetime_t   now;
   mulle_absolutetime_t   previous;
   mulle_relativetime_t   timeout;
   mulle_relativetime_t   callAgainInSeconds;
   mulle_relativetime_t   nextWindowDisplayCallInSeconds;
   mulle_relativetime_t   nextTimerFireCallInSeconds;

   assert( _state == Idle || _state == Finished);
   assert( [NSThread mulleIsMainThread]);

   closeWindows = NO;

   for(;;)
   {
      @autoreleasepool
      {
         _state = CheckWindows;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> CheckWindows");
#endif
            closeWindows = NO;

            mulle_array_for( &_windows, window)
            {
               if( [window shouldClose])
               {
                  closeWindows = YES;
                  break;
               }
            }
         }

         // closing is relatively rare and a bit more expensive
         //  so I don't want to call _closeWindows all the time
         if( closeWindows)
         {
            _state = CloseWindows;
            {
#ifdef RUN_DEBUG
               MulleUILog( "-> CloseWindows");
#endif
               [self _closeWindows];
            }
         }

         if( ! mulle_array_get_count( &_windows))  // no windows left ?
            break;

         nextWindowDisplayCallInSeconds = INFINITY;
         previous                       = 0.0;
         now                            = mulle_absolutetime_now();

         _state = DrawAndSwap;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> DrawAndSwap");
#endif
            mulle_array_for( &_windows, window)
            {
#ifdef RUN_DEBUG
               MulleUILog( "calls %#@ to refresh", window);
#endif
               callAgainInSeconds = [window displayFrameIfNeeded:now];

               previous = now;
               now      = mulle_absolutetime_now();

               callAgainInSeconds -= now - previous;
               if( callAgainInSeconds < nextWindowDisplayCallInSeconds)
                  nextWindowDisplayCallInSeconds = callAgainInSeconds;
               else
               // principally we'd need to reduce the actualFastestFrameRate
               // by the drawing time spent
                  nextWindowDisplayCallInSeconds -= now - previous;
            }
         }

         _state = InvokeMethods;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> InvokeMethods");
#endif
            [self runInvocations];
         }

         _state = FireTimers;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> FireTimers");
#endif
            nextTimerFireCallInSeconds = [self fireTimersIfNeeded:now];
         }

         _state = WindowPropertyChanges;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> WindowPropertyChanges");
#endif
            mulle_array_for( &_windows, window)
            {
#ifdef RUN_DEBUG
               MulleUILog( "calls %#@ to push property changes", window);
#endif
               // TODO: pass App as parameter
               [window writeOSWindowPropertyChangesIfNeeded];
            }
         }

         _state = PollEvents;
         {
#ifdef RUN_DEBUG
            MulleUILog( "-> PollEvents");
#endif
            timeout = nextTimerFireCallInSeconds < nextWindowDisplayCallInSeconds
                        ? nextTimerFireCallInSeconds
                        : nextWindowDisplayCallInSeconds;
            if( timeout < 0.0)
               timeout = 0.0;

#if defined( RUN_DEBUG)
            MulleUILog( "next loop scheduled: %.17f", timeout);
#endif
            [UIEvent os_waitEventsWithTimeout:timeout];
         }

//         _state = ProcessEvents;
//         {
//            mulle_fprintf( stderr, "%#@: %#@ -> ProcessEvents\n", [NSThread currentThread], self);
//
//            rover = mulle_array_enumerate( &_windows);
//            while( _mulle_arrayenumerator_next( &rover, (void **) &window))
//            {
//               // just process events ASAP for each window,
//               // these are the unretained windows though, which don't have
//               // their own thread
//               [window executeEventQueue];
//            }
//            mulle_arrayenumerator_done( &rover);
//         }
      }
   }

   _state = Finished;
}


- (int) run
{
   [self runLoop];
   return( [self terminate]);
}


- (int) runWindow:(id <UIWindow>) window
{
   [self addWindow:window];
   // keep stack frame a bit smaller by not calling run
   [self runLoop];
   return( [self terminate]);
}


int  UIApplicationRunWindow( id <UIWindow> window)
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];

   [app addWindow:window];
   // keep stack frame a bit smaller by not calling runWindow
   [app runLoop];
   return( [app terminate]);
}


int   UIApplicationMain( int argc, char **argv, Class appClass, id delegate)
{
   UIApplication   *app;

   assert( [NSThread mulleIsMainThread]);

   appClass = appClass ? appClass : [UIApplication class];

   app = [appClass sharedInstance];
   [app setDelegate:delegate];
   return( [app run]);
}

@end
