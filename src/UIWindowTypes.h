#import "import.h"

//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// basically a future, that UIWindow and SDLOSWindow adopt, chiefly
// to the benefit of UIApplication, which gains a little bit of
// type safety with it and some info
//

// TODO: move to MulleUIBase


// values for frameRate
// FPS will not be exceeded, but it's OK for the app to produce
// less frames if no change occurs
#define UIWindowFrameRateUnsynced   0.0        // as fast as possible
#define UIWindowFrameRateAsync      INFINITY   // wait until an event hits
#define UIWindowFrameRateSynced     -INFINITY  // tied to monitor frame rate (or 1/60.0 if not available)


char  *UIWindowFrameRateUTF8String( double frameRate);


// this constant creates 0.016677889899999999, which we then recognize more
// easily as a "default" rate.
#define UIScreenAssumedRefreshRate    (1.0 / 0.0166778899)
#define UIScreenAssumedRefreshRateHz  (1.0 / UIScreenAssumedRefreshRate)



@class UIApplication;


//
// trying hard to keep enums "positive"
//
//   .-----------------------------.
//   | UIWindowStyleBare           |
//   '-----------------------------'
//   | UIWindowStyleHidden      |
//   | UIWindowStyleTransparent    |
//   | UIWindowStyleFloating       |
//   |                             |
//   |                             |
//   |                             |
//   |                          .--.
//   '--------------------------'--'
//                               UIWindowStyleResizable

typedef NS_OPTIONS( NSUInteger, UIWindowStyle)
{
// All
   UIWindowStyleNop                  = 0x40000000, // if all bits are 0, use this to avoid getting default values

// SDL
//   UIWindowStyleClosable           = 0x0001,    // there are no SDL hints for them
//   UIWindowStyleMiniaturizable     = 0x0002,
   UIWindowStyleResizable            = 0x0004,
   UIWindowStyleHidden               = 0x0008,
   UIWindowStyleOffscreen            = 0x0010,
   UIWindowStyleSingleBuffer         = 0x0020,      // glfw (maybe useful with offscreen)
   UIWindowStyleTransparent          = 0x0040,
   UIWindowStyleFloating             = 0x0080,
   UIWindowStyleBare                 = 0x0100,      // window bar, resizer gone
   UIWindowStylePlanes               = 0x0200,
   UIWindowStyleNoView               = 0x0400,      // no UIView will be generated

// CG
   UIWindowStyleAntiAlias            = 0x00001000,     // nanovg or glfw
   UIWindowStyleForceEdgeAntiAlias   = 0x00002000,     // nanovg
   UIWindowStyleStencilStrokes       = 0x00004000,     // nanovg
   UIWindowStyleClearType            = 0x00008000,     // nanovg
   UIWindowStyleTraceDrawCalls       = 0x00010000,     // nanovg
   UIWindowStyleNoDrawing            = 0x00020000,     // nanovg

// UIWindow
   UIWindowStyleRetained             = 0x00100000,    // use UIWindowBackingStoreRetained
   UIWindowStyleRetainedOnMainThread = 0x00200000,    // use UIWindowBackingStoreRetainedOnMainThread
   UIWindowStyleProfileQueue         = 0x00400000,    // generate profile entries
   UIWindowStyleInputPolling         = 0x00800000,   // for special "X" demos

// SDL/OpenGL
   UIWindowOpenGLCoreProfile         = 0x01000000,  // OpenGLCore functions only
   UIWindowOpenGLForward             = 0x04000000,  // non-deprecated functions only
   UIWindowOpenGLLibraryFallback     = 0x08000000,  // try other openGL libraries as fallback

   UIWindowOpenGLDeprecated          = 0x10000000,   // if this is set, GLES can't be used

// Notcurses
   UIWindowNotcursesMouseDisable     = 0x20000000,  // do not use terminal mouse

// UIPureWindow
   UIWindowStyleNoDelayedShow        = 0x02000000,  // do not hide window initially; skip delayed show-after-first-swap

};


MULLE_UI_APPLICATION_GLOBAL
NS_OPTIONS_TABLE( UIWindowStyle, 21);

static inline char  *UIWindowStyleUTF8String( UIWindowStyle style)
{
   return( NS_OPTIONS_PRINT( UIWindowStyle, style));
}


