#import <MulleUIApplication/MulleUIApplication.h>


@interface UIApplication( DummyOSSupport)
@end


@implementation UIApplication( DummyOSSupport)

- (void) os_init
{
}

- (void *) os_createStandardCursor:(NSUInteger) shape
{
   return( NULL);
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

   [app addTimer:[NSTimer mulleTimerWithRelativeTimeInterval:0.0
                                              repeatInterval:2.0
                                                  invocation:[NSInvocation instance]]
forTimerReceiver:app];

   [app release];

   return( 0);
}