//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIApplication+UIEvent.h"

#import "import-private.h"



@interface UIApplication( UIScreenPrivate)

- (void) _addScreen:(id <UIScreen>) screen;
// does not call [UIWindow terminate]
- (void) _removeScreen:(id <UIScreen>) screen;

@end



@implementation UIApplication ( UIEvent)

- (UIWindowEvent *) handleScreenEvent:(UIScreenEvent *) event
{
   switch( [event screenEventType])
   {
   case UIScreenEventTypeConnected    : [self _addScreen:[event screen]]; break;
   case UIScreenEventTypeDisconnected : [self _removeScreen:[event screen]]; break;
   }

   // TODO: shouldn't we propagate this to all windows ?
   
   return( nil);
}


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
      MulleUILog( "UIApplication discards event %#@", event);
      return( nil);
   }

   MulleUILog( "UIApplication ignores event %#@", event);
   return( event);
}


- (void) receiveRetainedEvent:(UIWindowEvent *) event
{
#if DEBUG
   MulleUILog( "release retained event");
#endif
   [event release];
}

@end
