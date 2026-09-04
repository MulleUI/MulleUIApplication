//
//  UIEvent.h
//  MulleUIApplication
//
//  Copyright (c) 2018 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "import.h"

#import "UIWindowTypes.h"


// bits suitable for bitmasking
// need a way to extend this
//
typedef NS_OPTIONS( NSUInteger, UIEventType)
{                              // leave 0 to nil
   UIEventTypePresses  = 0x01,  // Keyboard
   UIEventTypeUnicode  = 0x02,  // Unicode char (interpreted Keyboard)
   UIEventTypeTouches  = 0x04,  // Mouse click
   UIEventTypeMotion   = 0x08,  // Mouse movement
   UIEventTypeScroll   = 0x10,  // Mouse Scrollwheel
   UIEventTypeWindow   = 0x20,  // Window event (close, resize, move etc)
   UIEventTypeScreen   = 0x40,  // Screen event (connect/disconnect)
   UIEventTypeGamepad  = 0x80,  // Gamepad event (connect/disconnect)
   UIEventTypeUser     = 0x100,  // User event
   UIEventTypeAction   = 0x200, // Action event (e.g. menu event)
   _UIEventTypeTimer   = 0x400,  // (This is not a real UIEvent)
   UIEventTypeTracking = 0x800 // Mouse tracking event (is this UIEventTypeMotion)
};


static inline char   *UIEventTypeUTF8String( UIEventType type)
{
   switch( type)
   {
   case UIEventTypePresses  : return( "UIEventTypePresses");
   case UIEventTypeUnicode  : return( "UIEventTypeUnicode");
   case UIEventTypeTouches  : return( "UIEventTypeTouches");
   case UIEventTypeMotion   : return( "UIEventTypeMotion");
   case UIEventTypeScroll   : return( "UIEventTypeScroll");
   case UIEventTypeWindow   : return( "UIEventTypeWindow");
   case UIEventTypeScreen   : return( "UIEventTypeScreen");
   case UIEventTypeGamepad  : return( "UIEventTypeGamepad");
   case UIEventTypeUser     : return( "UIEventTypeUser");
   case UIEventTypeAction   : return( "UIEventTypeAction");
   case _UIEventTypeTimer   : return( "_UIEventTypeTimer");
   case UIEventTypeTracking : return( "UIEventTypeTracking");
   default                  : return( "???");
   }
   assert( 0);
}


//
// As we are using glfw, the main object queue is in the main thread
// we retrieve objects from a central growing array of possibly used
// objects and reuse them. When we reclaim an object from a queue, we
// need to put up a memory barrier, so the receiver does not see stale
// data. An UIEvent is not read/only as _location is used for
// storing by UIView for efficiency (temporarily used)
//
// You can turn off reuse by setting the environment variable
// MULLE_UI_REUSE_EVENTS to NO, which may come in handy for leak detection.
//
@interface UIEvent : NSObject

// this is the time used by the render its relative to execution time
// an NSDateInterval from the start of execution
@optional
@property( dynamic, assign, readonly) mulle_absolutetime_t   timestamp;

+ (BOOL) reuseEvents;
+ (void) setReuseEvents:(BOOL) flag;

+ (void) waitForEventsTimeout:(mulle_relativetime_t) timeout;
+ (void) sendEmptyEvent;

@end



@interface UIEvent( Subclasses)

- (UIEventType) eventType;
- (BOOL) isInputEvent;

@end


//
// Only UIInputEvent events are distributed to UIViews. Might rename
// to something else, UIViewEvent maybe ?
//
// A input event is tied to the mouse pointer location.
// TODO: multiple touches (center point of touches) maybe
// TODO: keyboardEvent: last mouse pointer location, if there is
//                      mouse pointer available, then what ?
@interface UIInputEvent : UIEvent
{
   struct UIInputState   _inputState;

   //  NOT READONLY!! these values are set in _setLocation:forView:
   CGPoint               _location;
   id                    _locationView; // NOT retained!
}

@property( assign, readonly) struct UIInputState   inputState;
@property( assign, readonly) CGPoint               location;

@property( dynamic, assign, readonly) mulle_absolutetime_t   timestamp;
// access inputState;
@property( dynamic, assign, readonly) CGPoint      locationInWindow;
// this is known state of modifier keys
@property( dynamic, assign, readonly) NSUInteger   keyModifiers;
@property( dynamic, assign, readonly) NSUInteger   buttonStates;


- (instancetype) initWithInputState:(struct UIInputState *) state;

// mouseDown and initial touches are YES, default is NO
- (BOOL) isInitialEvent;
- (BOOL) isPhysicalEvent; // default returns YES, an actual user action

