#include <MulleUIApplication/MulleUIApplication.h>
#include <math.h>


static NSUInteger   gInfiniteWaitCount;
static NSUInteger   gTimedWaitCount;


@interface UIApplication (TestStubs)
@end

@implementation UIApplication (TestStubs)

- (void) os_waitEventsWithTimeout:(mulle_relativetime_t) timeout
{
   if( isinf( timeout))
   {
      gInfiniteWaitCount++;
      mulle_printf( "BUG: os_waitEventsWithTimeout called with INFINITY (starvation!)\n");
      // Don't actually sleep forever - abort the loop
      UIApplicationRequestRunLoopBreak = YES;
      return;
   }
   gTimedWaitCount++;
   mulle_relativetime_sleep( timeout);
}

- (void) os_pollGamepads
{
}

@end


@interface EventLogger : NSObject <UIEventReceiver>
{
   NSUInteger   _eventCount;
}
- (NSUInteger) eventCount;
@end

@implementation EventLogger

- (NSUInteger) eventCount { return( _eventCount); }

- (void) receiveRetainedEvent:(UIEvent *) event
{
   _eventCount++;
   mulle_printf( "Event %lu received (type=%ld)\n", _eventCount, (long) [event eventType]);
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
   UINullOSWindow   *osWindow;
   UINullWindow     *window;
   UIEventPlayer    *player;
   EventLogger      *logger;
   NSUInteger       i;

   @autoreleasepool
   {
      app      = [UIApplication sharedInstance];
      osWindow = [UINullOSWindow instance];
      logger   = [EventLogger instance];

      // Set async frame rate: window returns INFINITY from displayFrameIfNeeded:
      // when no animation is running - this is the condition that triggers starvation
      [osWindow setFrameRate:UIWindowFrameRateAsync];
      [osWindow setEventsReceiver:logger];

      window = [[[UINullWindow alloc] initWithOSWindow:osWindow] autorelease];
      [app addWindow:window];

      // Two events with a 0.3s gap between them.
      // After event 1 fires, the window is idle (INFINITY frame rate).
      // The timer for event 2 must still fire despite the idle window.
      player = [UIEventPlayer instance];
      [player loadScriptWithUTF8String:
         "0.0 mouseDown button=Left x=10 y=10\n"
         "0.3 mouseUp button=Left x=10 y=10\n"
         "0.4 terminate\n"];

      [player startPlayback];

      // Run loop - cap iterations to avoid hanging forever
      for( i = 0; i < 10000 && ! UIApplicationRequestRunLoopBreak; i++)
      {
         @autoreleasepool
         {
            [app runLoopIteration];
         }
      }

      mulle_printf( "\nEvents received: %lu (expected 2)\n", [logger eventCount]);
      mulle_printf( "Infinite waits:  %lu (expected 0)\n", gInfiniteWaitCount);
      mulle_printf( "Timed waits:     %lu\n", gTimedWaitCount);

      if( gInfiniteWaitCount > 0)
         mulle_printf( "RESULT: BUG REPRODUCED - timer starvation confirmed\n");
      else if( [logger eventCount] == 2)
         mulle_printf( "RESULT: PASS - both events delivered\n");
      else
         mulle_printf( "RESULT: FAIL - only %lu/2 events delivered\n", [logger eventCount]);
   }

   return( gInfiniteWaitCount > 0 ? 1 : 0);
}
