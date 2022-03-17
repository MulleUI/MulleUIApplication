//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIApplication+UIEvent.h"

#import "import-private.h"



@implementation UIApplication ( UIEvent)


/*
 * Window events are special. They don't come in over the queue but are
 * dispatched directly. It's assumed that only the main window (not the
 * offscreen window) sends these events. In a multi-thread configuration
 * these events come in and are handled by the mainThread. The regular
 * events also come in over the mainThread put are then queued for the
 * window thread.
 */
- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) NS_CONSUMED event
{
   //
   // we got to figure out which UIWindow is responsible
   // then do an immediate refresh there
   //
   switch( [event windowEventType])
   {
   case UIWindowEventTypeClose             :
   case UIWindowEventTypeFramebufferResize :
   case UIWindowEventTypeResize            :
   case UIWindowEventTypeMove              :
   case UIWindowEventTypeRefresh           :
      fprintf( stderr, "UIApplication discards event\n");
      return( nil);
   }

   fprintf( stderr, "UIApplication ignores event\n");
   return( event);
}


- (void) handleRetainedEvent:(UIWindowEvent *) event
{
#if DEBUG
   fprintf( stderr, "UIApplication releases retained event\n");
#endif
   [event release];
}

@end
