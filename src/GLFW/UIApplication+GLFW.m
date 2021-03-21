//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "UIApplication.h")
#  import "UIApplication.h"
# endif
#endif


#import "import-private.h"



@implementation UIApplication ( GLFW)

static void   error_callback(int code, const char* description)
{
   fprintf( stderr, "GLFW Error #%d: \"%s\"\n", code, description);
}


+ (void) os_initialize
{
   assert( [NSThread mulleIsMainThread]);

   if( ! glfwInit())
   {
      fprintf( stderr, "Couldn't get GLFW initialized\n");
      abort();
   }
   // calling glSwapInterval here is too early
   glfwSetErrorCallback( error_callback);
}


+ (void) os_terminate
{
	glfwTerminate();
}

@end
