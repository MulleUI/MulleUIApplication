#import "import.h"

#import "UIWindowTypes.h"

//
// MEMO: unhandled events, are they passed to the application ? If yes
//       it could be a problem. Application would needs its own queue,
//       which is managed by the main thread.
//
@interface UIApplication : NSObject <MulleObjCSingleton>
{
   struct mulle_array                    _windows;
   struct mulle_structarray              _timers;
   NSUInteger                            _timerHoles;
   NSUInteger                            _state;
   mulle_atomic_pointer_t                *_executionQueue;
   struct mulle_pointermultififo         _invocationList;
   NSMethodSignature                     *_bouncerSignature;
}

@property( assign) id   delegate;      // unused so far
@property( assign) int  returnValue;

- (void) addWindow:(id <UIWindow>) window;
// does not call [UIWindow terminate]
- (void) removeWindow:(id<UIWindow>) window;

// call terminate on all windows and then remove all of them
- (int) terminate;

// calls runWindows and then when all have closed, calls terminate
- (int) run;
- (void) runWindows;

- (NSUInteger) numberOfWindows;
- (NSUInteger) getWindows:(id<UIWindow> *) buf
                   length:(NSUInteger) length;


- (void) addTimer:(NSTimer *) timer;
- (void) removeTimer:(NSTimer *) timer;
- (void) removeAllTimers;


//
// These invocations are called during run and runWindows.
// This is the way to do window functionality which needs to run on the
// main thread. This is async, so you don't get a return value.
//
- (void) invokeOnMainThread:(NSInvocation *) invocation;

- (void) invokeOnMainThread:(NSInvocation *) invocation
              waitUntilDone:(BOOL) flag;

// called during runWindows
- (void) runInvocations;

@end


@interface UIApplication( OS)

+ (void) os_initialize;
+ (void) os_terminate;

@end

int  UIApplicationMain( int argc, char **argv, Class appClass, id delegate);