static inline UIWindowStyle   UIWindowStyleParseUTF8String( char *s)
{
   return( NS_OPTIONS_PARSE( UIWindowStyle, s));
}


// UIWindowStyleSingleBuffer is no longer fully supported, since glfw/wayland
// does not support it anymore. "persistent" double buffering is also
// not supported by glfw/wayland. 


static inline NSUInteger
   UIWindowsStyleMaskByEnabling( NSUInteger styleMask, UIWindowStyle style)
{
   return( styleMask | style);
}


static inline NSUInteger
   UIWindowsStyleMaskByDisabling( NSUInteger styleMask, UIWindowStyle style)
{
   return( styleMask & ~style);
}


static inline NSUInteger
   UIWindowStyleMaskBySetting( NSUInteger styleMask, UIWindowStyle style, int flag)
{
   if( flag)
      return( UIWindowsStyleMaskByEnabling( styleMask, style));
   return( UIWindowsStyleMaskByDisabling( styleMask, style));
}

typedef NSUInteger   UIWindowStyleMask;

#define UIWindowOpenGLProfileShift    (5*4)


@protocol UIOSWindow;
@protocol UIGraphicsContext;


typedef NS_OPTIONS( NSUInteger, UIWindowDisplayBit)
{
   // user setable bits
   UIWindowDisplayNeedsRedraw     = 0x1,   // needs immediate attention
   UIWindowDisplayNeedsStyling    = 0x2,   // needs immediate attention, will force layout
   UIWindowDisplayNeedsLayout     = 0x4,   // needs immediate attention, will force redraw

   UIWindowDisplayNeedsAnimation  = 0x8,   // needs attention according to animationRate

   // this bits are set during render, they will be ignored if set by user
   UIWindowDisplayDidAnimate      = 0x10000,   // animation code did changes (will redraw next frame)
   UIWindowDisplayNeedsMouseEvent = 0x20000    // layout change needs to retrack mouse
};

typedef NSUInteger   UIWindowDisplayBits;

// this is only for a single bit in buttons
static inline char   *_UIWindowDisplayBitUTF8String( NSUInteger bit)
{
   switch( bit)
   {
   case UIWindowDisplayNeedsRedraw     : return( "NeedsRedraw");
   case UIWindowDisplayNeedsStyling    : return( "NeedsStyling");
   case UIWindowDisplayNeedsLayout     : return( "NeedsLayout");
   case UIWindowDisplayNeedsAnimation  : return( "NeedsAnimation");
   case UIWindowDisplayDidAnimate      : return( "DidAnimate");
   case UIWindowDisplayNeedsMouseEvent : return( "NeedsMouseEvent");
   }
   return( NULL);
}


static inline char   *UIWindowDisplayBitUTF8String( NSUInteger bit)
{
   char   *s;

   s = _UIWindowDisplayBitUTF8String( bit);
   return( s ? s : "???");
}

MULLE_UI_APPLICATION_GLOBAL
char  *UIWindowDisplayBitsUTF8String( NSUInteger displayBits);


@protocol UIWindowLayoutDelegate

- (UIWindowDisplayBits) willLayoutWithAbsoluteTime:(mulle_absolutetime_t) renderStart;

@end


@class UIEvent;
@class UIWindowEvent;

@protocol UIEventReceiver <NSObject>

- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event   MULLE_OBJC_THREADSAFE_METHOD;
- (void) receiveRetainedEvent:(UIEvent *) NS_CONSUMED event     MULLE_OBJC_THREADSAFE_METHOD;

@end

@class NSTimer;

@protocol UITimerReceiver <NSObject>

- (void) handleRetainedTimer:(NSTimer *) NS_CONSUMED event     MULLE_OBJC_THREADSAFE_METHOD;

@end


@protocol UIWindow < MulleUINamedObject, UIEventReceiver>

@property( assign, readonly) id <UIGraphicsContext>  renderGraphicsContext;

// return primary OSWindow this window is using (or nil if none)
// if you return nil, you may not get many events
- (id <UIOSWindow>) OSWindow  MULLE_OBJC_THREADSAFE_METHOD;