@end



/*
 * Subclasses.
 */

@interface UIActionEvent : UIInputEvent

@property( assign, readonly) SEL   action;
@property( assign, readonly) id    sender;

- (instancetype) initWithInputState:(struct UIInputState *) state
                             action:(SEL) action
                             sender:(id) sender;

@end


/* If you subclass any of the following:
 *
 * UIKeyboardEvent
 * UIUnicodeEvent
 * UIMouseButtonEvent
 * UIMouseMotionEvent
 * UIMouseScrollEvent
 * UIActionEvent
 *
 * Bee sure to redefine +alloc/-dealloc:
 *
 *  + (id) alloc
 * {
 *    return( NSAllocateObject( self, 0, NULL));
 * }
 *
 *
 * - (void) dealloc
 * {
 *    NSDeallocateObject( self);
 * }
 *
 */

@interface UIKeyboardEvent : UIInputEvent

@property( assign, readonly) NSUInteger   key;
@property( assign, readonly) NSUInteger   scanCode;
@property( assign, readonly) NSUInteger   action;
@property( assign, readonly) BOOL         isARepeat;

- (instancetype) initWithInputState:(struct UIInputState *) state
                                key:(NSUInteger) key
                           scanCode:(NSUInteger) scanCode
                             action:(NSUInteger) action
                          isARepeat:(BOOL) isARepeat;
@end


// Receive a OS unicode character (w/o key press)
@interface UIUnicodeEvent : UIInputEvent

@property( assign, readonly) NSUInteger   character;

- (instancetype) initWithInputState:(struct UIInputState *) state
                          character:(NSUInteger) key;

@end


@interface UIMouseButtonEvent : UIInputEvent

@property( assign, readonly) NSUInteger   button;
@property( assign, readonly) NSUInteger   action;
@property( assign, readonly) NSUInteger   clickCount;
@property( class) NSTimeInterval   doubleClickInterval;

- (instancetype) initWithInputState:(struct UIInputState *) state
                             button:(NSUInteger) button
                             action:(NSUInteger) action
                         clickCount:(NSUInteger) clickCount;

@end


@interface UIMouseMotionEvent : UIInputEvent
@end

// used by MulleUIWindow to discern "physical" events, from events
// that are "faked" to provide highlighting in animated views
@interface UIMouseMotionNonPhysicalEvent : UIMouseMotionEvent
@end


@interface UIMouseScrollEvent : UIInputEvent

@property( assign, readonly) CGPoint   scrollOffset;

// MEMO: GLFWOSWindow already has scrollWheelSensitivity!!
+ (CGFloat) scrollWheelAcceleration;
+ (void) setScrollWheelAcceleration:(CGFloat) value;

- (instancetype) initWithInputState:(struct UIInputState *) state
                       scrollOffset:(CGPoint) offset;


// useModifiers: YES
//    alt swaps axis
//    ctrl allows fine scroll
//    shift does coarse scroll
- (CGPoint) scrollOffsetWithAcceleration:(BOOL) accelerate
                            useModifiers:(BOOL) useModifiers;

@end

/*
 * Other non-input events
 */

@interface UIUserEvent : UIEvent

@property( assign, readonly) mulle_absolutetime_t   timestamp;
@property( assign, readonly) NSUInteger             eventIdentifier;

- (instancetype) initWithEventIdentifier:(NSUInteger) identifier;

@end



typedef NS_ENUM( NSUInteger, UIScreenEventType)
{
   UIScreenEventTypeConnected    = 0x01,
   UIScreenEventTypeDisconnected = 0x02
};


// static inline, because presumably its only used during debugging
// and when linking this would be force-all linked
static inline char   *UIScreenEventTypeUTF8String( UIScreenEventType type)
{
   switch( type)
   {
   case UIScreenEventTypeConnected    : return( "UIScreenEventTypeConnected");
   case UIScreenEventTypeDisconnected : return( "UIScreenEventTypeDisconnected");
   }
   assert( 0);
   return( NULL);
}


// a monitor event bears no data
@interface UIScreenEvent : UIEvent

@property( assign, readonly) mulle_absolutetime_t   timestamp;
@property( assign, readonly) UIScreenEventType      screenEventType;
@property( assign, readonly) id <UIScreen>          screen;

- (instancetype) initWithScreen:(id <UIScreen>) screen
                screenEventType:(UIScreenEventType) eventType;

@end


// these are merely presence events, actuall button/and joystick events
// are part of the InputEvent family
//
typedef NS_ENUM( NSUInteger, UIGamepadEventType)
{
   UIGamepadEventTypeConnected    = 0x01,
   UIGamepadEventTypeDisconnected = 0x02
};


