# MulleUIApplication

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





### Add MulleUIApplication as a cmake subproject

In your code include its header:

``` c
#include <MulleUIApplication/MulleUIApplication.h>
```

Add MulleUIApplication and dependencies as git submodules and link against
them:

``` bash
git submodule add -f --branch * --name "mintomic" \
                            "clib:mulle-concurrent/mintomic@*" \
                            "stash/mintomic"
git submodule add -f --branch * --name "dlfcn-win32" \
                            "clib:mulle-core/dlfcn-win32@*" \
                            "stash/dlfcn-win32"
git submodule add -f --branch * --name "src/mulle-aba" \
                            "clib:mulle-concurrent/mulle-aba@*" \
                            "stash/src/mulle-aba"
git submodule add -f --branch * --name "src/mulle-allocator" \
                            "clib:mulle-c/mulle-allocator@*" \
                            "stash/src/mulle-allocator"
git submodule add -f --branch * --name "src/mulle-buffer" \
                            "clib:mulle-c/mulle-buffer@*" \
                            "stash/src/mulle-buffer"
git submodule add -f --branch * --name "src/mulle-c11" \
                            "clib:mulle-c/mulle-c11@*" \
                            "stash/src/mulle-c11"
git submodule add -f --branch * --name "src/mulle-concurrent" \
                            "clib:mulle-concurrent/mulle-concurrent@*" \
                            "stash/src/mulle-concurrent"
git submodule add -f --branch * --name "src/mulle-container-debug" \
                            "clib:mulle-c/mulle-container-debug@*" \
                            "stash/src/mulle-container-debug"
git submodule add -f --branch * --name "src/mulle-container" \
                            "clib:mulle-c/mulle-container@*" \
                            "stash/src/mulle-container"
git submodule add -f --branch * --name "src/mulle-data" \
                            "clib:mulle-c/mulle-data@*" \
                            "stash/src/mulle-data"
git submodule add -f --branch * --name "src/mulle-dlfcn" \
                            "clib:mulle-core/mulle-dlfcn@*" \
                            "stash/src/mulle-dlfcn"
git submodule add -f --branch * --name "src/mulle-dtostr" \
                            "clib:mulle-core/mulle-dtostr@*" \
                            "stash/src/mulle-dtostr"
git submodule add -f --branch * --name "src/mulle-fifo" \
                            "clib:mulle-concurrent/mulle-fifo@*" \
                            "stash/src/mulle-fifo"
git submodule add -f --branch * --name "src/mulle-fprintf" \
                            "clib:mulle-core/mulle-fprintf@*" \
                            "stash/src/mulle-fprintf"
git submodule add -f --branch * --name "src/mulle-http" \
                            "clib:mulle-c/mulle-http@*" \
                            "stash/src/mulle-http"
git submodule add -f --branch * --name "src/mulle-linkedlist" \
                            "clib:mulle-concurrent/mulle-linkedlist@*" \
                            "stash/src/mulle-linkedlist"
git submodule add -f --branch * --name "src/mulle-mmap" \
                            "clib:mulle-core/mulle-mmap@*" \
                            "stash/src/mulle-mmap"
git submodule add -f --branch * --name "src/mulle-multififo" \
                            "clib:mulle-concurrent/mulle-multififo@*" \
                            "stash/src/mulle-multififo"
git submodule add -f --branch * --name "src/mulle-rbtree" \
                            "clib:mulle-c/mulle-rbtree@*" \
                            "stash/src/mulle-rbtree"
git submodule add -f --branch * --name "src/mulle-rbtree-debug" \
                            "clib:mulle-core/mulle-rbtree-debug@*" \
                            "stash/src/mulle-rbtree-debug"
git submodule add -f --branch * --name "src/mulle-regex" \
                            "clib:mulle-c/mulle-regex@*" \
                            "stash/src/mulle-regex"
git submodule add -f --branch * --name "src/mulle-slug" \
                            "clib:mulle-c/mulle-slug@*" \
                            "stash/src/mulle-slug"
git submodule add -f --branch * --name "src/mulle-sprintf" \
                            "clib:mulle-core/mulle-sprintf@*" \
                            "stash/src/mulle-sprintf"
git submodule add -f --branch * --name "src/mulle-storage" \
                            "clib:mulle-c/mulle-storage@*" \
                            "stash/src/mulle-storage"
git submodule add -f --branch * --name "src/mulle-thread" \
                            "clib:mulle-concurrent/mulle-thread@*" \
                            "stash/src/mulle-thread"
git submodule add -f --branch * --name "src/mulle-time" \
                            "clib:mulle-core/mulle-time@*" \
                            "stash/src/mulle-time"
git submodule add -f --branch * --name "src/mulle-unicode" \
                            "clib:mulle-c/mulle-unicode@*" \
                            "stash/src/mulle-unicode"
git submodule add -f --branch * --name "src/mulle-url" \
                            "clib:mulle-c/mulle-url@*" \
                            "stash/src/mulle-url"
git submodule add -f --branch * --name "src/mulle-utf" \
                            "clib:mulle-c/mulle-utf@*" \
                            "stash/src/mulle-utf"
git submodule add -f --branch * --name "src/mulle-vararg" \
                            "clib:mulle-c/mulle-vararg@*" \
                            "stash/src/mulle-vararg"
git submodule add -f --name "stdthreads" \
                            "" \
                            "stash/stdthreads"
git submodule add -f --name "pthread" \
                            "" \
                            "stash/pthread"
git submodule add -f --name "src/mulle-spawn" \
                            "clib:mulle-core/mulle-spawn@*" \
                            "stash/src/mulle-spawn"
git submodule add -f --name "src/mulle-socket" \
                            "clib:mulle-core/mulle-socket@*" \
                            "stash/src/mulle-socket"
git submodule add -f --name "ws2_32" \
                            "" \
                            "stash/ws2_32"
git submodule add -f --name "mulle-core" \
                            "https://github.com/mulle-core/mulle-core.git" \
                            "stash/mulle-core"
git submodule add -f --name "craftinfo/libbacktrace-craftinfo" \
                            "" \
                            "stash/craftinfo/libbacktrace-craftinfo"
git submodule add -f --name "libbacktrace" \
                            "https://github.com/mulle-core/libbacktrace.git" \
                            "stash/libbacktrace"
git submodule add -f --branch * --name "src/mulle-atinit" \
                            "clib:mulle-core/mulle-atinit@*" \
                            "stash/src/mulle-atinit"
git submodule add -f --branch * --name "src/mulle-atexit" \
                            "clib:mulle-core/mulle-atexit@*" \
                            "stash/src/mulle-atexit"
git submodule add -f --branch * --name "src/mulle-stacktrace" \
                            "clib:mulle-core/mulle-stacktrace@*" \
                            "stash/src/mulle-stacktrace"
git submodule add -f --name "mulle-core-all-load" \
                            "https://github.com/mulle-core/mulle-core-all-load.git" \
                            "stash/mulle-core-all-load"
git submodule add -f --name "mulle-objc-runtime" \
                            "https://github.com/mulle-objc/mulle-objc-runtime.git" \
                            "stash/mulle-objc-runtime"
git submodule add -f --name "mulle-objc-debug" \
                            "https://github.com/mulle-objc/mulle-objc-debug.git" \
                            "stash/mulle-objc-debug"
git submodule add -f --name "mulle-objc-cc" \
                            "https://github.com/mulle-cc/mulle-objc-cc.git" \
                            "stash/mulle-objc-cc"
git submodule add -f --name "MulleObjC" \
                            "https://github.com/mulle-objc/MulleObjC.git" \
                            "stash/MulleObjC"
git submodule add -f --name "MulleObjCTimeFoundation" \
                            "https://github.com/MulleFoundation/MulleObjCTimeFoundation.git" \
                            "stash/MulleObjCTimeFoundation"
git submodule add -f --name "zlib" \
                            "https://github.com/madler/zlib.git" \
                            "stash/zlib"
git submodule add -f --name "src/mulle-bitmap" \
                            "clib:mulle-gfx/mulle-bitmap" \
                            "stash/src/mulle-bitmap"
git submodule add -f --name "src/mulle-frame" \
                            "clib:mulle-gfx/mulle-frame" \
                            "stash/src/mulle-frame"
git submodule add -f --name "src/mulle-geometry" \
                            "clib:mulle-gfx/mulle-geometry" \
                            "stash/src/mulle-geometry"
git submodule add -f --name "src/mulle-layout" \
                            "clib:mulle-gfx/mulle-layout" \
                            "stash/src/mulle-layout"
git submodule add -f --name "src/mulle-quadtree" \
                            "clib:mulle-gfx/mulle-quadtree" \
                            "stash/src/mulle-quadtree"
git submodule add -f --name "src/mulle-fparray" \
                            "clib:mulle-gfx/mulle-fparray" \
                            "stash/src/mulle-fparray"
git submodule add -f --name "src/mulle-hexcolor" \
                            "clib:mulle-c/mulle-hexcolor" \
                            "stash/src/mulle-hexcolor"
git submodule add -f --branch * --name "src/mulle-path" \
                            "clib:mulle-gfx/mulle-path@*" \
                            "stash/src/mulle-path"
git submodule add -f --branch * --name "src/mulle-color" \
                            "clib:mulle-gfx/mulle-color@*" \
                            "stash/src/mulle-color"
git submodule add -f --name "math" \
                            "" \
                            "stash/math"
git submodule add -f --name "z" \
                            "" \
                            "stash/z"
git submodule add -f --name "mulle-gfx" \
                            "https://github.com/mulle-gfx/mulle-gfx.git" \
                            "stash/mulle-gfx"
git submodule add -f --name "MulleUIBase" \
                            "https://github.com/MulleUI/MulleUIBase.git" \
                            "stash/MulleUIBase"
git submodule add -f --name "mulle-objc-tools" \
                            "https://github.com/mulle-objc/mulle-objc-tools.git" \
                            "stash/mulle-objc-tools"
git submodule add -f --name "MulleUIApplication" \
                        "https://github.com/MulleUI/MulleUIApplication" \
                        "stash/MulleUIApplication"
git submodule update --init --recursive
```