// return underlying SDL/GLFW window or whatever
- (void *) os_window          MULLE_OBJC_THREADSAFE_METHOD;

// obsolete ?
//- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate;

//
// this method must be called from the main thread only
// in this sense its threadsafe, because other threads abort
//
- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now   MULLE_OBJC_THREADSAFE_METHOD;

- (void) syncOSWindowPropertyChangesIfNeeded                              MULLE_OBJC_THREADSAFE_METHOD;

// the framebuffer is dirty and needs repainting, but the geometry has not
// neccesarily changed. If you have a copy of the window contents around
// just blit it
// these are threadsafe
- (void) setNeedsRefresh   MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) shouldClose       MULLE_OBJC_THREADSAFE_METHOD;

// sent by the application on add/remove when a window will be removed
// the application might be gone immediately afterwards if this is the
// last window (taking the graphics system with it!)
// Implementators should assert, that its called from main thread only
- (void) applicationDidAddWindow:(UIApplication *) app      MULLE_OBJC_THREADSAFE_METHOD;
- (void) applicationDidRemoveWindow:(UIApplication *) app   MULLE_OBJC_THREADSAFE_METHOD;

- (id) firstResponder;

- (char *) pasteboardCString;
- (void) setPasteboardCString:(char *) s;

@end


struct UIOSWindowInfo
{
   struct CGWindowInfo    base;
   mulle_relativetime_t   frameRate;
   mulle_relativetime_t   refreshRate;
   BOOL                   frameRateLimiter;
};


static inline struct CGRect
   UIOSWindowInfoGetFrame( struct UIOSWindowInfo *info)
{
   return( CGWindowInfoGetFrame( info ? &info->base : NULL));
}


static inline CGPixelSize
   UIOSWindowInfoGetFramebufferSize( struct UIOSWindowInfo *info)
{
   return( CGWindowInfoGetFramebufferSize( info ? &info->base : NULL));
}


static inline struct CGVector
   UIOSWindowInfoGetUIScale( struct UIOSWindowInfo *info)
{
   return( CGWindowInfoGetUIScale( info ? &info->base : NULL));
}


static inline double
   UIOSWindowInfoGetPixelRatio( struct UIOSWindowInfo *info)
{
   return( CGWindowInfoGetPixelRatio( info ? &info->base : NULL));
}

// TODO: explain that frameRate is the rate that we are pushing to the screen
//       and that refreshRate is the swap rate of the screen itself ()
static inline mulle_relativetime_t
   UIOSWindowInfoGetFrameRate( struct UIOSWindowInfo *info)
{
   return( info ? info->frameRate : UIScreenAssumedRefreshRate);
}


static inline mulle_relativetime_t
   UIOSWindowInfoGetRefreshRate( struct UIOSWindowInfo *info)
{
   return( info ? info->refreshRate : UIScreenAssumedRefreshRate);
}


static inline BOOL
   UIOSWindowInfoGetFrameRateLimiter( struct UIOSWindowInfo *info)
{
   return( info ? info->frameRateLimiter : NO);
}



// UIWindowFrameRateAsync    : INFINITY
// UIWindowFrameRateSynced   : refreshRate
// UIWindowFrameRateUnsynced : 0.0
// other                     : other
static inline mulle_relativetime_t
   UIOSWindowInfoGetFastestFrameRate( struct UIOSWindowInfo *info)
{
   mulle_relativetime_t   frameRate;

   if( ! info)
      return( UIScreenAssumedRefreshRate);

   frameRate = info->frameRate;
   if( frameRate == UIWindowFrameRateSynced)
      frameRate = info->refreshRate;

   return( frameRate);
}


// UIWindowFrameRateAsync    : INFINITY
// UIWindowFrameRateSynced   : frameLimiter ? INFINITY : refreshRate
// UIWindowFrameRateUnsynced : 0.0
// other                     : frameLimiter ? INFINITY : other
static inline mulle_relativetime_t
   UIOSWindowInfoGetSlowestFrameRate( struct UIOSWindowInfo *info)
{
   mulle_relativetime_t   frameRate;

   if( ! info)
      return( UIScreenAssumedRefreshRate);

   // if we use a limiter, we could make no updates for forever
   if( info->frameRateLimiter)
      frameRate = INFINITY;
   else
      frameRate = UIOSWindowInfoGetFastestFrameRate( info);

   return( frameRate);
}