// static inline, because presumably its only used during debugging
// and when linking this would be force-all linked
static inline char   *UIGamepadEventTypeUTF8String( UIGamepadEventType type)
{
   switch( type)
   {
   case UIGamepadEventTypeConnected    : return( "UIGamepadEventTypeConnected");
   case UIGamepadEventTypeDisconnected : return( "UIGamepadEventTypeDisconnected");
   }
   assert( 0);
   return( NULL);
}


// a monitor event bears no data
@interface UIGamepadEvent : UIEvent

@property( assign, readonly) mulle_absolutetime_t   timestamp;
@property( assign, readonly) UIGamepadEventType  gamepadEventType;
@property( assign, readonly) id <UIGamepad>      gamepad;

- (instancetype) initWithGamepad:(id <UIGamepad>) gamepad
                gamepadEventType:(UIGamepadEventType) eventType;

@end



typedef NS_OPTIONS( NSUInteger, UIWindowEventType)
{
   UIWindowEventTypeClose             = 0x01,
   UIWindowEventTypeRefresh           = 0x02,
   UIWindowEventTypeResize            = 0x04,
   UIWindowEventTypeMove              = 0x08,
   UIWindowEventTypeFramebufferResize = 0x10,
   UIWindowEventTypeFocusGained       = 0x20,
   UIWindowEventTypeFocusLost         = 0x40
};


// static inline, because presumably its only used during debugging
// and when linking this would be force-all linked
static inline char   *UIWindowEventTypeUTF8String( UIWindowEventType type)
{
   switch( type)
   {
   case UIWindowEventTypeClose             : return( "UIWindowEventTypeClose");
   case UIWindowEventTypeRefresh           : return( "UIWindowEventTypeRefresh");
   case UIWindowEventTypeResize            : return( "UIWindowEventTypeResize");
   case UIWindowEventTypeMove              : return( "UIWindowEventTypeMove");
   case UIWindowEventTypeFramebufferResize : return( "UIWindowEventTypeFramebufferResize");
   case UIWindowEventTypeFocusGained       : return( "UIWindowEventTypeFocusGained");
   case UIWindowEventTypeFocusLost         : return( "UIWindowEventTypeFocusLost");
   default                                 : return( "???");
   }
   assert( 0);
}


@interface UIWindowEvent : UIEvent

@property( assign, readonly) mulle_absolutetime_t   timestamp;

@end


@interface UIWindowEvent( Subclasses)

- (UIWindowEventType) windowEventType;

@end


@interface UIWindowMoveEvent : UIWindowEvent

- (instancetype) initWithOrigin:(CGPixelPoint) pos;

@property( assign, readonly) CGPixelPoint   origin;

@end


@interface UIWindowCloseEvent : UIWindowEvent
@end


@interface UIWindowRefreshEvent : UIWindowEvent
@end


@interface UIWindowFocusGainedEvent : UIWindowEvent
@end


@interface UIWindowFocusLostEvent : UIWindowEvent
@end


@interface UIWindowResizeEvent : UIWindowEvent

- (instancetype) initWithSize:(CGPixelSize) size;

@property( assign, readonly) CGPixelSize   size;

@end


@interface UIWindowFramebufferResizeEvent : UIWindowResizeEvent
@end


//
// #define GLFW_MOUSE_BUTTON_1         0
// #define GLFW_MOUSE_BUTTON_2         1
// #define GLFW_MOUSE_BUTTON_3         2
// #define GLFW_MOUSE_BUTTON_4         3
// #define GLFW_MOUSE_BUTTON_5         4
// #define GLFW_MOUSE_BUTTON_6         5
// #define GLFW_MOUSE_BUTTON_7         6
// #define GLFW_MOUSE_BUTTON_8         7
// #define GLFW_MOUSE_BUTTON_LAST      GLFW_MOUSE_BUTTON_8
// #define GLFW_MOUSE_BUTTON_LEFT      GLFW_MOUSE_BUTTON_1
// #define GLFW_MOUSE_BUTTON_RIGHT     GLFW_MOUSE_BUTTON_2
// #define GLFW_MOUSE_BUTTON_MIDDLE    GLFW_MOUSE_BUTTON_3

typedef NS_ENUM( NSUInteger, UIEventMouseButton)
{
   UIEventMouseButtonLeft   = 0x1,
   UIEventMouseButtonRight  = 0x2,
   UIEventMouseButtonMiddle = 0x4  // in polledEvents middle button is flakey!
};



