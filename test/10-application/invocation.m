#import <MulleUIApplication/MulleUIApplication.h>


// just a leak checking test really
int   main( void)
{
   UIApplication   *app;

   app = [UIApplication new];
   if( ! app)
   {
      fprintf( stderr, "sharedInstance failed\n");
      exit( 1);
   }

   [app invokeOnMainThread:[NSInvocation object]];

   [app release];

   return( 0);
}