``` cmake
include_directories( SYSTEM "${CMAKE_BINARY_DIR}/include")

add_subdirectory( stash/mintomic)
add_subdirectory( stash/dlfcn-win32)
add_subdirectory( stash/src/mulle-aba)
add_subdirectory( stash/src/mulle-allocator)
add_subdirectory( stash/src/mulle-buffer)
add_subdirectory( stash/src/mulle-c11)
add_subdirectory( stash/src/mulle-concurrent)
add_subdirectory( stash/src/mulle-container-debug)
add_subdirectory( stash/src/mulle-container)
add_subdirectory( stash/src/mulle-data)
add_subdirectory( stash/src/mulle-dlfcn)
add_subdirectory( stash/src/mulle-dtostr)
add_subdirectory( stash/src/mulle-fifo)
add_subdirectory( stash/src/mulle-fprintf)
add_subdirectory( stash/src/mulle-http)
add_subdirectory( stash/src/mulle-linkedlist)
add_subdirectory( stash/src/mulle-mmap)
add_subdirectory( stash/src/mulle-multififo)
add_subdirectory( stash/src/mulle-rbtree)
add_subdirectory( stash/src/mulle-rbtree-debug)
add_subdirectory( stash/src/mulle-regex)
add_subdirectory( stash/src/mulle-slug)
add_subdirectory( stash/src/mulle-sprintf)
add_subdirectory( stash/src/mulle-storage)
add_subdirectory( stash/src/mulle-thread)
add_subdirectory( stash/src/mulle-time)
add_subdirectory( stash/src/mulle-unicode)
add_subdirectory( stash/src/mulle-url)
add_subdirectory( stash/src/mulle-utf)
add_subdirectory( stash/src/mulle-vararg)
add_subdirectory( stash/stdthreads)
add_subdirectory( stash/pthread)
add_subdirectory( stash/src/mulle-spawn)
add_subdirectory( stash/src/mulle-socket)
add_subdirectory( stash/ws2_32)
add_subdirectory( stash/mulle-core)
add_subdirectory( stash/craftinfo/libbacktrace-craftinfo)
add_subdirectory( stash/libbacktrace)
add_subdirectory( stash/src/mulle-atinit)
add_subdirectory( stash/src/mulle-atexit)
add_subdirectory( stash/src/mulle-stacktrace)
add_subdirectory( stash/mulle-core-all-load)
add_subdirectory( stash/mulle-objc-runtime)
add_subdirectory( stash/mulle-objc-debug)
add_subdirectory( stash/mulle-objc-cc)
add_subdirectory( stash/MulleObjC)
add_subdirectory( stash/MulleObjCTimeFoundation)
add_subdirectory( stash/zlib)
add_subdirectory( stash/src/mulle-bitmap)
add_subdirectory( stash/src/mulle-frame)
add_subdirectory( stash/src/mulle-geometry)
add_subdirectory( stash/src/mulle-layout)
add_subdirectory( stash/src/mulle-quadtree)
add_subdirectory( stash/src/mulle-fparray)
add_subdirectory( stash/src/mulle-hexcolor)
add_subdirectory( stash/src/mulle-path)
add_subdirectory( stash/src/mulle-color)
add_subdirectory( stash/math)
add_subdirectory( stash/z)
add_subdirectory( stash/mulle-gfx)
add_subdirectory( stash/MulleUIBase)
add_subdirectory( stash/mulle-objc-tools)
add_subdirectory( stash/MulleUIApplication)

target_link_libraries( ${PROJECT_NAME} PUBLIC mintomic)
target_link_libraries( ${PROJECT_NAME} PUBLIC dlfcn-win32)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-aba)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-allocator)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-buffer)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-c11)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-concurrent)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-container-debug)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-container)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-data)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-dlfcn)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-dtostr)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-fifo)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-fprintf)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-http)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-linkedlist)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-mmap)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-multififo)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-rbtree)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-rbtree-debug)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-regex)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-slug)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-sprintf)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-storage)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-thread)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-time)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-unicode)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-url)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-utf)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-vararg)
target_link_libraries( ${PROJECT_NAME} PUBLIC stdthreads)
target_link_libraries( ${PROJECT_NAME} PUBLIC pthread)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-spawn)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-socket)
target_link_libraries( ${PROJECT_NAME} PUBLIC ws2_32)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-core)
target_link_libraries( ${PROJECT_NAME} PUBLIC craftinfo/libbacktrace-craftinfo)
target_link_libraries( ${PROJECT_NAME} PUBLIC libbacktrace)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-atinit)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-atexit)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-stacktrace)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-core-all-load)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-objc-runtime)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-objc-debug)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-objc-cc)
target_link_libraries( ${PROJECT_NAME} PUBLIC MulleObjC)
target_link_libraries( ${PROJECT_NAME} PUBLIC MulleObjCTimeFoundation)
target_link_libraries( ${PROJECT_NAME} PUBLIC zlib)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-bitmap)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-frame)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-geometry)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-layout)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-quadtree)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-fparray)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-hexcolor)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-path)
target_link_libraries( ${PROJECT_NAME} PUBLIC src/mulle-color)
target_link_libraries( ${PROJECT_NAME} PUBLIC math)
target_link_libraries( ${PROJECT_NAME} PUBLIC z)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-gfx)
target_link_libraries( ${PROJECT_NAME} PUBLIC MulleUIBase)
target_link_libraries( ${PROJECT_NAME} PUBLIC mulle-objc-tools)
target_link_libraries( ${PROJECT_NAME} PUBLIC MulleUIApplication)
```

Or let [mulle-sde](//github.com/mulle-sde) do it:

``` sh
mulle-sde add github:MulleUI/MulleUIApplication
```

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



