#import "UIApplication.h"

#import "import-private.h"

#import "import-project.h"

#include <errno.h>

#define MAX_TIMERHOLES    8
//#define RUN_DEBUG


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
   PollGamepads,
   WindowPropertyChanges,
   ProcessEvents,
   Finished,
   Terminating,
   Terminated
};


@interface NSObject( Declare)

- (void) _setPrimary:(BOOL) flag;

@end



MULLE_UI_APPLICATION_GLOBAL_VAR
UIApplication   *UIApp;

MULLE_UI_APPLICATION_GLOBAL_VAR
BOOL            UIApplicationRequestRunLoopBreak;


@interface UIApplication( Declare)

// don't call these yourself
- (void) loadStandardCursors;
- (void) removeStandardCursors;
- (void) removeCustomCursors;
- (void) removeAllTimers;
- (void) removeAllWindows;
- (void) removeAllInvocations;

@end 


@implementation NSObject( UIApplication)

- (BOOL) __isUIApplication
{
   return( NO);
}

@end


@implementation UIApplication

static struct
{
   NSUInteger   _debuggingFlags;
} Self;


static void   UIApplicationInitializeDebuggingFlags( Class self)
{
   char   *s;

   // don't rerun for subclass
   if( MulleObjCClassGetID( self) != @selector( UIApplication))
      return;

   // __CLASS_NAME__ is a wished for compiler feature,
   s = getenv( MULLE_C_STRINGIFY( UIApplication) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      Self._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) setDebuggingFlags:(NSUInteger) flag   MULLE_OBJC_THREADSAFE_METHOD
{
   Self._debuggingFlags = flag;
}



//
// TODO: this is an Objective-C problem, that if you subclass UIApplication
//       then initialize will be called first on UIApplication, which will
//       call "its" +os_initialize, so you can't really override it. Later
//       your subclass will call os_initialize again, now initializing a 
//       a second time. Your initialize needs to call os_deinitialize before
//       calling os_initialize again. Super bad. Solution ? Change the 
//       default behaviour of +initialize to _not_ be called when there
//       is no immediate implementation ?
//
+ (void) initialize
{
   [super initialize];  // call singleton initialize ?
   UIApplicationInitializeDebuggingFlags( self);

   if( [self respondsToSelector:@selector( os_initialize)])
      [self os_initialize];
}


+ (void) deinitialize
{
   if( [self respondsToSelector:@selector( os_deinitialize)])
      [self os_deinitialize];
}


- (BOOL) __isUIApplication
{
   return( YES);
}


#pragma clang diagnostic ignored "-Wobjc-method-access"
+ (instancetype) sharedInstance
{
   if( ! UIApp)
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

#ifdef UIAPPLICATION_DEBUGGING_FLAGS
   _debuggingFlags = UIAPPLICATION_DEBUGGING_FLAGS;
#else
   _debuggingFlags = Self._debuggingFlags;
#endif
   if( _debuggingFlags)
      MulleUILog( "init");

   [self _initResourceStorage:&_resourceStorage];

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_array_init( &_screens,
                     2,
                     &MulleObjCContainerRetainKeyCallback,
                     allocator);
   _screensLock = [NSLock new];

   allocator = MulleObjCInstanceGetAllocator( self);

   mulle_pointerarray_init( &_gamepads,
                            4,
                            allocator);
   _gamepadsLock = [NSLock new];


   mulle_map_init( &_standardCursors,
                   n_UICursorStandardShapes,
                   (struct mulle_container_keyvaluecallback *) &_MulleObjCContainerIntegerKeyPointerValueCallback,
                   allocator);

   _customCursorLock = [NSLock new];
   mulle_map_init( &_customCursors,
                   0,
                   (struct mulle_container_keyvaluecallback *) &_MulleObjCContainerCopiedCStringPointerValueCallback,
                   allocator);

   mulle_array_init( &_windows,
                     4,
                     &MulleObjCContainerRetainKeyCallback,
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


- (MulleObjCTAOStrategy) mulleTAOStrategy
{
   return( MulleObjCTAOKnownThreadSafeMethods);
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
   id   gamepad;

   assert( [NSThread mulleIsMainThread]);

   [self _doneResourceStorage:&_resourceStorage];

   [_bouncerSignature release];

   assert( _mulle_pointermultififo_read_barrier( &_invocationList) == NULL);
   _mulle_pointermultififo_done( &_invocationList);

   [_timersLock release];
   mulle_structarray_done( &_timers);
   mulle_array_done( &_windows);

   [_customCursorLock release];
   mulle_map_done( &_customCursors);

   [_gamepadsLock release];
   mulle_pointerarray_for( &_gamepads, gamepad)
   {
      [gamepad release];
   }
   mulle_pointerarray_done( &_gamepads);

   [_eventPlayer release];

   [_screensLock release];
   mulle_array_done( &_screens);

   mulle_map_done( &_standardCursors);

   [super dealloc];
}


- (struct MulleUIResourceStorage *) _resourceStorage  MULLE_OBJC_THREADSAFE_METHOD
{
   return( &_resourceStorage);
}

/*
 *
 */

// assume all windows thread are quiescent now... else why call terminate :)


- (int) terminate
{
   assert( [NSThread mulleIsMainThread]);

   UIApplicationRequestRunLoopBreak = YES;
   if( _state == Terminated)
      return( _returnStatus);

   _state = Terminating;

   [self setEventPlayer:nil];
   [self removeAllInvocations];
   [self removeAllTimers];
   [self removeAllWindows];

   if( [self respondsToSelector:@selector( os_finalize)])
      [self os_finalize];

   [self removeCustomCursors];
   [self removeStandardCursors];

   _state = Terminated;

   return( _returnStatus);
}


- (void) invokeOnMainThread:(NSInvocation *) invocation  MULLE_OBJC_THREADSAFE_METHOD
{
   if( ! invocation)
      return;

   // Even if we are the mainThread we want to keep the sequence of the
   // invocations as stored in the _invocationList and only "fire" them off at
   // a predefined sequence point in the runLoop. So we don't special case this
   // if( [NSThread mulleIsMainThread])
   //    [invocation invoke];

   // TODO: use -mulleImmutableCopyArguments, which doesn't exist yet (?)
   [invocation retainArguments];
   [invocation mulleRelinquishAccess];

   for(;;)
   {
      if( ! _mulle_pointermultififo_write( &_invocationList, invocation))
         break;

      switch( errno)
      {
      case EBUSY :  // just busy, we wait... this should happen really rarely
         mulle_thread_yield();
         break;

      default :
         MulleObjCThrowErrnoExceptionUTF8String( "invocation fifo problem");
      }
   }
}


// TODO: explain why this is not a MulleInvocationQueue
- (void) runInvocations
{
   NSInvocation   *invocation;

   assert( [NSThread mulleIsMainThread]);

   // maybe name "extract"
   while( (invocation = _mulle_pointermultififo_read_barrier( &_invocationList)))
   {
      [invocation mulleGainAccess];
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
      // coded like runInvocations for least surprises
      [invocation mulleGainAccess];
   }
}


- (void) _synchronousInvoke:(NSInvocation *) invocation
              conditionLock:(NSConditionLock *) lock
{
   assert( [NSThread mulleIsMainThread]);

   [lock lockWhenCondition:0];  // this can not not work
   [invocation invoke];
   [invocation mulleRetainReturnValue];
   [invocation mulleRelinquishAccess];
   [lock unlockWithCondition:1]; // this will not block either
}


//
// if waitUntilDone is set to YES, you can get the return value
// from the invocation!!! In this case the invocation w
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

   //
   // A special case, if we are the main thread we could deadlock ourselfs.
   // So we just run it now, circumventing any stored invocations.
   //
   if( [NSThread mulleIsMainThread])
   {
      [invocation invoke];
      return;
   }

   // keep invocation around for return value
   //[invocation retain];

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

   // get invocation back (and autorelease)
   [invocation mulleGainAccess];

   // rare that we don't autorelease here, but...
   // we can't get exceptions from the invocation anyway, and I want the
   // lock to be gone ASAP, because there could be OS limits...
   [lock release];
}



- (void) setEventPlayer:(id) player
{
   assert( [NSThread mulleIsMainThread]);
   if( player == _eventPlayer)
      return;
   if( _eventPlayer)
      [_eventPlayer autorelease];
   _eventPlayer = [player retain];
}


- (id) eventPlayer
{
   assert( [NSThread mulleIsMainThread]);
   return( _eventPlayer);
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

   NSLockingDo( _screensLock)
   {
      count = mulle_array_get_count( &_screens);
   }

   return( count);
}


- (id <UIScreen>) screenAtIndex:(NSUInteger) i
{
   NSUInteger      n;
   id <UIScreen>   screen;

   screen = nil;
   NSLockingDo( _screensLock)
   {
      n = mulle_array_get_count( &_screens);
      if( i < n)
      {
         screen = mulle_array_get( &_screens, i);
         screen = [[screen retain] autorelease];
      }
   }

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

   NSLockingDo( _screensLock)
   {
      assert( [self _indexOfScreen:screen] == NSNotFound);
      mulle_array_add( &_screens, screen);
   }
}


- (void) _removeScreen:(id <UIScreen>) screen
{
   NSInteger   found;

   NSLockingDo( _screensLock)
   {
      found = [self _indexOfScreen:screen];
      if( found != NSNotFound)
      {
         [screen mullePerformFinalize]; // lop off connection to GLFW
         mulle_array_remove_in_range( &_screens, mulle_range_make( found, 1));
      }
   }
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

   NSLockingDo( _screensLock)
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
   NSLockingDo( _screensLock)
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

   return( count);
}


/*
 * UIGamepad
 */
static NSUInteger   UIApplicationIndexOfGamepad( UIApplication *self,
                                                 id <UIGamepad> gamepad,
                                                 NSUInteger * firstHoleIndex,
                                                 BOOL locking)
{
   char        *guid;
   char        *other_guid;
   NSUInteger  i;
   NSUInteger  index;
   NSLock      *lock;

   guid            = [gamepad guidUTF8String];
   index           = NSNotFound;
   *firstHoleIndex = NSNotFound;  // superflous but less complicated

   if( ! guid)
      return( index);

   lock = locking ? self->_gamepadsLock : nil;
   NSLockingDo( lock)
   {
      i = 0;
      mulle_pointerarray_for( &self->_gamepads, gamepad)
      {
         other_guid = [gamepad guidUTF8String];
         if( ! other_guid)
         {
            *firstHoleIndex = i;
            continue;
         }
         if( ! strcmp( guid, other_guid))
         {
            index = i;
            break;
         }
         i++;
      }
   }

   return( index);
}


- (NSUInteger) indexOfGamepad:(id <UIGamepad>) gamepad
{
   NSUInteger   unused;

   return( UIApplicationIndexOfGamepad( self, gamepad, &unused, YES));
}



static NSInteger   UIApplicationIndexForSetGamepad( UIApplication *self,
                                                    id <UIGamepad> gamepad)
{
   id <UIGamepad>   old;
   NSUInteger       index;
   NSUInteger       firstHoleIndex;

   index = UIApplicationIndexOfGamepad( self, gamepad, &firstHoleIndex, NO);
   if( index == NSNotFound)
   {
      index = firstHoleIndex;
      if( index == NSNotFound)
         index = mulle_pointerarray_get_count( &self->_gamepads);
   }
   else
   {
      // remove previous if present
      old = mulle_pointerarray_get_zeroing( &self->_gamepads, index);
      if( old)
      {
         [old autorelease];
         self->_numberOfGamepads--;
      }
   }
   return( index);
}


- (void) _addGamepad:(id <UIGamepad>) gamepad
{
   NSInteger   index;

   assert( gamepad);

   NSLockingDo( _gamepadsLock)
   {
      index = UIApplicationIndexForSetGamepad( self, gamepad);

      [gamepad retain];
      mulle_pointerarray_set_zeroing( &_gamepads, index, gamepad);
      _numberOfGamepads++;
   }
}


- (void) _removeGamepad:(id <UIGamepad>) gamepad
{
   NSInteger   index;

   assert( gamepad);

   NSLockingDo( _gamepadsLock)
   {
      index = UIApplicationIndexForSetGamepad( self, gamepad);
      mulle_pointerarray_set_zeroing( &_gamepads, index, NULL);
      [gamepad mullePerformFinalize]; // lop off connection to GLFW
   }
}


- (id <UIGamepad>) gamepadAtIndex:(NSUInteger) index
{
   id <UIGamepad>   gamepad;

   NSLockingDo( _gamepadsLock)
   {
      gamepad = mulle_pointerarray_get_zeroing( &_gamepads, index);
      gamepad = [[gamepad retain] autorelease];
   }

   return( gamepad);
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

   assert( [NSThread mulleIsMainThread]);

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

   assert( [NSThread mulleIsMainThread]);

   mulle_array_init( &tmp,
                     mulle_array_get_count( &_windows),
                     mulle_array_get_callback( &_windows),
                     NULL);
   mulle_array_add_array( &tmp, &_windows, mulle_range_make_all());

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


- (id <UIWindow>) windowAtIndex:(NSUInteger) index
{
   id <UIWindow>    window;
   NSUInteger       count;

   assert( [NSThread mulleIsMainThread]);

   count = mulle_array_get_count( &_windows);
   if( index >= count)
      return( nil);

   window = mulle_array_get( &_windows, index);

   return( window);
}


//
//
//

- (CGPixelSize) standardCursorSize
{
#if defined(_WIN32)
      return( CGPixelSizeMake( 32, 32));
#endif

#if defined(__APPLE__)
      return( CGPixelSizeMake( 32, 32));
#endif

#if defined(__linux__)
   char   *xdg_session_type = (char *) getenv("XDG_SESSION_TYPE");

   if( xdg_session_type && strcmp(xdg_session_type, "wayland") == 0)
   {
      return( CGPixelSizeMake( 32, 32));
   }
   else
   {
      return( CGPixelSizeMake( 32, 32));
   }
#else
   return( CGPixelSizeMake( 32, 32));
#endif
}


- (UICursor *) cursorWithStandardShape:(UICursorStandardShape) shape
{
   return( mulle_map_get( &_standardCursors, (void *) shape));
}


- (void) loadStandardCursors
{
   NSUInteger   shape;
   UICursor     *cursor;

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
      cursor = [self os_createStandardCursor:shape];
      mulle_map_set( &_standardCursors, (void *) shape, cursor);
   }
}


- (void) removeStandardCursors
{
   NSUInteger   shape;
   UICursor     *cursor;

   assert( [NSThread mulleIsMainThread]);

   for( shape = 1; shape < n_UICursorStandardShapes; shape++)
   {
      cursor = mulle_map_get( &_standardCursors, (void *) shape);
      if( cursor) // can happen in tests
      {
         [self os_destroyCursor:cursor];
         mulle_map_remove( &_standardCursors, (void *) shape);
      }
   }
}


- (UICursor *) cursorForKeyUTF8String:(char *) s
{
   UICursor  *cursor;

   NSLockingDo( _customCursorLock)
   {
      cursor = mulle_map_get( &_customCursors, (void *) s);
   }
   return( cursor);
}


- (void) removeCustomCursors
{
   UICursor     *cursor;
   char         *key;

   assert( [NSThread mulleIsMainThread]);

   mulle_map_for( &_customCursors, key, cursor)
   {
      [self os_destroyCursor:cursor];
   }
   mulle_map_reset( &_customCursors);
}


- (UICursor *) registerCursorBitmap:(struct CGBitmap) bitmap
                            hotSpot:(CGPixelPoint) hotSpot
                   forKeyUTF8String:(char *) key
                scaleToStandardSize:(BOOL) flag
{
   struct CGBitmapInfo  info;
   struct CGBitmap      scaled;
   struct CGBitmap      *cursorBitmap;
   UICursor             *cursor;

   assert( [NSThread mulleIsMainThread]);

   info = CGBitmapInfoMake( flag
                              ? [self standardCursorSize]
                              : bitmap.info.size,
                            0,
                            CGBitmapEncodingRGBABytes);

   // avoid needless bitmap copy, if it already fits
   if( CGBitmapNeedsConversion( bitmap, info))
   {
      scaled       = CGBitmapConvert( bitmap, info, NULL);
      cursorBitmap = &scaled;
   }
   else
   {
      memset( &scaled, 0, sizeof( scaled));
      cursorBitmap = &bitmap;
   }

   cursor = [self os_createCursorWithBitmap:*cursorBitmap
                                    hotSpot:hotSpot];
   if( cursor)
      NSLockingDo( _customCursorLock)
      {
         mulle_map_set( &_customCursors, key, (void *) cursor);
      }

   CGBitmapDone( scaled);
   return( cursor);
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


- (void) handleRetainedTimer:(NSTimer *) timer   MULLE_UI_MAIN_THREAD_ONLY
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

   NSLockingDo( _timersLock)
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
}


// if timer is nil, this will remove all timers of the receiver
// if receiver is nil, it will ignore receiver for check
- (void) removeTimer:(NSTimer *) timer
    forTimerReceiver:(id <UITimerReceiver>) receiver
{
   struct UIApplicationTimer   *appTimer;
   struct mulle_structarray    tmp;
   NSUInteger                  n;

   NSLockingDo( _timersLock)
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
               [appTimer->timer autorelease];
               continue;
            }
            mulle_structarray_add( &_timers, appTimer);
         }

         // now remove tmp
         mulle_structarray_done( &tmp);
      }
   }
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

   NSLockingDo( _timersLock)
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

