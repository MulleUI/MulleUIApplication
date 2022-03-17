#import "import.h"

//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// basically a future, that UIWindow and GLFWOSWindow adopt, chiefly
// to the benefit of UIApplication, which gains a little bit of
// type safety with it and some info
//

// values for frameRate
// FPS will not be exceeded, but it's OK for the app to produce
// less frames if no change occurs
#define UIWindowFrameRateUnsynced   0.0        // as fast as possible
#define UIWindowFrameRateAsync      INFINITY   // wait until an event hits
#define UIWindowFrameRateSynced     -INFINITY  // tied to monitor frame rate (or 1/60.0 if not available)



@protocol UIWindow < NSObject>

@property( assign) double   frameRate;

- (void) eventHandlingWithFrameRate:(mulle_relativetime_t) frameRate;

- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now;

- (void) writeOSWindowPropertyChangesIfNeeded;

// the framebuffer is dirty and needs repainting, but the geometry has not
// neccesarily changed. If you have a copy of the window contents around
// just blit it
- (void) setNeedsRefresh;
- (BOOL) shouldClose;

- (double) fastestFrameRate;

@end


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

// GLFW
//   UIWindowStyleClosable           = 0x001,   // there are no GLFW hints for them
//   UIWindowStyleMiniaturizable     = 0x002,
   UIWindowStyleResizable          = 0x004,
   UIWindowStyleInvisible          = 0x008,
   UIWindowStyleOffscreen          = 0x010,
   UIWindowStyleSingleBuffer       = 0x020, // glfw (maybe useful with offscreen)
   UIWindowStyleTransparent        = 0x040,
   UIWindowStyleFloating           = 0x080,
   UIWindowStyleBare               = 0x100,  // window bar, resizer gone

// CG
   UIWindowStyleEdgeAntialias      = 0x1000,   // nanvg
   UIWindowStyleStencilStrokes     = 0x2000,   // nanovg

// UIWindow
   UIWindowStyleRetained             = 0x10000,  // use UIWindowBackingStoreRetained
   UIWindowStyleRetainedOnMainThread = 0x20000,  // use UIWindowBackingStoreRetainedOnMainThread

// GLFW/OpenGL
   UIWindowOpenGLCoreProfile       = 0x0100000,
   UIWindowOpenGLCompatProfile     = 0x0200000,
   UIWindowOpenGLForwardCompatible = 0x0400000,  // folklore says, specify compat too

   UIWindowOpenGLLibraryFallback   = 0x0800000,  // try other openGL libraries as fallback
   UIWindowOpenGLDeprecated        = 0x1000000  // if this is set, GLES can't be used
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


// just like 0x800000FF for middle red, full alpha. Sparingly used...
typedef NSUInteger   UIHexColor;


@class UIEvent;
@class UIWindowEvent;

@protocol UIEventReceiver < NSObject>

- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event;
- (void) handleRetainedEvent:(UIEvent *) NS_CONSUMED event;

@end


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
- (void) os_deactivateGraphicsContext;
- (void) os_swapBuffers;

- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

- (void) os_show;
- (void) os_hide;

- (void) os_initEvents;

- (void) os_setTitleUTF8String:(char *) s;

// this is not HZ (but 1 / HZ)
- (double) os_primaryMonitorPPI;
- (double) os_primaryMonitorRefreshRate;
- (double) os_monitorRefreshRate;

// glfw window
- (void *) os_window;

- (void) getWindowInfo:(struct CGWindowInfo *) info;  // owner UIWindow

@end


struct mulle_pointerarray;


@protocol UIGraphicsContext <NSObject>

@property( assign) BOOL         rendersOffScreen;
@property( assign) NSUInteger   framebufferBits;
@property( assign) id           OSWindow;

- (instancetype) initWithEdgeAntialiasing:(BOOL) edgeAntialiasing
                        useStencilStrokes:(BOOL) stencilStrokes;

- (void) setActive:(BOOL) yes;

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
@end


@protocol UIImage <NSObject>

- (id) shareWithContext:(id) context;
- (CGSize) size;

@end
