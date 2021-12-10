#import "import.h"

//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// basically a future, but GLFWWindow also adopts it
// the only reason for this is a little type safety
@protocol UIWindow < NSObject>
@end


//
// trying hard to keep enums "positive"
//
//   .-----------------------------.
//   | UIWindowStyleDecorated      |
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
   UIWindowStyleDecorated          = 0x100,  // window bar, resizer

// CG
   UIWindowStyleEdgeAntialias      = 0x1000,   // nanvg
   UIWindowStyleStencilStrokes     = 0x2000,   // nanovg

// UIWindow
   UIWindowStyleRetained           = 0x10000,  // use UIWindowBackingStoreRetained

// GLFW/OpenGL
   UIWindowOpenGLCoreProfile       = 0x0100000,
   UIWindowOpenGLCompatProfile     = 0x0200000,
   UIWindowOpenGLForwardCompatible = 0x0400000,  // folklore says, specify compat too

   UIWindowOpenGLLibraryFallback   = 0x0800000,  // try other openGL libraries as fallback
   UIWindowOpenGLDeprecated        = 0x1000000  // if this is set, GLES can't be used
};



static inline NSUInteger   UIWindowsStyleMaskByEnabling( NSUInteger styleMask, enum UIWindowStyle style)
{
   return( styleMask | style);
}


static inline NSUInteger   UIWindowsStyleMaskByDisabling( NSUInteger styleMask, enum UIWindowStyle style)
{
   return( styleMask & ~style);
}


static inline NSUInteger   UIWindowsStyleMaskBySetting( NSUInteger styleMask, enum UIWindowStyle style, int flag)
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

@protocol UIEventReceiver < NSObject>

- (UIEvent *) handleWindowEvent:(UIEvent *) event;
- (void) queueRetainedEvent:(UIEvent *) event;

@end


@protocol UIOSWindow <NSObject>

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(NSUInteger) hints
                 sharingWindow:(id <UIOSWindow>) sharingWindow;

@property( assign) id <UIEventReceiver>   windowEventsReceiver;
@property( assign) id <UIEventReceiver>   eventsReceiver;
@property( assign) NSUInteger             discardEventsMask;

- (void) os_requestClose;
- (void) os_destroyWindow;

- (CGSize) os_windowSize;
- (CGRect) os_windowFrame;
- (void) os_setSwapInterval:(NSUInteger) value;

// bind GL context of the window to the current thread
// synonymous with activate
- (void) os_activateContext;
- (void) os_deactivateContext;
- (struct CGBitmapSize) os_framebufferSize;
- (void) os_swapBuffers;

- (void) os_requestClose;
- (BOOL) os_windowShouldClose;

- (void) os_show;
- (void) os_hide;

- (void) os_initEvents;

- (CGFloat) os_primaryMonitorPPI;
- (CGFloat) os_primaryMonitorRefreshRate;

@end


struct mulle_pointerarray;


@protocol UIOSGraphicsContext <NSObject>

@property( assign) BOOL   rendersOffScreen;

- (instancetype) initWithEdgeAntialiasing:(BOOL) edgeAntialiasing
                        useStencilStrokes:(BOOL) stencilStrokes;

- (void) setActive:(BOOL) yes;

- (void) clearFramebufferWithHexColor:(UIHexColor) color;

- (void) beginRender:(struct CGFrameInfo *) info;
- (void) renderObjects:(struct mulle_pointerarray *) array;
- (void) suspendRender;
- (void) resumeRender;
- (void) _endRender;
- (void) endRender;  // calls suspendRender then endRender

- (id) framebufferImage;

- (struct CGFramebufferBitmap)
   lastRenderedFramebufferBitmapType:(enum CGFramebufferBitmapType) type
                            inFlight:(BOOL) inFlight
                           allocator:(struct mulle_allocator *) allocator;

- (struct CGFramebufferBitmap)
   lastRenderedOffscreenFramebufferBitmapType:(enum CGFramebufferBitmapType) type
                                    allocator:(struct mulle_allocator *) allocator;

- (void) drawFramebufferBitmap:(struct CGFramebufferBitmap *) fb;

- (id) shareImage:(id) framebufferImage
      withContext:(id <UIOSGraphicsContext>) context;

// used by UIWindow to blit...
- (void) drawRect:(CGRect) rect
            image:(id) image
            scale:(BOOL) scale;

// used by UIWindow to debug...
- (void) fillRect:(CGRect) rect
         hexColor:(UIHexColor) hexColor;

- (void) strokeRect:(CGRect) rect
           hexColor:(UIHexColor) hexColor
              width:(CGFloat) width;
@end

