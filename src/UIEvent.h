#import "import.h"

#include "CGGeometry.h"
#include "CATime.h"

@class UIWindow;
@class UIView;


// bits suitable or bitmasking
typedef enum
{
   UIEventTypePresses = 0x01,  // Keyboard
   UIEventTypeUnicode = 0x02,  // Unicode char (interpreted Keyboard)
   UIEventTypeTouches = 0x04,  // Mouse click
   UIEventTypeMotion  = 0x08,  // Mouse movemeent
   UIEventTypeScroll  = 0x10,  // Mouse Scrollwheel
   UIEventTypeWindow  = 0x20   // Window event (close, resize, move etc)
} UIEventType;

//
// As we are using glfw, the main object queue is in the main thread
// we retrieve objects from a central growing array of possibly used
// objects and reuse them. When we reclaim an object from a queue, we
// need to put up a memory barrier, so the receiver does not see stale
// data. An UIEvent is not read/only as _translatedPoint is used for
// storing by UIView for efficiency (temporarily used)
//
// You can turn off reuse by setting the environment variable
// MULLE_UI_REUSE_EVENTS to NO, which may come in handy for leak detection.
//
@interface UIEvent : NSObject
{
   UIWindow  *_window;   // assign  ??
   CGPoint   _translatedPoint;
   UIView    *_translatedView; // NOT READONLY!!
}

@property( assign, readonly) CGPoint   locationInWindow;

// clock() vs clock_gettime() tests on linux show, that that clock
// is 25% faster. That's IMO not enough to forego the convenience of
// CAAbsoluteTime here
@property( assign, readonly) CAAbsoluteTime   timestamp;

// current known state of modifier keys
@property( assign, readonly) uint64_t  modifiers;

+ (BOOL) reuseEvents;
+ (void) setReuseEvents:(BOOL) flag;

+ (void) waitForEvents:(double) hz;
+ (void) sendEmptyEvent;


//
// translated mouseLocation to current view bounds (ephemeral)
// set by _handleEvent:position for
//
- (CGPoint) mouseLocationInView:(UIView *) view;

- (void) _setTranslatedPoint:(CGPoint) point
                     forView:(UIView *) view;
- (CGPoint) _translatedPointForView:(UIView *) view;

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods;

@end


@interface UIEvent( Subclasses)

- (UIEventType) eventType;

@end

/*
 * Subclasses
 */

@interface UIKeyboardEvent : UIEvent

@property( assign, readonly) int   key;
@property( assign, readonly) int   scanCode;
@property( assign, readonly) int   action;

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                            key:(int) key
                       scanCode:(int) scanCode
                         action:(int) action;
@end


// Receive a OS unicode character (w/o key press)
@interface UIUnicodeEvent : UIEvent

@property( assign, readonly) int   character;

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                      character:(int) key;

@end


@interface UIMouseButtonEvent : UIEvent

@property( assign, readonly) int   button;
@property( assign, readonly) int   action;

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                         button:(int) button
                         action:(int) action;


@end


@interface UIMouseMotionEvent : UIEvent

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                   buttonStates:(uint64_t) buttonStates;

@property( assign, readonly) int   buttonStates;

@end


@interface UIMouseScrollEvent : UIEvent

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                   scrollOffset:(CGPoint) offset;

@property( assign, readonly) CGPoint   scrollOffset;

+ (CGFloat) scrollWheelAcceleration;
+ (void) setScrollWheelAcceleration:(CGFloat) value;

- (CGPoint) acceleratedScrollOffset;

@end


enum UIWindowEventType
{
   UIWindowEventTypeClose             = 0x01,
   UIWindowEventTypeRefresh           = 0x02,
   UIWindowEventTypeResize            = 0x04,
   UIWindowEventTypeMove              = 0x08,
   UIWindowEventTypeFramebufferResize = 0x10
};


@interface UIWindowEvent : UIEvent
@end


@interface UIWindowEvent( Subclasses)

- (enum UIWindowEventType) windowEventType;

@end


@interface UIWindowMoveEvent : UIWindowEvent

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                         origin:(CGPoint) pos;

@property( assign, readonly) CGPoint   origin;

@end


@interface UIWindowCloseEvent : UIWindowEvent
@end


@interface UIWindowRefreshEvent : UIWindowEvent
@end


@interface UIWindowResizeEvent : UIWindowEvent

- (instancetype) initWithWindow:(UIWindow *) window
                  mouseLocation:(CGPoint) pos
                      modifiers:(int) mods
                           size:(CGSize) size;

@property( assign, readonly) CGSize   size;

@end


@interface UIWindowFramebufferResizeEvent : UIWindowResizeEvent
@end


@interface UIEvent( OS)

+ (void) os_waitEventsTimeout:(CGFloat) seconds;
+ (void) os_pollEvents;
+ (void) os_sendEmptyEvent;

@end

