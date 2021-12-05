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

#define  GLFWWindowStyleMaskDefault (UIWindowStyleDecorated)


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

