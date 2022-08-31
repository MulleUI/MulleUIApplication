#import "import.h"

//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// basically a future, that UIWindow and SDLOSWindow adopt, chiefly
// to the benefit of UIApplication, which gains a little bit of
// type safety with it and some info
//

// values for frameRate
// FPS will not be exceeded, but it's OK for the app to produce
// less frames if no change occurs
#define UIWindowFrameRateUnsynced   0.0        // as fast as possible
#define UIWindowFrameRateAsync      INFINITY   // wait until an event hits
#define UIWindowFrameRateSynced     -INFINITY  // tied to monitor frame rate (or 1/60.0 if not available)



//
// trying hard to keep enums "positive"
//
//   .-----------------------------.
//   | UIWindowStyleBare           |
//   '-----------------------------'
//   | UIWindowStyleInvisible      |
//   | UIWindowStyleTransparent    |
//   | UIWindowStyleFloating       |
//   |                             |
//   |                             |
//   |                             |
//   |                          .--.
//   '--------------------------'--'
//                               UIWindowStyleResizable

enum UIWindowStyle
{
// All
   UIWindowStyleNop                = 0x40000000, // if all bits are 0, use this to avoid getting default values

// SDL
//   UIWindowStyleClosable           = 0x001,    // there are no SDL hints for them
//   UIWindowStyleMiniaturizable     = 0x002,
   UIWindowStyleResizable          = 0x004,
   UIWindowStyleInvisible          = 0x008,
   UIWindowStyleOffscreen          = 0x010,
   UIWindowStyleSingleBuffer       = 0x020,      // glfw (maybe useful with offscreen)
   UIWindowStyleTransparent        = 0x040,
   UIWindowStyleFloating           = 0x080,
   UIWindowStyleBare               = 0x100,      // window bar, resizer gone

// CG
   UIWindowStyleEdgeAntialias      = 0x1000,     // nanvg
   UIWindowStyleStencilStrokes     = 0x2000,     // nanovg

// UIWindow
   UIWindowStyleRetained             = 0x10000,  // use UIWindowBackingStoreRetained
   UIWindowStyleRetainedOnMainThread = 0x20000,  // use UIWindowBackingStoreRetainedOnMainThread

// SDL/OpenGL
   UIWindowOpenGLCoreProfile       = 0x0100000,  // OpenGLCore functions only
   UIWindowOpenGLForward           = 0x0400000,  // non-deprecated functions only
   UIWindowOpenGLLibraryFallback   = 0x0800000,  // try other openGL libraries as fallback

   UIWindowOpenGLDeprecated        = 0x1000000   // if this is set, GLES can't be used
};



static inline NSUInteger
   UIWindowsStyleMaskByEnabling( NSUInteger styleMask, enum UIWindowStyle style)
{
   return( styleMask | style);
}


static inline NSUInteger
   UIWindowsStyleMaskByDisabling( NSUInteger styleMask, enum UIWindowStyle style)
{
   return( styleMask & ~style);
}


static inline NSUInteger
   UIWindowsStyleMaskBySetting( NSUInteger styleMask, enum UIWindowStyle style, int flag)
{
   if( flag)
      return( UIWindowsStyleMaskByEnabling( styleMask, style));
   return( UIWindowsStyleMaskByDisabling( styleMask, style));
}

typedef NSUInteger   UIWindowStyleMask;

#define UIWindowOpenGLProfileShift    (5*4)


@protocol UIOSWindow;


@protocol UIWindow < NSObject>

// return primary OSWindow this window is using (or nil if none)
// if you return nil, you may not get many events
- (id <UIOSWindow>) OSWindow;

// return underlying SDL/GLFW window or whatever
- (void *) os_window;

// obsolete ?
- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate;

- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now;

- (void) writeOSWindowPropertyChangesIfNeeded;

// the framebuffer is dirty and needs repainting, but the geometry has not
// neccesarily changed. If you have a copy of the window contents around
// just blit it
// these are threadsafe
- (void) setNeedsRefresh;
- (BOOL) shouldClose;

// sent by the application on add/remove when a window will be removed
// the application might be gone immediately afterwards if this is the
// last window (taking the graphics system with it!)
- (void) applicationDidAddWindow;
- (void) applicationDidRemoveWindow;

@end



// just like 0x800000FF for middle red, full alpha. Sparingly used...
typedef NSUInteger   UIHexColor;


@class UIEvent;
@class UIWindowEvent;

@protocol UIEventReceiver <NSObject>

- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event;
- (void) handleRetainedEvent:(UIEvent *) NS_CONSUMED event;

@end

@class NSTimer;

@protocol UITimerReceiver <NSObject>

- (void) handleRetainedTimer:(NSTimer *) NS_CONSUMED event;

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


static inline struct CGBitmapSize
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


static inline mulle_relativetime_t
   UIOSWindowInfoGetFrameRate( struct UIOSWindowInfo *info)
{
   return( info ? info->frameRate : 1.0 / 60.0);
}


static inline mulle_relativetime_t
   UIOSWindowInfoGetRefreshRate( struct UIOSWindowInfo *info)
{
   return( info ? info->refreshRate : 1.0 / 60.0);
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
      return( 1.0 / 60.0);

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
      return( 1.0 / 60.0);

      // if we use a limiter, we could make no updates for forever
   if( info->frameRateLimiter)
      frameRate = INFINITY;
   else
      frameRate = UIOSWindowInfoGetFastestFrameRate( info);

   return( frameRate);
}


