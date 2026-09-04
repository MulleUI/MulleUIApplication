# MulleUIApplication

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🛖 MulleUIApplication provides abstract classes like UIApplication and UIEvent

This library lays the ground work for window and event handling. It isn't tied
to any platform or graphics library. The `UIApplication` and `UIEvent` base
classes get fleshed out by MulleUIWindow and the platform wrappers
(MulleGLFW, MulleSDL).

Though technically dependent on MulleFoundationBase, the conceptual dependency
is MulleObjCLockingFoundation only. Especially not used are "NSArray" or
"NSString"




| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleUIApplication.svg) [![Build Status](https://github.com/MulleUI/MulleUIApplication/workflows/CI/badge.svg)](//github.com/MulleUI/MulleUIApplication/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleUIApplication](https://deepwiki.com/MulleUI/MulleUIApplication)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-ui-app-construction)
* [Debugger Guide](asset/howto/debugger/mulle-ui-application)
* [Verifier Guide](asset/howto/verifier/mulle-ui-application)

## Usage

Create an application, attach a window and run it:

``` objc
#import <MulleUIApplication/MulleUIApplication.h>

int  main( void)
{
   @autoreleasepool
   {
      UIApplication  *application;
      UIWindow       *window;

      application = [UIApplication sharedInstance];

      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 400.0)];
      [application addWindow:window];

      return( [application runApp]);
   }
}
```

The `UIWindowStyle` options passed to the window control how it is
created and rendered:

|Enum | Description
|-----|---------------------------------------
|`UIWindowStyleNop` |  Sentinel value; use when no style bits are set to avoid default values.
|`UIWindowStyleResizable` |  Allows the user to resize the window by dragging edges/corners.
|`UIWindowStyleHidden` |  Window is created but not shown.
|`UIWindowStyleOffscreen` |  Renders offscreen with no visible desktop window. For pure offscreen use.
|`UIWindowStyleSingleBuffer` |  Uses single buffering instead of double buffering, no front/back buffer swap.
|`UIWindowStyleTransparent` |   Renders with a transparent background instead of opaque.
|`UIWindowStyleFloating` |   Window floats above other windows, not constrained by stacking order.
|`UIWindowStyleBare` | No window decorations like borders, title bar, close buttons etc are drawn.
|`UIWindowStylePlanes` |   Gives the window `UIWindowPlane`s (content, menu, tooltip, ...).
|`UIWindowStyleNoView` |   No `UIView` will be generated for the window.
|`UIWindowStyleAntiAlias` |   Enables antialiasing (nanovg or GLFW). On by default via `UIWindowStyleMaskDefault`.
|`UIWindowStyleForceEdgeAntiAlias` |   Forces software EdgeAA regardless of platform.
|`UIWindowStyleStencilStrokes` |   Enables stencil buffer usage for stroke shapes without fill.
|`UIWindowStyleClearType` |   Enables ClearType subpixel antialiasing.
|`UIWindowStyleRetained` |   Retains rendered contents between frames for resize performance. Uses a separate render thread.
|`UIWindowStyleRetainedOnMainThread` |   Retained rendering occurs on main thread instead of a separate render thread.
|`UIWindowOpenGLCoreProfile` |  Requests OpenGL Core profile context instead of Compatibility.
|`UIWindowOpenGLForward` |   Requests forward-compatible OpenGL context for future compatibility.
|`UIWindowOpenGLLibraryFallback` | Fallback to system OpenGL library if custom OpenGL fails.
|`UIWindowOpenGLDeprecated` |   Includes deprecated OpenGL features in context.

## Build the demo

The `demo/` folder is a [mulle-sde](//github.com/mulle-sde) project:

``` sh
cd demo
mulle-sde craft
```


### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleUIApplication to your project:

``` sh
mulle-sde add github:MulleUI/MulleUIApplication
```

To only add the sources of MulleUIApplication with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleUIApplication
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleUIApplication and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleUIApplication/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleObjCTimeFoundation](https://github.com/MulleFoundation/MulleObjCTimeFoundation)             | 💰 MulleObjCTimeFoundation provides time classes
| [MulleUIBase](https://github.com/MulleUI/MulleUIBase)             | 💺 MulleUIBase adds Objective-C to mulle-geometry and friends
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleUIApplication/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleUIApplication/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleUIApplication** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



