#import "import.h"

#import "UIWindowTypes.h"


// bits suitable for bitmasking
// need a way to extend this
//
enum UIEventType
{                              // leave 0 to nil
   UIEventTypePresses = 0x01,  // Keyboard
   UIEventTypeUnicode = 0x02,  // Unicode char (interpreted Keyboard)
   UIEventTypeTouches = 0x04,  // Mouse click
   UIEventTypeMotion  = 0x08,  // Mouse movemeent
   UIEventTypeScroll  = 0x10,  // Mouse Scrollwheel
   UIEventTypeWindow  = 0x20,  // Window event (close, resize, move etc)
   UIEventTypeScreen  = 0x40,  // Screen event
   UIEventTypeUser    = 0x80   // User event
};

static inline char   *UIEventTypeUTF8String( enum UIEventType type)
{
   switch( type)
   {
   case UIEventTypePresses : return( "UIEventTypePresses");
   case UIEventTypeUnicode : return( "UIEventTypeUnicode");
   case UIEventTypeTouches : return( "UIEventTypeTouches");
   case UIEventTypeMotion  : return( "UIEventTypeMotion");
   case UIEventTypeScroll  : return( "UIEventTypeScroll");
   case UIEventTypeWindow  : return( "UIEventTypeWindow");
   case UIEventTypeScreen  : return( "UIEventTypeScreen");
   case UIEventTypeUser    : return( "UIEventTypeUser");
   }
}


typedef NSUInteger   UIEventType;
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

// this is the time used by the render its relative to execution time
// an NSDateInterval from the start of execution
@property( assign, readonly) mulle_absolutetime_t   timestamp;

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
@interface UIInputEvent : UIEvent
{
   CGPoint   _translatedPoint;
   id        _translatedView; // NOT READONLY!!
}

@property( assign, readonly) CGPoint     locationInWindow;

// this is thown state of modifier keys
@property( assign, readonly) NSUInteger  modifiers;


// TODO: rename to LocationInWindow or LocationInRootView ?
- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods;
@end



/*
 * Subclasses
 */

@interface UIUserEvent : UIEvent

@property( assign, readonly) NSUInteger   eventIdentifier;

- (instancetype) initWithEventIdentifier:(NSUInteger) identifier;
@end


@interface UIKeyboardEvent : UIInputEvent

@property( assign, readonly) NSUInteger   key;
@property( assign, readonly) NSUInteger   scanCode;
@property( assign, readonly) NSUInteger   action;

- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods
                                   key:(NSUInteger) key
                              scanCode:(NSUInteger) scanCode
                                action:(NSUInteger) action;
@end


// Receive a OS unicode character (w/o key press)
@interface UIUnicodeEvent : UIInputEvent

@property( assign, readonly) NSUInteger   character;

- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods
                             character:(NSUInteger) key;

@end


@interface UIMouseButtonEvent : UIInputEvent

@property( assign, readonly) NSUInteger   button;
@property( assign, readonly) NSUInteger   action;

- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods
                                button:(NSUInteger) button
                                action:(NSUInteger) action;


@end


@interface UIMouseMotionEvent : UIInputEvent

- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods
                          buttonStates:(NSUInteger) buttonStates;

@property( assign, readonly) NSUInteger   buttonStates;

@end


@interface UIMouseScrollEvent : UIInputEvent

- (instancetype) initWithMouseLocation:(CGPoint) pos
                             modifiers:(NSUInteger) mods
                          scrollOffset:(CGPoint) offset;

@property( assign, readonly) CGPoint   scrollOffset;

// MEMO: GLFWOSWindow already has scrollWheelSensitivity!!
+ (CGFloat) scrollWheelAcceleration;
+ (void) setScrollWheelAcceleration:(CGFloat) value;

- (CGPoint) acceleratedScrollOffset;

@end


enum UIScreenEventType
{
   UIScreenEventTypeConnected    = 0x01,
   UIScreenEventTypeDisconnected = 0x02
};


