#import "import.h"

#import "UIWindowTypes.h"
#import "UICursor.h"

//
// MEMO: unhandled events, are they passed to the application ? If yes
//       it could be a problem. Application would needs its own queue,
//       which is managed by the main thread.
//
// If you subclass UIApplication, you must not override +initialize or
// +deinitialize.
//
@interface UIApplication : NSObject <MulleObjCSingleton, UITimerReceiver, MulleUIResourceMap >
{
   struct mulle_array              _screens;
   NSLock *                        _screensLock;

   struct mulle_array              _windows;

   // custom cursors need a mulle_pointerarray (implement later)
   UICursor *                      _standardCursors[ n_UICursorStandardShapes];

   struct mulle_structarray        _timers;
   NSLock *                        _timersLock;
   NSUInteger                      _timerHoles;
   NSUInteger                      _state;
   struct MulleUIResourceStorage   _resourceStorage;

   mulle_atomic_pointer_t *        _executionQueue;
   struct mulle_pointermultififo   _invocationList;
   NSMethodSignature *             _bouncerSignature;
}

@property( assign) id   delegate;      // unused so far
@property( assign) int  returnStatus;

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

- (id <UIWindow>) windowForOSWindowHandle:(void *) os_window;


//
// UICursor
//
// Standard UICursors can be retrieved from any thread. 
// As they are allocated during initialization and removed
// on terminate.
//
// Cursors can't be removed currently, so don't stream
// videos into your cursor bitmap (would waste lotsa leaks)...
//
- (UICursor *) cursorWithStandardShape:(UICursorStandardShape) shape;


//
// NSTimer:
//
// NSTimers that are not mutable can be added in a threadsafe manner.
//

- (void) addTimer:(NSTimer *) timer
 forTimerReceiver:(id <UITimerReceiver>) receiver;

- (void) removeTimer:(NSTimer *) timer
    forTimerReceiver:(id <UITimerReceiver>) receiver;

- (void) removeAllTimersForTimerReceiver:(id <UITimerReceiver>) receiver;

- (void) removeAllTimers;

// like re-adding a timer, the timer is reset to now + offset
- (void) resetTimer:(NSTimer *) timer;


//
// These invocations are called during run and runLoop.
// This is the way to do window functionality which needs to run on the
// main thread. This is async, so you don't get a return value.
//
- (void) invokeOnMainThread:(NSInvocation *) invocation;

// this will actually block the calling thread, not recommended
- (void) invokeOnMainThread:(NSInvocation *) invocation
              waitUntilDone:(BOOL) flag;

// called during runLoop
- (void) runInvocations;


// this will return and the app will terminate some time later, 
// except if called on the mainThread
- (void) requestTerminate;

// call terminate on all windows and then remove all of them
// must be called from mainThread
- (int) terminate;

// must be called from mainThread
- (void) runLoop;

// calls runLoop and then when all have closed, calls terminate
// must be called from mainThread
- (int) run;

// like UIApplicationRunWindow
- (int) runWindow:(id <UIWindow>) window;


@end


@interface UIApplication( OS)

+ (void) os_initialize;
+ (void) os_deinitialize;

- (void) os_init;
- (void) os_finalize;

- (void *) os_createStandardCursor:(UICursorStandardShape) shape;
- (void) os_destroyCursor:(void *) cursor;

@end


int  UIApplicationMain( int argc, char **argv, Class appClass, id delegate);


// A shortcut for +sharedInstance, addWindow: and runLoop and terminate.
// This must be called from mainThread
int  UIApplicationRunWindow( id <UIWindow> window);


// the singleton is placed into a global variable for easier access during
// events. [UIApplication sharedInstance] sets this variable and 
// UIWindow initWithFrame:... is guaranteed to call 
// [UIApplication sharedInstance]

//UI_APPLICATION_EXTERN_GLOBAL
extern UIApplication   *UIApp;