@protocol UIScreen;
@protocol UIGamepad;

@class UIWindowEvent;
@class UIEvent;


typedef void   (*UIOSWindowEventCallback_t)( id <UIOSWindow> window, UIWindowEvent *event);
typedef void   (*UIOSWindowRetainedEventCallback_t)( id <UIOSWindow> window, UIEvent *retainedEvent);

typedef UIWindowDisplayBits   (*UIOSWindowFrameCallback_t)( id <UIOSWindow> window);

//
// Keep this layout in sync with backend-specific graphics hint structs
// (currently GLFWGraphicsHints). The shared encoding avoids selector
// signature mismatches for -initWithFrame:...graphicsHints:sharingWindow:.
//
typedef struct
{
   unsigned int   profile   : 2;
   unsigned int   forward   : 1;
   unsigned int   api       : 3;
   unsigned int   lib       : 2;
   unsigned int   major     : 8;
   unsigned int   minor     : 8;

   unsigned int   software  : 1;
   unsigned int   dri_prime : 4;

   const char    *glx_vendor;
   const char    *driver;
   const char    *lib_path;
   const char    *egl_vendor;
} UIOSWindowGraphicsHints;


@protocol UIOSWindow <MulleUINamedObject, UIOSGraphicsContext>

@property( assign) id <UIEventReceiver>   windowEventsReceiver;
@property( assign) id <UIEventReceiver>   eventsReceiver;
@property( assign) NSUInteger             discardEventsMask;
@property( assign) id <UIWindow>          parentWindow;  // owner UIWindow

@property( readonly, getter=isAntiAliasing) BOOL     antiAliasing;

// default: GLFWOSWindowEventDefaultCallback
@property( assign) UIOSWindowEventCallback_t         windowEventsCallback;
// default: GLFWOSWindowRetainedEventDefaultCallback
@property( assign) UIOSWindowRetainedEventCallback_t otherRetainedEventsCallback;
//
// very basic rendering and event support. Does not use CGContext!
// view port is not setup and framebuffer is not cleared!
@property( assign) UIOSWindowFrameCallback_t         frameCallback;
@property( readonly) struct UIInputState             inputState;


- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(UIOSWindowGraphicsHints) hints
                 sharingWindow:(id <UIOSWindow>) sharingWindow;

// a shareID. Windows with sharing contexts have the same shareID
- (NSInteger) shareID;

// these are threadsafe
- (void) setFrameRateLimiter:(BOOL) flag  MULLE_OBJC_THREADSAFE_METHOD;

// this is threadsafe
- (BOOL) frameRateLimiter                 MULLE_OBJC_THREADSAFE_METHOD;

// these are threadsafe
- (void) setFrameRate:(mulle_relativetime_t) frameRate   MULLE_OBJC_THREADSAFE_METHOD;

// this is threadsafe
- (mulle_relativetime_t) frameRate              MULLE_OBJC_THREADSAFE_METHOD;

// these are threadsafe
- (void) setFrameRateHz:(CGFloat) frameRateHz   MULLE_OBJC_THREADSAFE_METHOD;

// this is threadsafe
- (CGFloat) frameRateHz                         MULLE_OBJC_THREADSAFE_METHOD;

// this is threadsafe, for OpenGL will give enum for OpenGL3, OpenGL ES etc.
- (NSUInteger) backend                          MULLE_OBJC_THREADSAFE_METHOD;

// return self
- (id <UIOSWindow>) OSWindow;

- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag;
- (id <UIScreen>) screen;

- (mulle_absolutetime_t) lastSwapBuffersTimestamp;

// this is threadsafe
- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info  MULLE_OBJC_THREADSAFE_METHOD;

- (NSThread *) activeThread                              MULLE_OBJC_THREADSAFE_METHOD;


// https://www.glfw.org/docs/latest/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
- (void) os_setSwapInterval:(NSUInteger) value           MULLE_OBJC_THREADSAFE_METHOD;

// bind GL context of the window to the current thread
// synonymous with activate
- (void) os_activateGraphicsContext;
- (BOOL) os_tryActivateGraphicsContext;
- (void) os_deactivateGraphicsContext;
- (void) os_swapBuffers;

