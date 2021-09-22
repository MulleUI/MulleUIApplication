//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local GLFWWindow over one in import.h
#ifdef __has_include
# if __has_include( "GLFWWindow.h")
#  import "GLFWWindow.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface GLFWWindow( UIEvent)

- (void) os_initEvents;

@end
