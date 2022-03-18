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
};


@implementation UIApplication

+ (void) initialize
{
   [super initialize];  // call singleton initialize ?
   [UIApplication os_initialize];
}


- (id) init
{
   struct mulle_allocator   *allocator;

   assert( [NSThread mulleIsMainThread]);

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_array_init( &_windows,
                     4,
                     (struct mulle_container_keycallback *) &key_retain_callback,
                     allocator);

   mulle_structarray_init( &_timers,
                           sizeof( struct UIApplicationTimer),
                           alignof( struct UIApplicationTimer),
                           0,
                           allocator);

   _mulle_pointermultififo_init( &_invocationList, 128, allocator);

   _bouncerSignature = [[self methodSignatureForSelector:@selector( _synchronousInvoke:conditionLock:)] retain];

   return( self);
}


- (void) dealloc
{
   assert( [NSThread mulleIsMainThread]);

   [_bouncerSignature release];

   assert( _mulle_pointermultififo_get_count( &_invocationList) == 0);
   _mulle_pointermultififo_done( &_invocationList);
   mulle_structarray_done( &_timers);
   mulle_array_done( &_windows);

   [super dealloc];
}


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
   NSConditionLock     *lock;
   NSInvocation        *bouncer;
   NSMethodSignature   *signature;

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


- (void) addWindow:(id <UIWindow>) window
{
   assert( window);
   assert( [self _indexOfWindow:window] == NSNotFound);
   assert( [NSThread mulleIsMainThread]);

   mulle_array_add( &_windows, window);
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
}


// assume all windows thread are quiescent now... else why call terminate :)
- (int) terminate
{
   struct mulle_arrayenumerator   rover;
   id <UIWindow>                  window;

   [self removeAllTimers];

   // ensure all windows are not calling glfw/opengl anymore
   rover = mulle_array_enumerate( &_windows);
   while( _mulle_arrayenumerator_next( &rover, (void **) &window))
      [window mullePerformFinalize];
   mulle_arrayenumerator_done( &rover);

   mulle_array_reset( &_windows);

   // this shuts down glfw, it doesn't exit
   [[self class] os_terminate];
   return( _returnValue);
}


