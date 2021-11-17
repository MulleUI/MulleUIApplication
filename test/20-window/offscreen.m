#import <MulleUICore/MulleUICore.h>


int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 128, 128)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleRenderNonRetainedOnly|UIWindowStyleOffscreen];
   if( ! window)
   {
      fprintf( stderr, "windowWithFrame: failed\n");
      exit( 1);
   }
   [app addWindow:window];
   [app terminate];

   return( 0);
}