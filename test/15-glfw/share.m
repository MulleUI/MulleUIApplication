#import <MulleUICore/MulleUICore.h>


int   main( void)
{
   UIApplication   *app;
   GLFWWindow      *window[ 2];

   app = [UIApplication sharedInstance];

   @autoreleasepool
   {
      window[ 0] = [[[GLFWWindow alloc] initWithFrame:CGRectMake( 0, 0, 128, 128)
                                      titleUTF8String:"Foo"
                                            styleMask:UIWindowStyleInvisible] autorelease];

      window[ 1] = [[[GLFWWindow alloc] initWithFrame:CGRectMake( 128, 0, 128, 128)
                                      titleUTF8String:"Bar"
                                            styleMask:UIWindowStyleInvisible
                                        sharingWindow:window[ 0]] autorelease];
      if( ! window[ 1])
      {
         fprintf( stderr, "sharingWindow: failed\n");
         exit( 1);
      }

      // GLFW windows are not part of UIApplication, but once we
      // terminate the app, the windows can't properly be reaped so.
      // either performFinalize them or wrap everything into an autoreleasepool
      // which is easier
   }
   [app terminate];

   return( 0);
}