#ifdef RUN_DEBUG
   MulleUILog( "add Timer %#@ (%.3f)", timer, appTimer.timestamp);
#endif
}


- (void) resetTimer:(NSTimer *) timer
{
   struct UIApplicationTimer   *appTimer;

   assert( [timer isKindOfClass:[NSTimer class]]);

   NSLockingDo( _timersLock)
   {
      assert( [timer mulleIsRelativeTimer]);

      mulle_structarray_for( &_timers, appTimer)
      {
         if( appTimer->timer == timer)
         {
            appTimer->timestamp = mulle_absolutetime_now() + [timer mulleRelativeTimeInterval];
#ifdef RUN_DEBUG
            MulleUILog( "reset Timer %#@ (%.3f)", timer, appTimer->timestamp);
#endif
            break;
         }
      }
   }
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

   NSLockingDo( _timersLock)
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
         MulleUILog( "Timer %#@ %.3f (%.3f)",timer, then, now);
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

   //
   // fire all the timers that were accumulated, very often this will
   // be none...
   //
   mulle_structarray_for( &fireTimers, appTimer)
   {
#if defined( RUN_DEBUG)
       MulleUILog( "Fire Timer %#@",timer);
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
//
//

//
// The frameRate of a window gives a "hint", when to call "draw" again. "draw"
// may be called earlier though, it's the windows task to check, if it wants
// to redraw. If it doesn't, it returns the amount of time it wants to wait
// for the next frame. The decoupling of "game" code that runs at fixed
// intervals, will be done with NSTimers, that sort of act like a window.
// We also put them into the loop, query them for when they want to run.
//

- (BOOL) runLoopIteration
{
   BOOL                   closeWindows;
   id <UIWindow>          window;
   mulle_relativetime_t   callAgainInSeconds;
   mulle_relativetime_t   previous;
   mulle_relativetime_t   now;
   mulle_relativetime_t   timeout;
   mulle_relativetime_t   nextWindowDisplayCallInSeconds;
   mulle_relativetime_t   nextTimerFireCallInSeconds;

   assert( [NSThread mulleIsMainThread]);

   _state = CheckWindows;
   {
      UIApplicationLogVerbose( "-> CheckWindows");
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
         UIApplicationLogVerbose( "-> CloseWindows");
         [self _closeWindows];
      }
   }

   if( ! mulle_array_get_count( &_windows))  // no windows left ?
      return( NO);

   nextWindowDisplayCallInSeconds = INFINITY;
   previous                               = 0.0;
   now                                    = mulle_absolutetime_now();

   _state = DrawAndSwap;
   {
      UIApplicationLogVerbose( "-> DrawAndSwap");
      mulle_array_for( &_windows, window)
      {
         UIApplicationLog( "calls %#@ to refresh", window);

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

         UIApplicationLog( "%#@ will be called to refresh again in %.6gs (requested %.6gs)", window,
                           nextWindowDisplayCallInSeconds, callAgainInSeconds);
      }
   }

   _state = WindowPropertyChanges;
   {
      UIApplicationLogVerbose( "-> WindowPropertyChanges");
      mulle_array_for( &_windows, window)
      {
         UIApplicationLogVerbose( "calls %#@ to push property changes", window);

         // this will also push mouse state if polling
         [window syncOSWindowPropertyChangesIfNeeded];
      }
   }

   _state = InvokeMethods;
   {
      UIApplicationLogVerbose( "-> InvokeMethods");
      [self runInvocations];
   }

   if( UIApplicationRequestRunLoopBreak)
      return( NO);

   _state = FireTimers;
   {
      UIApplicationLogVerbose( "-> FireTimers");
      nextTimerFireCallInSeconds = [self fireTimersIfNeeded:now];
   }

   _state = PollEvents;
   {
      timeout = nextTimerFireCallInSeconds < nextWindowDisplayCallInSeconds
                  ? nextTimerFireCallInSeconds
                  : nextWindowDisplayCallInSeconds;
      if( timeout < 0.0)
         timeout = 0.0;

      UIApplicationLogVerbose( "-> PollEvents with timeout: %.17f", timeout);
      [self os_waitEventsWithTimeout:timeout];
      UIApplicationLogVerbose( "<- PollEvents returned");
   }

   // this will generate event callbacks for gamepads to the application
   // but the event will be sent later to the
   _state = PollGamepads;
   {
      UIApplicationLogVerbose( "-> PollGamepads");
      [self os_pollGamepads];
      UIApplicationLogVerbose( "<- PollGamepads");
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
   return( YES);
}


- (void) runLoop
{
   BOOL  keepGoing;

   if( _state == Terminated)
      return;

   // TODO:  call delegate -applicationDidFinishLaunching here ?
   do
   {
      @autoreleasepool
      {
         keepGoing = [self runLoopIteration];
      }

   }
   while( keepGoing);

   _state = Finished;
}


- (int) runApp
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
   return( [app runApp]);
}

@end
