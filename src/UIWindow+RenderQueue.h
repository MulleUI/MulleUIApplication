//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local UIView over one in import.h
#ifdef __has_include
# if __has_include( "UIWindow.h")
#  import "UIWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface UIWindow( RenderQueue)

// all layers are placed into the render queue, the layers get their
// transform and alpha set
- (void) createRenderQueue:(struct mulle_pointerarray *) renderQueue;

@end