@protocol UIScreen;


@protocol UIOSWindow <NSObject>

@property( assign) id <UIEventReceiver>   windowEventsReceiver;
@property( assign) id <UIEventReceiver>   eventsReceiver;
@property( assign) NSUInteger             discardEventsMask;
@property( assign) id <UIWindow>          parentWindow;  // owner UIWindow

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(NSUInteger) hints
                 sharingWindow:(id <UIOSWindow>) sharingWindow;

// a shareID. Windows with shared contexts have the same shareID
- (NSInteger) shareID;

// these are threadsafe
- (void) setFrameRateLimiter:(BOOL) flag;

// this is threadsafe
- (BOOL) frameRateLimiter;

// these are threadsafe
- (void) setFrameRate:(mulle_relativetime_t) frameRate;

// this is threadsafe
- (mulle_relativetime_t) frameRate;

// these are threadsafe
- (void) setFrameRateHz:(CGFloat) frameRateHz;

// this is threadsafe
- (CGFloat) frameRateHz;

// this is threadsafe, for OpenGL will give enum for OpenGL3, OpenGL ES etc.
- (NSUInteger) backend;

// return self
- (id <UIOSWindow>) OSWindow;

- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag;
- (id <UIScreen>) screen;


// this is threadsafe
- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info;


- (void) os_requestClose;
- (void) os_destroyWindow;

- (CGPoint) os_windowPosition;
- (void) os_setWindowPosition:(CGPoint) position;
- (CGSize) os_windowSize;
- (void) os_setWindowSize:(CGSize) size;
- (CGRect) os_windowFrame;
- (void) os_setWindowFrame:(CGRect) rect;

- (struct CGBitmapSize) os_framebufferSize;

// https://www.glfw.org/docs/latest/group__context.html#ga6d4e0cdf151b5e579bd67f13202994ed
- (void) os_setSwapInterval:(NSUInteger) value;

// bind GL context of the window to the current thread
// synonymous with activate
- (void) os_activateGraphicsContext;
- (BOOL) os_tryActivateGraphicsContext;
- (void) os_deactivateGraphicsContext;
- (void) os_swapBuffers;

- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

- (void) os_show;
- (void) os_hide;

- (void) os_initEvents;

- (void) os_setTitleUTF8String:(char *) s;
- (void) os_setCursor:(void *) cursor;

// glfw window
- (void *) os_window;

- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info;  // owner UIWindow

@end


struct mulle_pointerarray;


@protocol UIGraphicsContext <NSObject>

@property( assign) BOOL                          rendersOffScreen;
@property( assign) NSUInteger                    framebufferBits;
@property( assign) id                            OSWindow;
@property( assign, readonly) UIGraphicsBackend   backend;

- (instancetype) initWithEdgeAntialiasing:(BOOL) edgeAntialiasing
                        useStencilStrokes:(BOOL) stencilStrokes
                                  shareID:(NSUInteger) shareID
                                  backend:(UIGraphicsBackend) backend;
- (char *) backendUTF8String;

- (void) setActive:(BOOL) yes;

- (void) clearFramebufferNoColor; // keep color information
- (void) clearFramebufferWithColor:(CGColor) color;

- (void) beginRender:(struct CGFrameInfo *) info;
- (void) drawObjects:(struct mulle_pointerarray *) array;
- (void) suspendRender;
- (void) resumeRender;
- (void) _endRender;
- (void) endRender;  // calls suspendRender then endRender

// rename to something else, maybe combine and just reset
- (void) resetTransform;
- (void) resetScissor;

- (id) acquireOffscreenFramebuffer;
- (void) recycleFramebuffer:(id) layer;

- (id) shareImage:(id) framebufferImage
      withContext:(id <UIGraphicsContext>) context;

// used by UIWindow to blit...
- (void) drawRect:(CGRect) rect
            image:(id) image
            scale:(BOOL) scale;

// used by UIWindow to debug...
- (void) fillRect:(CGRect) rect
            color:(CGColor) color;

- (void) strokeRect:(CGRect) rect
              color:(CGColor) color
              width:(CGFloat) width;

- (void) drawAtPoint:(CGPoint) position
      textUTF8String:(char *) s
  fontNameUTF8String:(char *) fontNameUTF8String    // can be NULL for default
            fontSize:(CGFloat) fontSize  // can be 0.0 for default
               color:(CGColor) color;

// this is used for making screenshots
- (struct CGBitmap) readFramebufferBitmap:(struct CGBitmapRect) rect
                    framebufferBitmapType:(enum CGFramebufferBitmapType) type
                                allocator:(struct mulle_allocator *) allocator;
@end


@protocol UIImage <NSObject>

- (id) shareWithContext:(id) context;
- (CGSize) size;

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
   CGFloat                dpi;            // convenience for printing, dont use
   char                   colorBits[ 4];
   mulle_relativetime_t   refreshRate;
};


static inline double   UIScreenInfoGetPPI( struct UIScreenInfo *info)
{
   double   ppi;

   if( ! info || info->physicalSize.height == 0.0)
      return( 72.0);

   // need to convert h in mm to inches
   // https://en.wikipedia.org/wiki/Inch
   ppi = info->frame.size.height / (info->physicalSize.height * (1.0 / 25.4));
   return( ppi);
}


@protocol UIScreen <NSObject>

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
- (char *) nameUTF8String;

@end
