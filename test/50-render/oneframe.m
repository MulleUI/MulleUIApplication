#import <MulleUICore/MulleUICore.h>


int   main( void)
{
   UIApplication   *app;
   UIWindow        *window;

   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 128, 128)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleRenderNonRetainedOnly|UIWindowStyleInvisible];
   [app addWindow:window];
   [window renderUpToNumberOfFrames:1];
   [app terminate];

   return( 0);
}