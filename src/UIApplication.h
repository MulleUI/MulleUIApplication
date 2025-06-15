#import "import.h"

#import "UIWindowTypes.h"
#import "UICursor.h"

#define N_UIApplicationSpaceDoubles  5

//
// MEMO: unhandled events, are they passed to the application ? If yes
//       it could be a problem. Application would needs its own queue,
//       which is managed by the main thread.
//
// If you subclass UIApplication, you must not override +initialize or
// +deinitialize. If you add category methods, make sure they are either
// main thread only or threadsafe. UIApplication is not marked as threadsafe,
// but its TAO strategy is (MulleObjCTAOKnownThreadSafeMethods)
//
@interface UIApplication : MulleDynamicObject <MulleObjCSingleton, UITimerReceiver, MulleUIResourceMap >
{
   struct mulle_array              _screens;
   NSLock *                        _screensLock;

   struct mulle_pointerarray       _gamepads;
   NSUInteger                      _numberOfGamepads; // not same as count!
   NSLock *                        _gamepadsLock;

   struct mulle_array              _windows;
   struct mulle_map                _standardCursors;

   NSLock *                        _customCursorLock;
   struct mulle_map                _customCursors;

   struct mulle_structarray        _timers;
   NSLock *                        _timersLock;
   NSUInteger                      _timerHoles;
   NSUInteger                      _state;
   struct MulleUIResourceStorage   _resourceStorage;

   mulle_atomic_pointer_t *        _executionQueue;
   struct mulle_pointermultififo   _invocationList;
   NSMethodSignature *             _bouncerSignature;

// some private state for the runloop, so we can have the iteration
// run in a separate method
@private
   // none needed ?

   //
   // here is some extra space for SDL/GLFW whoever. Subclassing UIApplication
   // in general is tricky, but for SDL we need some storage space for handles
   //
@private
   struct
   {
      double  _d[ N_UIApplicationSpaceDoubles];
   } _space;
}



@property( assign) id           delegate        MULLE_UI_MAIN_THREAD_ONLY;      // unused so far
@property( assign) int          returnStatus    MULLE_UI_MAIN_THREAD_ONLY;
@property( assign) NSUInteger   debuggingFlags  MULLE_OBJC_THREADSAFE_PROPERTY;

//
// UIScreen:
//
// UIScreens are managed by the UIApplication. You don't add or remove
// UIScreens manually. Once you have a screen you can get its info also in
// a threadsafe manner.
//
- (id <UIScreen>) primaryScreen                 MULLE_OBJC_THREADSAFE_METHOD;
- (NSUInteger) numberOfScreens                  MULLE_OBJC_THREADSAFE_METHOD;
- (id <UIScreen>) screenAtIndex:(NSUInteger) i  MULLE_OBJC_THREADSAFE_METHOD;

// use the window frame to figure out on which screen the window resides
// (predominantly)
// can also be nil if primaryIfNoneMatches is set, if no screen is connected
- (id <UIScreen>) screenForFrame:(CGRect) frame
            primaryIfNoneMatches:(BOOL) primaryIfNoneMatches   MULLE_OBJC_THREADSAFE_METHOD;

// always returns the number of actually intersecting screens. Will store
// the first `maxCount` screens in `screens`
- (NSUInteger) getScreens:(id <UIScreen> *) screens
                 maxCount:(NSUInteger) maxCount
        intersectingFrame:(CGRect) frame                       MULLE_OBJC_THREADSAFE_METHOD;



//
// UIGamepad:
//
// Note that gamepads can be unplugged and swapped, so a gamepadAtIndex: can
// return nil. We don't keep the joystick stable, but we could...
//
- (id <UIGamepad>) gamepadAtIndex:(NSUInteger) i MULLE_OBJC_THREADSAFE_METHOD;


//
// UIWindow
//
// UIWindows should be added and removed only from the main thread.
// What can be queried on a UIWindow from the mainThread and from a possible
// render/event thread is explained in UIWindow.h

- (void) addWindow:(id <UIWindow>) window                      MULLE_UI_MAIN_THREAD_ONLY;
// does not call [UIWindow terminate]
- (void) removeWindow:(id<UIWindow>) window                    MULLE_UI_MAIN_THREAD_ONLY;


- (NSUInteger) numberOfWindows                                 MULLE_UI_MAIN_THREAD_ONLY;
- (NSUInteger) getWindows:(id <UIWindow> *) buf
                   length:(NSUInteger) length                  MULLE_UI_MAIN_THREAD_ONLY;

- (id <UIWindow>) windowForOSWindowHandle:(void *) os_window   MULLE_UI_MAIN_THREAD_ONLY;