- (void) _closeWindows
{
   struct mulle_arrayenumerator   rover;
   id <UIWindow>                  window;
   struct mulle_array             tmp;

   mulle_array_init( &tmp,
                     mulle_array_get_count( &_windows),
                     mulle_array_get_callback( &_windows),
                     NULL);
   mulle_array_add_array( &tmp, &_windows, mulle_range_make( 0, -1));

   rover = mulle_array_enumerate( &tmp);
   while( _mulle_arrayenumerator_next( &rover, (void **) &window))
   {
      if( [window shouldClose])
      {
#ifdef RUN_DEBUG
         mulle_fprintf( stderr, "%#@: %#@ remove Window %@ and finalize\n",
                         [NSThread currentThread], self, window);
#endif
         [self removeWindow:window];
         [window mullePerformFinalize];  // remove from screen
      }
   }
   mulle_arrayenumerator_done( &rover);

   mulle_array_done( &tmp);
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


// if timer is nil, this will remove holes in the array
- (void) removeAllTimers
{
   struct mulle_structarrayenumerator   rover;
   struct UIApplicationTimer            *appTimer;

   // move stuff over to _timers, that's not "timer"
   rover = mulle_structarray_enumerate( &_timers);
   while( mulle_structarrayenumerator_next( &rover, (void **) &appTimer))
      [appTimer->timer autorelease];
   mulle_structarrayenumerator_done( &rover);

   mulle_structarray_reset( &_timers);
   _timerHoles = 0;
}


// if timer is nil, this will remove holes in the array
- (void) removeTimer:(NSTimer *) timer
{
   struct mulle_structarrayenumerator   rover;
   struct UIApplicationTimer            *appTimer;
   struct mulle_structarray             tmp;
   NSUInteger                           n;

   n = mulle_structarray_get_count( &_timers);
   if( ! n)
      return;

   // old array in tmp, wipe _timers.
   tmp         = _timers;
   mulle_structarray_init( &_timers,
                           sizeof( struct UIApplicationTimer),
                           alignof( struct UIApplicationTimer),
                           n,
                           mulle_structarray_get_allocator( &_timers));
   _timerHoles = 0;

   // move stuff over to _timers, that's not "timer"
   rover = mulle_structarray_enumerate( &tmp);
   while( mulle_structarrayenumerator_next( &rover, (void **) &appTimer))
   {
      if( appTimer->timer == timer)
      {
         [timer autorelease];
         continue;
      }
      mulle_structarray_add( &_timers, appTimer);
   }
   mulle_structarrayenumerator_done( &rover);

   // now remove tmp
   mulle_structarray_done( &tmp);
}


- (void) addTimer:(NSTimer *) timer
{
   struct UIApplicationTimer   appTimer;

   // when we have too many holes compact
   if( _timerHoles >= MAX_TIMERHOLES)
       [self removeTimer:nil];

   assert( [timer mulleIsRelativeTimer]);

   appTimer.timestamp = mulle_absolutetime_now() + [timer mulleRelativeTimeInterval];
   appTimer.timer     = [timer retain];

   mulle_structarray_add( &_timers, &appTimer);

#ifdef RUN_DEBUG
   mulle_fprintf( stderr, "%#@: %#@ add Timer %@ (%.3f)\n",
                      [NSThread currentThread], self, timer, appTimer.timestamp);
#endif
}


- (mulle_relativetime_t) fireTimersIfNeeded:(mulle_absolutetime_t) now
{
   struct UIApplicationTimer            *appTimer;
   struct mulle_structarrayenumerator   rover;
   struct mulle_array                   fireTimers;
   struct mulle_arrayenumerator         fireRover;
   NSUInteger                           n;
   mulle_absolutetime_t                 then;
   mulle_relativetime_t                 min;
   mulle_relativetime_t                 diff;
   mulle_relativetime_t                 repeatInterval;
   NSTimer                              *timer;

   // if capacity is 0, nothing is malloced yet, which is good
   // because presumably most of the times there won't be timers at all
   //
   mulle_array_init( &fireTimers,
                     0,
                     (struct mulle_container_keycallback *) &key_retain_callback,
                     NULL);

   // because firing times may add or remove times, we first need to
   // collect all the timers in another array, then fire them

   min   = INFINITY;
   rover = mulle_structarray_enumerate( &_timers);
   while( mulle_structarrayenumerator_next( &rover, (void **) &appTimer))
   {
      timer = appTimer->timer;
      then  = appTimer->timestamp;
      diff  = then - now;

#ifdef RUN_DEBUG
      mulle_fprintf( stderr, "%@: Timer %@ %.3f (%.3f)\n",
                              [NSThread currentThread], timer, then, now);
#endif
      if( diff > 0.0) // time to fire
      {
         if( diff < min)
            min = diff;
         continue;
      }

      // add time to fire list
      mulle_array_add( &fireTimers, timer);

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
   mulle_structarrayenumerator_done( &rover);

   //
   // fire all the timers that were accumulated, very often this will
   // be none...
   //
   fireRover = mulle_array_enumerate( &fireTimers);
   while( _mulle_arrayenumerator_next( &fireRover, (void **) &timer))
   {
#ifdef RUN_DEBUG
       mulle_fprintf( stderr, "%@: Fire Timer %@\n",
                                        [NSThread currentThread], timer);
#endif
      [timer fire];
   }
   mulle_arrayenumerator_done( &fireRover);

   mulle_array_done( &fireTimers);

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
- (void) runWindows
{
   struct mulle_arrayenumerator   rover;
   id <UIWindow>                  window;
   BOOL                           closeWindows;
   mulle_absolutetime_t           now;
   mulle_absolutetime_t           previous;
   mulle_relativetime_t           timeout;
   mulle_relativetime_t           callAgainInSeconds;
   mulle_relativetime_t           nextWindowDisplayCallInSeconds;
   mulle_relativetime_t           nextTimerFireCallInSeconds;

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
            mulle_fprintf( stderr, "%#@: %#@ -> CheckWindows\n", [NSThread currentThread], self);
#endif
            closeWindows = NO;

            rover = mulle_array_enumerate( &_windows);
            while( _mulle_arrayenumerator_next( &rover, (void **) &window))
            {
               if( [window shouldClose])
               {
                  closeWindows = YES;
                  break;
               }
            }
            mulle_arrayenumerator_done( &rover);
         }

         // closing is relatively rare and a bit more expensive
         //  so I don't want to call _closeWindows all the time
         if( closeWindows)
         {
            _state = CloseWindows;
            {
#ifdef RUN_DEBUG
               mulle_fprintf( stderr, "%#@: %#@ -> CloseWindows\n", [NSThread currentThread], self);
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
            mulle_fprintf( stderr, "%#@: %#@ -> DrawAndSwap\n", [NSThread currentThread], self);
#endif
            rover = mulle_array_enumerate( &_windows);
            while( _mulle_arrayenumerator_next( &rover, (void **) &window))
            {
#ifdef RUN_DEBUG
               mulle_fprintf( stderr, "%#@: %#@ calls %@ to refresh (%.3f)\n",
                                       [NSThread currentThread], self, window,
                                       now);
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
            mulle_arrayenumerator_done( &rover);
         }

         _state = InvokeMethods;
         {
#ifdef RUN_DEBUG
            mulle_fprintf( stderr, "%#@: %#@ -> InvokeMethods\n", [NSThread currentThread], self);
#endif
            [self runInvocations];
         }

         _state = FireTimers;
         {
#ifdef RUN_DEBUG
            mulle_fprintf( stderr, "%#@: %#@ -> FireTimers\n", [NSThread currentThread], self);
#endif
            nextTimerFireCallInSeconds = [self fireTimersIfNeeded:now];
         }

         _state = WindowPropertyChanges;
         {
#ifdef RUN_DEBUG
            mulle_fprintf( stderr, "%#@: %#@ -> WindowPropertyChanges\n", [NSThread currentThread], self);
#endif
            rover = mulle_array_enumerate( &_windows);
            while( _mulle_arrayenumerator_next( &rover, (void **) &window))
            {
#ifdef RUN_DEBUG
               mulle_fprintf( stderr, "%#@: %#@ calls %@ to push property changes (%.3f)\n",
                                       [NSThread currentThread], self, window,
                                       now);
#endif
               [window writeOSWindowPropertyChangesIfNeeded];
            }
            mulle_arrayenumerator_done( &rover);
         }

         _state = PollEvents;
         {
#ifdef RUN_DEBUG
            mulle_fprintf( stderr, "%#@: %#@ -> PollEvents\n", [NSThread currentThread], self);
#endif
            timeout = nextTimerFireCallInSeconds < nextWindowDisplayCallInSeconds
                        ? nextTimerFireCallInSeconds
                        : nextWindowDisplayCallInSeconds;
            if( timeout < 0.0)
               timeout = 0.0;

#ifdef RUN_DEBUG
            mulle_fprintf( stderr, "%#@: %#@ next loop scheduled: %.17f\n",
                                       [NSThread currentThread], self, timeout);
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
//               [window handleEventQueue];
//            }
//            mulle_arrayenumerator_done( &rover);
//         }
      }
   }

   _state = Finished;
}


- (int) run
{
   [self runWindows];
   return( [self terminate]);
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