- (void) os_requestClose                          MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) os_windowShouldClose                     MULLE_OBJC_THREADSAFE_METHOD;

- (void) os_show                                  MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_hide                                  MULLE_UI_MAIN_THREAD_ONLY;

- (CGPoint) os_windowPosition                     MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_setWindowPosition:(CGPoint) position  MULLE_UI_MAIN_THREAD_ONLY;
- (CGSize) os_windowSize                          MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_setWindowSize:(CGSize) size           MULLE_UI_MAIN_THREAD_ONLY;
- (CGRect) os_windowFrame                         MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_setWindowFrame:(CGRect) rect          MULLE_UI_MAIN_THREAD_ONLY;
- (CGPixelSize) os_framebufferSize    MULLE_UI_MAIN_THREAD_ONLY;

- (void) os_initEvents                            MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_finalizeEvents                        MULLE_UI_MAIN_THREAD_ONLY;

- (void) os_setTitleUTF8String:(char *) s         MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_setCursor:(void *) cursor             MULLE_UI_MAIN_THREAD_ONLY;
- (void) os_setCursorCaptured:(BOOL) captured     MULLE_UI_MAIN_THREAD_ONLY;

- (void) os_pollInputState:(struct UIInputState *) state   MULLE_UI_MAIN_THREAD_ONLY;

// returns number of currently pressed keys (up to count)
// keys are UIEventKey values, polls from OS directly
- (NSUInteger) os_pressedKeys:(NSUInteger *) keys
                        count:(NSUInteger) count  MULLE_UI_MAIN_THREAD_ONLY;

// returns number of currently pressed keys (up to count)
// maintained from key events, resynced on focus regain (cheap, no OS call)
- (NSUInteger) pressedKeys:(NSUInteger *) keys
                     count:(NSUInteger) count;

// glfw window
- (void *) os_window                              MULLE_OBJC_THREADSAFE_METHOD;


@end


struct mulle_pointerarray;
struct CGPath;


@protocol UIImage < MulleUINamedObject>


- (Class) preferredImageLayerClass;
- (CGSize) size;
- (BOOL) isMultiSample;

@end


// this is an abstraction on CGFramebuffer, but UILayer is already in use because
// of CALayer, and we probably gonna rename CGFramebuffer to CGFramebuffer anyway
@protocol UIFramebuffer < MulleUINamedObject>
@end


typedef NS_OPTIONS( NSUInteger, UIGraphicsContextState)
{
   UIGraphicsContextAssociated = 0x1,    // associated with current thread
   UIGraphicsContextActive     = 0x2     // also has active OpenGL context
};



@protocol UIGraphicsContext < MulleUINamedObject>

@property( assign) BOOL                          rendersOffScreen;
@property( assign) NSUInteger                    framebufferBits;
@property( assign) struct UIInputState           inputState        MULLE_OBJC_THREADSAFE_PROPERTY;
@property( readonly) NSUInteger                  debuggingFlags    MULLE_OBJC_THREADSAFE_PROPERTY;
@property( readonly) char                        *nameUTF8String   MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign, readonly) id <UIOSGraphicsContext> OSWindow     MULLE_OBJC_THREADSAFE_PROPERTY;
@property( assign, readonly) UIGraphicsBackend   backend;
@property( assign, getter=isInitializedFramebuffer) BOOL   initializedFramebuffer;
@property( assign) UIGraphicsContextState        state; // UIGraphicsContextState

+ (BOOL) supportsAntiAliasing;

- (instancetype) initWithOSGraphicsContext:(id <UIOSGraphicsContext>) osContext
                            nameUTF8String:(char *) nameUTF8String
                                   shareID:(NSUInteger) shareID
                                   options:(UIGraphicsOptions) options;

- (instancetype) initWithOSGraphicsContext:(id <UIOSGraphicsContext>) window
                                   shareID:(NSUInteger) shareID
                                   options:(UIGraphicsOptions) options;
                                 
- (char *) backendUTF8String;

- (NSThread *) activeThread      MULLE_OBJC_THREADSAFE_METHOD;     // wo set it active