// this is only for a single bit in buttons
static inline char   *_UIEventMouseButtonUTF8String( NSUInteger button)
{
   switch( button)
   {
   case UIEventMouseButtonLeft   : return( "Left");
   case UIEventMouseButtonRight  : return( "Right");
   case UIEventMouseButtonMiddle : return( "Middle");
   case 0x8                      : return( "Other");
   case 0x10                     : return( "Another");
   }
   return( NULL);
}


static inline char   *UIEventMouseButtonUTF8String( NSUInteger button)
{
   char   *s;

   s = _UIEventMouseButtonUTF8String( button);
   return( s ? s : "???");
}



//// these are not compatible to iOS but the values are 1:1 GLFW
//#define GLFW_RELEASE   0
//#define GLFW_PRESS     1
//#define GLFW_REPEAT    2


// used for mouse button and keyboard buttons
typedef NS_ENUM( NSUInteger, UIEventButtonAction)
{
   UIEventButtonActionUp     = 0,
   UIEventButtonActionDown   = 1,
   UIEventButtonActionRepeat = 2
};


static inline char   *_UIEventButtonActionUTF8String( NSUInteger action)
{
   switch( action)
   {
   case UIEventButtonActionUp     : return( "Up");
   case UIEventButtonActionDown   : return( "Down");
   case UIEventButtonActionRepeat : return( "Repeat");
   }
   return( NULL);
}


static inline char   *UIEventButtonActionUTF8String( NSUInteger action)
{
   char   *s;

   s = _UIEventButtonActionUTF8String( action);
   return( s ? s : "???");
}


// #define GLFW_MOD_SHIFT           0x0001
// #define GLFW_MOD_CONTROL         0x0002
// #define GLFW_MOD_ALT             0x0004
// #define GLFW_MOD_SUPER           0x0008
// #define GLFW_MOD_CAPS_LOCK       0x0010
// #define GLFW_MOD_NUM_LOCK        0x0020


// TODO: rename to compatible keys
typedef NS_OPTIONS( NSUInteger, UIEventKeyModifier)
{
   UIEventKeyModifierShift    = 0x0001,
   UIEventKeyModifierControl  = 0x0002,
   UIEventKeyModifierAlt      = 0x0004,
   UIEventKeyModifierSuper    = 0x0008,
   UIEventKeyModifierCapsLock = 0x0010,
   UIEventKeyModifierNumLock  = 0x0020
};


static inline char   *_UIEventKeyModifierUTF8String( NSUInteger modifier)
{
   switch( modifier)
   {
   case UIEventKeyModifierShift    : return( "Shift");
   case UIEventKeyModifierControl  : return( "Control");
   case UIEventKeyModifierAlt      : return( "Alt");
   case UIEventKeyModifierSuper    : return( "Super");
   case UIEventKeyModifierCapsLock : return( "CapsLock");
   case UIEventKeyModifierNumLock  : return( "NumLock ");
   }
   return( NULL);
}

// this is only for a single bit in modifiers
static inline char   *UIEventKeyModifierUTF8String( NSUInteger modifier)
{
   char   *s;

   s = _UIEventKeyModifierUTF8String( modifier);
   return( s ? s : "???");
}