// static inline, because presumably its only used during debugging
// and when linking this would be force-all linked
static inline char   *UIScreenEventTypeUTF8String( enum UIScreenEventType type)
{
   switch( type)
   {
   case UIScreenEventTypeConnected    : return( "UIScreenEventTypeConnected");
   case UIScreenEventTypeDisconnected : return( "UIScreenEventTypeDisconnected");
   }
}


// a monitor event bears no data
@interface UIScreenEvent : UIEvent

@property( assign, readonly) enum UIScreenEventType  screenEventType;
@property( assign, readonly) id <UIScreen>           screen;

- (instancetype) initWithScreen:(id <UIScreen>) screen
                screenEventType:(enum UIScreenEventType) eventType;

@end



enum UIWindowEventType
{
   UIWindowEventTypeClose             = 0x01,
   UIWindowEventTypeRefresh           = 0x02,
   UIWindowEventTypeResize            = 0x04,
   UIWindowEventTypeMove              = 0x08,
   UIWindowEventTypeFramebufferResize = 0x10
};


// static inline, because presumably its only used during debugging
// and when linking this would be force-all linked
static inline char   *UIWindowEventTypeUTF8String( enum UIWindowEventType type)
{
   switch( type)
   {
   case UIWindowEventTypeClose             : return( "UIWindowEventTypeClose");
   case UIWindowEventTypeRefresh           : return( "UIWindowEventTypeRefresh");
   case UIWindowEventTypeResize            : return( "UIWindowEventTypeResize");
   case UIWindowEventTypeMove              : return( "UIWindowEventTypeMove");
   case UIWindowEventTypeFramebufferResize : return( "UIWindowEventTypeFramebufferResize");
   }
}

@interface UIWindowEvent : UIEvent
@end


@interface UIWindowEvent( Subclasses)

- (enum UIWindowEventType) windowEventType;

@end


@interface UIWindowMoveEvent : UIWindowEvent

- (instancetype) initWithOrigin:(struct CGBitmapPoint) pos;

@property( assign, readonly) struct CGBitmapPoint   origin;

@end


@interface UIWindowCloseEvent : UIWindowEvent
@end


@interface UIWindowRefreshEvent : UIWindowEvent
@end


@interface UIWindowResizeEvent : UIWindowEvent

- (instancetype) initWithSize:(struct CGBitmapSize) size;

@property( assign, readonly) struct CGBitmapSize   size;

@end


@interface UIWindowFramebufferResizeEvent : UIWindowResizeEvent
@end



@interface UIEvent( OS)

+ (void) os_waitEventsWithTimeout:(mulle_relativetime_t) seconds;
+ (void) os_pollEvents;
+ (void) os_sendEmptyEvent;

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

enum
{
   UIEventMouseButtonLeft   = 1,
   UIEventMouseButtonMiddle = 2,
   UIEventMouseButtonRight  = 3
};


// these are not compatible to iOS but the values are 1:1 GLFW
#define GLFW_RELEASE   0
#define GLFW_PRESS     1
#define GLFW_REPEAT    2


// used for mouse button and keyboard buttons
enum
{
   UIEventButtonUp     = 0,
   UIEventButtonDown   = 1,
   UIEventButtonRepeat = 2
};




// #define GLFW_MOD_SHIFT           0x0001
// #define GLFW_MOD_CONTROL         0x0002
// #define GLFW_MOD_ALT             0x0004
// #define GLFW_MOD_SUPER           0x0008
// #define GLFW_MOD_CAPS_LOCK       0x0010
// #define GLFW_MOD_NUM_LOCK        0x0020

enum
{
   UIEventKeyModifierShift    = 0x0001,
   UIEventKeyModifierControl  = 0x0002,
   UIEventKeyModifierAlt      = 0x0004,
   UIEventKeyModifierSuper    = 0x0008,
   UIEventKeyModifierCapsLock = 0x0010,
   UIEventKeyModifierNukLock  = 0x0020
};


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
enum
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

   UIEventKeyLeftAhift      = 340,
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
