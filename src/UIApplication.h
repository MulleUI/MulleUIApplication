#import "import.h"

#import "UIWindowTypes.h"

//
// MEMO: unhandled events, are they passed to the application ? If yes
//       it could be a problem. Application would needs its own queue,
//       which is managed by the main thread.
//
@interface UIApplication : NSObject <MulleObjCSingleton>
{
   struct mulle_array                    _screens;
   NSLock                                *_screensLock;

   struct mulle_array                    _windows;

   struct mulle_structarray              _timers;
   NSLock                                *_timersLock;
   NSUInteger                            _timerHoles;
   NSUInteger                            _state;

   mulle_atomic_pointer_t                *_executionQueue;
   struct mulle_pointermultififo         _invocationList;
   NSMethodSignature                     *_bouncerSignature;
}

@property( assign) id   delegate;      // unused so far
@property( assign) int  returnValue;

//
// UIScreen:
//
// UIScreens are managed by the UIApplication. You don't add or remove
// UIScreens manually. Once you have a screen you can get its info also in
// a threadsafe manner.
//
- (id <UIScreen>) primaryScreen;
- (NSUInteger) numberOfScreens;
- (id <UIScreen>) screenAtIndex:(NSUInteger) i;

// use the window frame to figure out on which screen the window resides
// (predominantly)
// can also be nil if primaryIfNoneMatches is set, if no screen is connected
- (id <UIScreen>) screenForFrame:(CGRect) frame
            primaryIfNoneMatches:(BOOL) primaryIfNoneMatches;

// always returns the number of actually intersecting screens. Will store
// the first `maxCount` screens in `screens`
- (NSUInteger) getScreens:(id <UIScreen> *) screens
                 maxCount:(NSUInteger) maxCount
        intersectingFrame:(CGRect) frame;

//
// UIWindow
//
// UIWindows should be added and removed only from the main thread.
// What can be queried on a UIWindow from the mainThread and from a possible
// render/event thread is explained in UIWindow.h

- (void) addWindow:(id <UIWindow>) window;
// does not call [UIWindow terminate]
- (void) removeWindow:(id<UIWindow>) window;

- (NSUInteger) numberOfWindows;
- (NSUInteger) getWindows:(id <UIWindow> *) buf
                   length:(NSUInteger) length;


//
// NSTimer:
//
// NSTimers that are not mutable can be added in a threadsafe manner.
//
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



// call terminate on all windows and then remove all of them
- (int) terminate;

// calls runWindows and then when all have closed, calls terminate
- (int) run;
- (void) runWindows;



@end


@interface UIApplication( OS)

+ (void) os_initialize;
+ (void) os_terminate;

- (void) os_init;
- (void) os_finalize;

@end


int  UIApplicationMain( int argc, char **argv, Class appClass, id delegate);