// /* The unknown key */
// #define GLFW_KEY_UNKNOWN            -1
//
// /* Printable keys */
// #define GLFW_KEY_SPACE              32
// #define GLFW_KEY_APOSTROPHE         39  /* ' */
// #define GLFW_KEY_COMMA              44  /* , */
// #define GLFW_KEY_MINUS              45  /* - */
// #define GLFW_KEY_PERIOD             46  /* . */
// #define GLFW_KEY_SLASH              47  /* / */
// #define GLFW_KEY_0                  48
// #define GLFW_KEY_1                  49
// #define GLFW_KEY_2                  50
// #define GLFW_KEY_3                  51
// #define GLFW_KEY_4                  52
// #define GLFW_KEY_5                  53
// #define GLFW_KEY_6                  54
// #define GLFW_KEY_7                  55
// #define GLFW_KEY_8                  56
// #define GLFW_KEY_9                  57
// #define GLFW_KEY_SEMICOLON          59  /* ; */
// #define GLFW_KEY_EQUAL              61  /* = */
// #define GLFW_KEY_A                  65
// #define GLFW_KEY_B                  66
// #define GLFW_KEY_C                  67
// #define GLFW_KEY_D                  68
// #define GLFW_KEY_E                  69
// #define GLFW_KEY_F                  70
// #define GLFW_KEY_G                  71
// #define GLFW_KEY_H                  72
// #define GLFW_KEY_I                  73
// #define GLFW_KEY_J                  74
// #define GLFW_KEY_K                  75
// #define GLFW_KEY_L                  76
// #define GLFW_KEY_M                  77
// #define GLFW_KEY_N                  78
// #define GLFW_KEY_O                  79
// #define GLFW_KEY_P                  80
// #define GLFW_KEY_Q                  81
// #define GLFW_KEY_R                  82
// #define GLFW_KEY_S                  83
// #define GLFW_KEY_T                  84
// #define GLFW_KEY_U                  85
// #define GLFW_KEY_V                  86
// #define GLFW_KEY_W                  87
// #define GLFW_KEY_X                  88
// #define GLFW_KEY_Y                  89
// #define GLFW_KEY_Z                  90
// #define GLFW_KEY_LEFT_BRACKET       91  /* [ */
// #define GLFW_KEY_BACKSLASH          92  /* \ */
// #define GLFW_KEY_RIGHT_BRACKET      93  /* ] */
// #define GLFW_KEY_GRAVE_ACCENT       96  /* ` */
// #define GLFW_KEY_WORLD_1            161 /* non-US #1 */
// #define GLFW_KEY_WORLD_2            162 /* non-US #2 */
//
// /* Function keys */
// #define GLFW_KEY_ESCAPE             256
// #define GLFW_KEY_ENTER              257
// #define GLFW_KEY_TAB                258
// #define GLFW_KEY_BACKSPACE          259
// #define GLFW_KEY_INSERT             260
// #define GLFW_KEY_DELETE             261
// #define GLFW_KEY_RIGHT              262
// #define GLFW_KEY_LEFT               263
// #define GLFW_KEY_DOWN               264
// #define GLFW_KEY_UP                 265
// #define GLFW_KEY_PAGE_UP            266
// #define GLFW_KEY_PAGE_DOWN          267
// #define GLFW_KEY_HOME               268
// #define GLFW_KEY_END                269
// #define GLFW_KEY_CAPS_LOCK          280
// #define GLFW_KEY_SCROLL_LOCK        281
// #define GLFW_KEY_NUM_LOCK           282
// #define GLFW_KEY_PRINT_SCREEN       283
// #define GLFW_KEY_PAUSE              284
// #define GLFW_KEY_F1                 290
// #define GLFW_KEY_F2                 291
// #define GLFW_KEY_F3                 292
// #define GLFW_KEY_F4                 293
// #define GLFW_KEY_F5                 294
// #define GLFW_KEY_F6                 295
// #define GLFW_KEY_F7                 296
// #define GLFW_KEY_F8                 297
// #define GLFW_KEY_F9                 298
// #define GLFW_KEY_F10                299
// #define GLFW_KEY_F11                300
// #define GLFW_KEY_F12                301
// #define GLFW_KEY_F13                302
// #define GLFW_KEY_F14                303
// #define GLFW_KEY_F15                304
// #define GLFW_KEY_F16                305
// #define GLFW_KEY_F17                306
// #define GLFW_KEY_F18                307
// #define GLFW_KEY_F19                308
// #define GLFW_KEY_F20                309
// #define GLFW_KEY_F21                310
// #define GLFW_KEY_F22                311
// #define GLFW_KEY_F23                312
// #define GLFW_KEY_F24                313
// #define GLFW_KEY_F25                314
// #define GLFW_KEY_KP_0               320
// #define GLFW_KEY_KP_1               321
// #define GLFW_KEY_KP_2               322
// #define GLFW_KEY_KP_3               323
// #define GLFW_KEY_KP_4               324
// #define GLFW_KEY_KP_5               325
// #define GLFW_KEY_KP_6               326
// #define GLFW_KEY_KP_7               327
// #define GLFW_KEY_KP_8               328
// #define GLFW_KEY_KP_9               329
// #define GLFW_KEY_KP_DECIMAL         330
// #define GLFW_KEY_KP_DIVIDE          331
// #define GLFW_KEY_KP_MULTIPLY        332
// #define GLFW_KEY_KP_SUBTRACT        333
// #define GLFW_KEY_KP_ADD             334
// #define GLFW_KEY_KP_ENTER           335
// #define GLFW_KEY_KP_EQUAL           336
// #define GLFW_KEY_LEFT_SHIFT         340
// #define GLFW_KEY_LEFT_CONTROL       341
// #define GLFW_KEY_LEFT_ALT           342
// #define GLFW_KEY_LEFT_SUPER         343
// #define GLFW_KEY_RIGHT_SHIFT        344
// #define GLFW_KEY_RIGHT_CONTROL      345
// #define GLFW_KEY_RIGHT_ALT          346
// #define GLFW_KEY_RIGHT_SUPER        347
// #define GLFW_KEY_MENU               348
//
// #define GLFW_KEY_LAST               GLFW_KEY_MENU
//
typedef NS_ENUM( NSUInteger, UIEventKey)
{
/* Printable keys */
   UIEventKeySpace          = 32,

   UIEventKeyApostrophe     = 39,  /* ' */

   UIEventKeyComma          = 44,  /* , */
   UIEventKeyMinus          = 45,  /* - */
   UIEventKeyPeriod         = 46,  /* . */
   UIEventKeySlash          = 47,  /* / */
   UIEventKey0              = 48,
   UIEventKey1              = 49,
   UIEventKey2              = 50,
   UIEventKey3              = 51,
   UIEventKey4              = 52,
   UIEventKey5              = 53,
   UIEventKey6              = 54,
   UIEventKey7              = 55,
   UIEventKey8              = 56,
   UIEventKey9              = 57,

   UIEventKeySemicolon      = 59,  /* ; */

   UIEventKeyEqual          = 61,  /* = */

   UIEventKeyA              = 65,
   UIEventKeyB              = 66,
   UIEventKeyC              = 67,
   UIEventKeyD              = 68,
   UIEventKeyE              = 69,
   UIEventKeyF              = 70,
   UIEventKeyG              = 71,
   UIEventKeyH              = 72,
   UIEventKeyI              = 73,
   UIEventKeyJ              = 74,
   UIEventKeyK              = 75,
   UIEventKeyL              = 76,
   UIEventKeyM              = 77,
   UIEventKeyN              = 78,
   UIEventKeyO              = 79,
   UIEventKeyP              = 80,
   UIEventKeyQ              = 81,
   UIEventKeyR              = 82,
   UIEventKeyS              = 83,
   UIEventKeyT              = 84,
   UIEventKeyU              = 85,
   UIEventKeyV              = 86,
   UIEventKeyW              = 87,
   UIEventKeyX              = 88,
   UIEventKeyY              = 89,
   UIEventKeyZ              = 90,
   UIEventKeyLeftBracket    = 91,  /* [ */
   UIEventKeyBackslash      = 92,  /* \ */
   UIEventKeyRightBracket   = 93,  /* ] */

   UIEventKeyGraveAccent    = 96,  /* ` */

   UIEventKeyWorld1         = 161, /* non-US #1 */
   UIEventKeyWorld2         = 162, /* non-US #2 */

/* Function keys */
   UIEventKeyEscape         = 256,
   UIEventKeyEnter          = 257,
   UIEventKeyTab            = 258,
   UIEventKeyBackspace      = 259,
   UIEventKeyInsert         = 260,
   UIEventKeyDelete         = 261,
   UIEventKeyRight          = 262,
   UIEventKeyLeft           = 263,
   UIEventKeyDown           = 264,
   UIEventKeyUp             = 265,
   UIEventKeyPageUp         = 266,
   UIEventKeyPageDown       = 267,
   UIEventKeyHome           = 268,
   UIEventKeyEnd            = 269,
   UIEventKeyCapsLock       = 280,
   UIEventKeyScrollLock     = 281,
   UIEventKeyNumLock        = 282,
   UIEventKeyPrintScreen    = 283,
   UIEventKeyPause          = 284,

   UIEventKeyF1             = 290,
   UIEventKeyF2             = 291,
   UIEventKeyF3             = 292,
   UIEventKeyF4             = 293,
   UIEventKeyF5             = 294,
   UIEventKeyF6             = 295,
   UIEventKeyF7             = 296,
   UIEventKeyF8             = 297,
   UIEventKeyF9             = 298,
   UIEventKeyF10            = 299,
   UIEventKeyF11            = 300,
   UIEventKeyF12            = 301,
   UIEventKeyF13            = 302,
   UIEventKeyF14            = 303,
   UIEventKeyF15            = 304,
   UIEventKeyF16            = 305,
   UIEventKeyF17            = 306,
   UIEventKeyF18            = 307,
   UIEventKeyF19            = 308,
   UIEventKeyF20            = 309,
   UIEventKeyF21            = 310,
   UIEventKeyF22            = 311,
   UIEventKeyF23            = 312,
   UIEventKeyF24            = 313,
   UIEventKeyF25            = 314,

   UIEventKeyKeypad0        = 320,
   UIEventKeyKeypad1        = 321,
   UIEventKeyKeypad2        = 322,
   UIEventKeyKeypad3        = 323,
   UIEventKeyKeypad4        = 324,
   UIEventKeyKeypad5        = 325,
   UIEventKeyKeypad6        = 326,
   UIEventKeyKeypad7        = 327,
   UIEventKeyKeypad8        = 328,
   UIEventKeyKeypad9        = 329,
   UIEventKeyKeypadDecimal  = 330,
   UIEventKeyKeypadDivide   = 331,
   UIEventKeyKeypadMultiply = 332,
   UIEventKeyKeypadSubtract = 333,
   UIEventKeyKeypadAdd      = 334,
   UIEventKeyKeypadEnter    = 335,
   UIEventKeyKeypadEqual    = 336,

   UIEventKeyLeftShift      = 340,
   UIEventKeyLeftControl    = 341,
   UIEventKeyLeftAlt        = 342,
   UIEventKeyLeftSuper      = 343,
   UIEventKeyRightShift     = 344,
   UIEventKeyRightControl   = 345,
   UIEventKeyRightAlt       = 346,
   UIEventKeyRightSuper     = 347,
   UIEventKeyMenu           = 348
};