- (BOOL) needsFramebufferClear;
- (void) clearFramebufferNoColor; // keep color information
- (void) clearFramebufferWithHexColor:(NSUInteger) color;        // black all zero

- (void) useDefaultFont;

// no CGColor here yet..
//- (void) clearFramebufferWithColor:(CGColor) color;

- (void) beginRender:(struct CGFrameInfo *) info;
- (void) renderObjects:(struct mulle_pointerarray *) array;
- (void) suspendRender;
- (void) resumeRender;
- (void) _endRender;
- (void) endRender;  // calls suspendRender then endRender

// rename to something else, maybe combine and just reset
- (void) reset;

//
// These methods can not be called from the activeThread of the context.
// They are used to move a framebuffer from and to a differen thread, also the
// framebuffer will cease being a resource of the context or will be readded
// to the resources.
//
- (id) acquireRenderedFramebuffer        MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) recycleAcquiredRenderedFramebuffer:(id) layer    MULLE_OBJC_THREADSAFE_METHOD;

//- (id) shareImage:(id) framebufferImage
//      withContext:(id <UIGraphicsContext>) context;

// this is used for making screenshots
- (struct CGBitmap) readFramebufferBitmap:(CGPixelRect) rect
                    framebufferBitmapType:(CGFramebufferBitmapType) type
                                allocator:(struct mulle_allocator *) allocator;

- (void) barrier;

// first frame is 0
- (NSUInteger) numberOfFrames;

// screenshot, bitmap is a copy
- (struct CGBitmap) framebufferBitmap;


// the most basic drawing commands

- (void) setCompositionMode:(UIGraphicsCompositionMode) mode;

// only useable until the offscreen renderer hits again (?=)
- (void) drawBitmap:(struct CGBitmap) fb;

// used by UIWindow to blit...
- (void) drawRect:(CGRect) rect
            image:(id) image
            scale:(BOOL) scale;

- (id <UIImage>) imageWithFramebuffer:(id <UIFramebuffer>) layer
                       nameUTF8String:(char *) nameUTF8String;

// support for some demos
- (CGPoint) mouseLocation             MULLE_OBJC_THREADSAFE_METHOD;
- (NSUInteger) keyModifiers           MULLE_OBJC_THREADSAFE_METHOD;
- (NSUInteger) buttonStates           MULLE_OBJC_THREADSAFE_METHOD;
- (struct UIKeyStates) keyStates      MULLE_OBJC_THREADSAFE_METHOD;

// TODO: keep this, delete others
- (struct UIInputState) inputState    MULLE_OBJC_THREADSAFE_METHOD;

@end



@protocol UIDrawingContext < MulleUINamedObject>

- (BOOL) drawInContext:(id <UIDrawingContext>) context;

@end


//
// Use CGRect from frame/canvas since it's more uniform with UIWindow/UIView
// though the underlying OS/SDL format is really integer
//
struct UIScreenInfo
{
   CGRect                 frame;
   CGRect                 canvas;         // workarea
   CGVector               contentScale;
   CGSize                 physicalSize;
   CGFloat                dpi;
   char                   colorBits[ 4];
   mulle_relativetime_t   refreshRate;
};


static inline double   UIScreenInfoGetPPI( struct UIScreenInfo *info)
{
   if( ! info || info->dpi == 0.0)
      return( 72.0);
   return( info->dpi);
}


@protocol UIScreen < MulleUINamedObject>

// threadSafe, though of course the screenAtIndex: call is not guaranteed
// to operate on the same numberOfScreens since, that could have changed
+ (NSUInteger) numberOfScreens;

// returns nil, if none at index, threadSafe
+ (id <UIScreen>) screenAtIndex:(NSUInteger) i;

// this is thread safe
- (void) getScreenInfo:(struct UIScreenInfo *) info;

// this is thread safe
- (mulle_relativetime_t) refreshRate;
- (CGRect) frame;
- (CGRect) canvas;

@end


#define UIGamepadInfoMaxButtons  32    // 32 buttons (A B X Y)
#define UIGamepadInfoMaxAxes     6     // two analog sticks
#define UIGamepadInfoMaxSticks   4     // four digital sticks (hats) why not

