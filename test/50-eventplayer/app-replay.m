#include <MulleUIApplication/MulleUIApplication.h>


// Test category to stub out OS-layer methods we don't need for event replay testing
@interface UIApplication (TestStubs)
@end

@implementation UIApplication (TestStubs)

- (void) os_waitEventsWithTimeout:(mulle_relativetime_t) timeout
{
   // Sleep for the timeout duration to allow timers to become ready
   mulle_relativetime_sleep( timeout);
}

- (void) os_pollGamepads
{
   // No-op for testing - no gamepads in test environment
}

- (NSUInteger) testTimerCount
{
   NSUInteger count;
   NSLockingDo( _timersLock)
   {
      count = mulle_structarray_get_count( &_timers);
   }
   return( count);
}

@end


@interface EventLogger : NSObject <UIEventReceiver>
{
   NSUInteger   _eventCount;
}
@end


@implementation EventLogger

- (void) receiveRetainedEvent:(UIEvent *) event
{
   _eventCount++;
   mulle_printf( "Event %lu: type=%ld\n", _eventCount, (long)[event eventType]);
   [event release];
}

- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event
{
   return( event);
}

@end


int main( void)
{
   UIApplication    *app;
   UINullOSWindow   *nullOSWindow;
   UINullWindow     *window;
   UIEventPlayer    *player;
   EventLogger      *logger;
   BOOL              result;
   int               i;
   
   @autoreleasepool
   {
      mulle_printf( "=== UIEventPlayer with UINullWindow Test ===\n\n");
      
      // Get application
      app = [UIApplication sharedInstance];
      [app setDebuggingFlags:0x1];  // Enable basic debugging
      mulle_printf( "Got UIApplication\n");
      
      // Create null OS window
      nullOSWindow = [UINullOSWindow instance];
      mulle_printf( "Created UINullOSWindow\n");
      
      // Create event logger and hook it to OS window
      logger = [EventLogger instance];
      [nullOSWindow setEventsReceiver:logger];
      mulle_printf( "Set event logger\n");

      
      // Wrap in UIWindow
      window = [[[UINullWindow alloc] initWithOSWindow:nullOSWindow] autorelease];
      mulle_printf( "Created UINullWindow\n");
      
      // Add window to application
      [app addWindow:window];
      mulle_printf( "Added window to UIApplication\n\n");
      
      // Create and load event player
      player = [UIEventPlayer instance];
      result = [player loadScriptWithUTF8String:
         "window 0\n"
         "0.0 mouseMove x=100 y=100\n"
         "0.1 mouseDown button=Left x=100 y=100\n"
         "0.2 mouseUp button=Left x=100 y=100\n"];
      
      if( ! result)
      {
         mulle_printf( "FAILED: Could not load script\n");
         return( 1);
      }
      
      mulle_printf( "Loaded 3 mouse events\n");
      mulle_printf( "Starting playback...\n");

      
      // Start playback - this will use app's timers
      [player startPlayback];
      
      
      // Run until event player requests terminate
      i = 0;
      while( ! UIApplicationRequestRunLoopBreak && i < 10000)
      {
         [app runLoopIteration];
         i++;
      }
      
      mulle_printf( "\nRan event loop until terminate\n");
      mulle_printf( "\nSUCCESS: UIEventPlayer integrated with UIApplication\n");
      

   }
   
   return( 0);
}