#define UIEventKeyUnknown   (-1)
#define UIEventKeyFirst     UIEventKeySpace
#define UIEventKeyLast      UIEventKeyMenu


static inline char   *_UIEventKeyUTF8String( NSUInteger key)
{
   switch( key)
   {
   case UIEventKeyUnknown        : return( "Unknown");
   case UIEventKeySpace          : return( "Space");
   case UIEventKeyApostrophe     : return( "Apostrophe");
   case UIEventKeyComma          : return( "Comma");
   case UIEventKeyMinus          : return( "Minus");
   case UIEventKeyPeriod         : return( "Period");
   case UIEventKeySlash          : return( "Slash");
   case UIEventKey0              : return( "0");
   case UIEventKey1              : return( "1");
   case UIEventKey2              : return( "2");
   case UIEventKey3              : return( "3");
   case UIEventKey4              : return( "4");
   case UIEventKey5              : return( "5");
   case UIEventKey6              : return( "6");
   case UIEventKey7              : return( "7");
   case UIEventKey8              : return( "8");
   case UIEventKey9              : return( "9");
   case UIEventKeySemicolon      : return( "Semicolon");
   case UIEventKeyEqual          : return( "Equal");
   case UIEventKeyA              : return( "A");
   case UIEventKeyB              : return( "B");
   case UIEventKeyC              : return( "C");
   case UIEventKeyD              : return( "D");
   case UIEventKeyE              : return( "E");
   case UIEventKeyF              : return( "F");
   case UIEventKeyG              : return( "G");
   case UIEventKeyH              : return( "H");
   case UIEventKeyI              : return( "I");
   case UIEventKeyJ              : return( "J");
   case UIEventKeyK              : return( "K");
   case UIEventKeyL              : return( "L");
   case UIEventKeyM              : return( "M");
   case UIEventKeyN              : return( "N");
   case UIEventKeyO              : return( "O");
   case UIEventKeyP              : return( "P");
   case UIEventKeyQ              : return( "Q");
   case UIEventKeyR              : return( "R");
   case UIEventKeyS              : return( "S");
   case UIEventKeyT              : return( "T");
   case UIEventKeyU              : return( "U");
   case UIEventKeyV              : return( "V");
   case UIEventKeyW              : return( "W");
   case UIEventKeyX              : return( "X");
   case UIEventKeyY              : return( "Y");
   case UIEventKeyZ              : return( "Z");
   case UIEventKeyLeftBracket    : return( "LeftBracket");
   case UIEventKeyBackslash      : return( "Backslash");
   case UIEventKeyRightBracket   : return( "RightBracket");
   case UIEventKeyGraveAccent    : return( "GraveAccent");
   case UIEventKeyWorld1         : return( "World1");
   case UIEventKeyWorld2         : return( "World2");
   case UIEventKeyEscape         : return( "Escape");
   case UIEventKeyEnter          : return( "Enter");
   case UIEventKeyTab            : return( "Tab");
   case UIEventKeyBackspace      : return( "Backspace");
   case UIEventKeyInsert         : return( "Insert");
   case UIEventKeyDelete         : return( "Delete");
   case UIEventKeyRight          : return( "Right");
   case UIEventKeyLeft           : return( "Left");
   case UIEventKeyDown           : return( "Down");
   case UIEventKeyUp             : return( "Up");
   case UIEventKeyPageUp         : return( "PageUp");
   case UIEventKeyPageDown       : return( "PageDown");
   case UIEventKeyHome           : return( "Home");
   case UIEventKeyEnd            : return( "End");
   case UIEventKeyCapsLock       : return( "CapsLock");
   case UIEventKeyScrollLock     : return( "ScrollLock");
   case UIEventKeyNumLock        : return( "NumLock");
   case UIEventKeyPrintScreen    : return( "PrintScreen");
   case UIEventKeyPause          : return( "Pause");
   case UIEventKeyF1             : return( "F1");
   case UIEventKeyF2             : return( "F2");
   case UIEventKeyF3             : return( "F3");
   case UIEventKeyF4             : return( "F4");
   case UIEventKeyF5             : return( "F5");
   case UIEventKeyF6             : return( "F6");
   case UIEventKeyF7             : return( "F7");
   case UIEventKeyF8             : return( "F8");
   case UIEventKeyF9             : return( "F9");
   case UIEventKeyF10            : return( "F10");
   case UIEventKeyF11            : return( "F11");
   case UIEventKeyF12            : return( "F12");
   case UIEventKeyF13            : return( "F13");
   case UIEventKeyF14            : return( "F14");
   case UIEventKeyF15            : return( "F15");
   case UIEventKeyF16            : return( "F16");
   case UIEventKeyF17            : return( "F17");
   case UIEventKeyF18            : return( "F18");
   case UIEventKeyF19            : return( "F19");
   case UIEventKeyF20            : return( "F20");
   case UIEventKeyF21            : return( "F21");
   case UIEventKeyF22            : return( "F22");
   case UIEventKeyF23            : return( "F23");
   case UIEventKeyF24            : return( "F24");
   case UIEventKeyF25            : return( "F25");
   case UIEventKeyKeypad0        : return( "Keypad0");
   case UIEventKeyKeypad1        : return( "Keypad1");
   case UIEventKeyKeypad2        : return( "Keypad2");
   case UIEventKeyKeypad3        : return( "Keypad3");
   case UIEventKeyKeypad4        : return( "Keypad4");
   case UIEventKeyKeypad5        : return( "Keypad5");
   case UIEventKeyKeypad6        : return( "Keypad6");
   case UIEventKeyKeypad7        : return( "Keypad7");
   case UIEventKeyKeypad8        : return( "Keypad8");
   case UIEventKeyKeypad9        : return( "Keypad9");
   case UIEventKeyKeypadDecimal  : return( "KeypadDecimal");
   case UIEventKeyKeypadDivide   : return( "KeypadDivide");
   case UIEventKeyKeypadMultiply : return( "KeypadMultiply");
   case UIEventKeyKeypadSubtract : return( "KeypadSubtract");
   case UIEventKeyKeypadAdd      : return( "KeypadAdd");
   case UIEventKeyKeypadEnter    : return( "KeypadEnter");
   case UIEventKeyKeypadEqual    : return( "KeypadEqual");
   case UIEventKeyLeftShift      : return( "LeftShift");
   case UIEventKeyLeftControl    : return( "LeftControl");
   case UIEventKeyLeftAlt        : return( "LeftAlt");
   case UIEventKeyLeftSuper      : return( "LeftSuper");
   case UIEventKeyRightShift     : return( "RightShift");
   case UIEventKeyRightControl   : return( "RightControl");
   case UIEventKeyRightAlt       : return( "RightAlt");
   case UIEventKeyRightSuper     : return( "RightSuper");
   case UIEventKeyMenu           : return( "Menu");
   }
   return( NULL);
}