//
// UICursor
//
// Standard UICursors can be retrieved from any thread. 
// As they are allocated during initialization and removed
// on terminate.
//
// Cursors can't be removed currently, so don't stream
// videos into your cursor bitmap (would waste lotsa leaks)...
// Standard shape cursors are readonly, so considered threadsafe (though
// not locking)
//
- (UICursor *) cursorWithStandardShape:(UICursorStandardShape) shape MULLE_OBJC_THREADSAFE_METHOD;

// add your own cursors with a name
 - (UICursor *) registerCursorBitmap:(struct CGBitmap) bitmap
                             hotSpot:(CGPixelPoint) hotSpot
                    forKeyUTF8String:(char *) key
                 scaleToStandardSize:(BOOL) flag                       MULLE_UI_MAIN_THREAD_ONLY;

- (UICursor *) cursorForKeyUTF8String:(char *) s                     MULLE_OBJC_THREADSAFE_METHOD;

// this is likely to be some hardcoded value, depending on platform
- (CGPixelSize) standardCursorSize;

//
// NSTimer:
//
// NSTimers that are not mutable can be added in a threadsafe manner.
//

- (void) addTimer:(NSTimer *) timer
 forTimerReceiver:(id <UITimerReceiver>) receiver     MULLE_OBJC_THREADSAFE_METHOD;

- (void) removeTimer:(NSTimer *) timer
    forTimerReceiver:(id <UITimerReceiver>) receiver  MULLE_OBJC_THREADSAFE_METHOD;

- (void) removeAllTimersForTimerReceiver:(id <UITimerReceiver>) receiver   MULLE_OBJC_THREADSAFE_METHOD;

- (void) removeAllTimers                              MULLE_OBJC_THREADSAFE_METHOD;

// like re-adding a timer, the timer is reset to now + offset
- (void) resetTimer:(NSTimer *) timer                 MULLE_OBJC_THREADSAFE_METHOD;


//
// These invocations are called during run and runLoop.
// This is the way to do window functionality which needs to run on the
// main thread. This is async, so you don't get a return value.
//
- (void) invokeOnMainThread:(NSInvocation *) invocation  MULLE_OBJC_THREADSAFE_METHOD;

// this will actually block the calling thread, not recommended
- (void) invokeOnMainThread:(NSInvocation *) invocation
              waitUntilDone:(BOOL) flag                  MULLE_OBJC_THREADSAFE_METHOD;

// called during runLoop
- (void) runInvocations                                  MULLE_UI_MAIN_THREAD_ONLY;

// only call during tests
- (void) removeAllInvocations                            MULLE_UI_MAIN_THREAD_ONLY;


// this will return and the app will terminate some time later, 
// except if called on the mainThread
- (void) requestTerminate                                MULLE_OBJC_THREADSAFE_METHOD;

// call terminate on all windows and then remove all of them
// must be called from mainThread
- (int) terminate                                        MULLE_UI_MAIN_THREAD_ONLY;

// must be called from mainThread
- (void) runLoop                                         MULLE_UI_MAIN_THREAD_ONLY;

// must be called from mainThread
- (BOOL) runLoopIteration                                MULLE_UI_MAIN_THREAD_ONLY;


// calls runLoop and then when all have closed, calls terminate
// must be called from mainThread
// can not be called -run because thats a different signature
- (int) runApp                                           MULLE_UI_MAIN_THREAD_ONLY;

// like UIApplicationRunWindow
- (int) runWindow:(id <UIWindow>) window                 MULLE_UI_MAIN_THREAD_ONLY;

// this window gets the events, if UIApplication can not decide which
// window should get it (this does not imply ordering at all)
@property( retain, setter=setOSKeyWindow:) id <UIOSWindow>  osKeyWindow    MULLE_UI_MAIN_THREAD_ONLY;

@end


@interface UIApplication( OS)

+ (void) os_initialize           MULLE_UI_MAIN_THREAD_ONLY;
+ (void) os_deinitialize         MULLE_UI_MAIN_THREAD_ONLY;

- (void) os_init                 MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_finalize             MULLE_UI_MAIN_THREAD_ONLY;

- (void *) os_createStandardCursor:(UICursorStandardShape) shape  MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_destroyCursor:(void *) cursor                         MULLE_UI_MAIN_THREAD_ONLY;

- (void) os_waitEventsWithTimeout:(mulle_relativetime_t) seconds  MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_pollEvents                                            MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_pollGamepads                                          MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_sendEmptyEvent       MULLE_OBJC_THREADSAFE_METHOD;

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

// use this during runApp, if you want to terminate from a signal handler
extern BOOL   UIApplicationRequestRunLoopBreak;


#define UIApplicationSizeOfSpace   (sizeof( double) * N_UIApplicationSpaceDoubles)

static inline void   *UIApplicationGetSpace( UIApplication *self, size_t expect)
{
   assert( expect <= UIApplicationSizeOfSpace);
   return( (void *) &((struct{ @defs( UIApplication); } *) self)->_space);
}
