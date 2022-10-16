#import <MulleUIApplication/MulleUIApplication.h>


@interface MyWindow : NSObject <UIWindow>
@end


@implementation MyWindow

- (void *) os_window;
{
   return( NULL);
}


- (id <UIOSWindow>) OSWindow
{
   return( nil);
}


- (void) applicationDidAddWindow:(UIApplication *) app
{
}


- (void) applicationDidRemoveWindow:(UIApplication *) app
{
}


- (mulle_relativetime_t) displayFrameIfNeeded:(mulle_absolutetime_t) now
{
   return( INFINITY);
}


- (void) writeOSWindowPropertyChangesIfNeeded
{
}


- (void) setNeedsRefresh
{
}


- (BOOL) shouldClose
{
   return( NO);
}

@end


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

   [app addWindow:[MyWindow object]];

   [app release];

   return( 0);
}