char   *UIEventKeyUTF8String( NSUInteger key);


//
// Ctrl+Left Click -> Right Click emulation (macOS convention).
// Enabled by default. Set to NO to disable.
// Check this in your OS event translation layer before creating UIMouseButtonEvents.
//
MULLE_UI_APPLICATION_GLOBAL
BOOL   UIEventCtrlClickEmulatesRightClick;


static inline NSUInteger   UIEventMouseButtonWithModifiers( NSUInteger button,
                                                            NSUInteger *p_keyModifiers)
{
   if( UIEventCtrlClickEmulatesRightClick)
      if( button == UIEventMouseButtonLeft)
         if( *p_keyModifiers & UIEventKeyModifierControl)
         {
            *p_keyModifiers &= ~UIEventKeyModifierControl;
            return( UIEventMouseButtonRight);
         }
   return( button);
}


static inline NSUInteger   UIEventButtonStatesWithModifiers( NSUInteger buttonStates,
                                                             NSUInteger *p_keyModifiers)
{
   if( UIEventCtrlClickEmulatesRightClick)
      if( *p_keyModifiers & UIEventKeyModifierControl)
         if( buttonStates & UIEventMouseButtonLeft)
         {
            buttonStates &= ~UIEventMouseButtonLeft;
            buttonStates |= UIEventMouseButtonRight;
            *p_keyModifiers &= ~UIEventKeyModifierControl;
         }
   return( buttonStates);
}
