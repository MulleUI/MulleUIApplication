//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"


typedef NS_ENUM( NSUInteger, UICursorStandardShape)
{
   UICursorDefault,
   UICursorTextInput,
   UICursorDrag,
   UICursorHorizontalResize,
   UICursorVerticalResize,
#if ! defined( GLFW_VERSION_MAJOR) || (GLFW_VERSION_MAJOR > 3) || (GLFW_VERSION_MAJOR == 3 && GLFW_VERSION_MAJOR >= 4)
   UICursorDiagonalResize,      // need glfw3.4 for this (also change below!)
#endif

   n_UICursorStandardShapes
};


typedef NSUInteger  UICursorStandardShape;

typedef void   UICursor;
