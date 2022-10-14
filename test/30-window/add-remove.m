#import <MulleUIApplication/MulleUIApplication.h>


@interface UIEvent( DummyOSSupport)
@end

@implementation UIEvent( DummyOSSupport)

+ (void) os_waitEventsWithTimeout:(mulle_relativetime_t) timeout
{
}


@end



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


- (void) applicationDidRemoveWindow
{
}


- (void) applicationDidAddWindow
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
   MyWindow        *window;

   app = [UIApplication sharedInstance];
   if( ! app)
   {
      fprintf( stderr, "sharedInstance failed\n");
      exit( 1);
   }

   window = [MyWindow object];
   [app addWindow:window];
   [app removeWindow:window];

   [app addWindow:window];
   window = [MyWindow object];
   [app addWindow:window];

   [app requestTerminate];
   [app runLoop];

   return( 0);
}