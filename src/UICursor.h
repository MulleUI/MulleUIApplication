//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "NSObject.h")
#  import "NSObject.h"
# endif
#endif

#import "import.h"


enum
{
   UICursorDefault,
   UICursorTextInput,
   UICursorDrag,
   UICursorHorizontalResize,
   UICursorVerticalResize 
};

typedef NSUInteger  UICursorStandardShape;
#define n_UICursorStandardShapes   (UICursorVerticalResize + 1)

typedef void   UICursor;