//
// 24 bytes axes
// 32 bytes buttons
//  4 bytes sticks
//  3 bytes number
//  1 byte isJoystick
//
// 64 bytes total
//
struct UIGamepadInfo
{
   float            axes[ UIGamepadInfoMaxAxes];         // 2 * 3D
   unsigned char    buttons[ UIGamepadInfoMaxButtons];   // BOOL
   unsigned char    sticks[ UIGamepadInfoMaxSticks];     // CADirection

   unsigned char    numberOfSticks;    // standard digital joysticks
   unsigned char    numberOfButtons;   // on off buttons
   unsigned char    numberOfAxes;      // standard analog joystick axes (3 per)
   char             isJoystick;
};


// values like GLFW (but Dpad is in sticks and not duplicated in buttons)
typedef NS_ENUM( NSUInteger, UIGamepadButton)
{
   UIGamepadButtonA           = 0,
   UIGamepadButtonB           = 1,
   UIGamepadButtonX           = 2,
   UIGamepadButtonY           = 3,
   UIGamepadButtonLeftBumper  = 4,
   UIGamepadButtonRightBumper = 5,
   UIGamepadButtonBack        = 6,
   UIGamepadButtonStart       = 7,
   UIGamepadButtonGuide       = 8,
   UIGamepadButtonLeftThumb   = 9,
   UIGamepadButtonRightThumb  = 10,
   UIGamepadButtonCross       = UIGamepadButtonA,
   UIGamepadButtonCircle      = UIGamepadButtonB,
   UIGamepadButtonSquare      = UIGamepadButtonX,
   UIGamepadButtonTriangle    = UIGamepadButtonY
};

//
// if you use a variable for button, then wrap this in a function
//
static inline BOOL   UIGamepadInfoGetButton( struct UIGamepadInfo *info,
                                             UIGamepadButton button)
{
   assert( button < UIGamepadInfoMaxButtons);
   return( info->buttons[ button]);
}


static inline CADirection   UIGamepadInfoGetDigitalStick( struct UIGamepadInfo *info,
                                                          NSUInteger index)
{
   assert( index < UIGamepadInfoMaxSticks);

   return( (CADirection) info->sticks[ index]);
}


static inline CADirection   UIGamepadInfoGetDPad( struct UIGamepadInfo *info)
{
   return( UIGamepadInfoGetDigitalStick( info, 0));
}


static inline BOOL   UIGamepadInfoIsJoystick( struct UIGamepadInfo *info)
{
   return( info->isJoystick);
}



static inline void   UIGamepadInfoGetAnalogStick( struct UIGamepadInfo *info,
                                                  NSUInteger index,
                                                  float  axes[ 3])
{
   assert( index == 0 || index == 1);

   axes[ 0] = info->axes[ 0 + index * 3];
   axes[ 1] = info->axes[ 1 + index * 3];
   axes[ 2] = info->axes[ 2 + index * 3];
}



@protocol UIGamepad < MulleUINamedObject>

@property( readonly) char        *guidUTF8String;

@property( readonly) BOOL        isJoystick;
@property( readonly) NSInteger   osIndex;

// returns nil, the osIndex is not the same as the index used by
// UIApplication, because UIApplication ensures 0-... where as GLFW
// produces holes, because non-gamepads are also in there which need to
// be filtered out
+ (id <UIGamepad>) gamepadAtOSIndex:(NSUInteger) i;
+ (NSRange) osIndexRange;

// this is thread safe. it is slightly faster (less locking) if you query
// the UIGamepadInfo with the C functions above
- (void) getGamepadInfo:(struct UIGamepadInfo *) info    MULLE_OBJC_THREADSAFE_METHOD;



// convenience interface
- (CADirection) direction                                MULLE_OBJC_THREADSAFE_METHOD;
- (BOOL) stateOfGamepadButton:(UIGamepadButton) button   MULLE_OBJC_THREADSAFE_METHOD;

- (BOOL) getAnalogStickWithIndex:(NSUInteger) index
                            axes:(float [ 3]) axes       MULLE_OBJC_THREADSAFE_METHOD;

- (BOOL) getDigitalStickWithIndex:(NSUInteger) index
                        direction:(CADirection *) direction  MULLE_OBJC_THREADSAFE_METHOD;

- (void) os_pollGamepadInfo;

@end
