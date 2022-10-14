#import <MulleUIApplication/MulleUIApplication.h>


@interface UIApplication( DummyOSSupport)
@end

@implementation UIApplication( DummyOSSupport)

- (void) os_init
{
}


- (void) os_finalize
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
      fprintf( stderr, "failed\n");
      exit( 1);
   }

   [app release];

   return( 0);
}