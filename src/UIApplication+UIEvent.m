//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIApplication+UIEvent.h"

#import "import-private.h"

#import "import-project.h"


@interface UIApplication( Private)

- (void) _addScreen:(id <UIScreen>) screen;
// does not call [UIWindow terminate]
- (void) _removeScreen:(id <UIScreen>) screen;

- (void) _addGamepad:(id <UIGamepad>) screen;
// does not call [UIWindow terminate]
- (void) _removeGamepad:(id <UIGamepad>) screen;

@end



@implementation UIApplication ( UIEvent)

- (UIWindowEvent *) handleScreenEvent:(UIScreenEvent *) event
{
   id <UIWindow>   window;

   assert( [NSThread mulleIsMainThread]);

   switch( [event screenEventType])
   {
   case UIScreenEventTypeConnected    : [self _addScreen:[event screen]]; break;
   case UIScreenEventTypeDisconnected : [self _removeScreen:[event screen]]; break;
   }

   // propagate this to all windows ?
   mulle_array_for( &_windows, window)
   {
      [window receiveRetainedEvent:[event retain]];
   }   
   return( nil);
}


- (UIWindowEvent *) handleGamepadEvent:(UIGamepadEvent *) event
{
   id <UIWindow>   window;

   assert( [NSThread mulleIsMainThread]);

   switch( [event gamepadEventType])
   {
   case UIGamepadEventTypeConnected    : [self _addGamepad:[event gamepad]]; break;
   case UIGamepadEventTypeDisconnected : [self _removeGamepad:[event gamepad]]; break;
   }

   // propagate this to all windows ?
   mulle_array_for( &_windows, window)
   {
      [window receiveRetainedEvent:[event retain]];
   }   
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
- (UIWindowEvent *) handleWindowEvent:(UIWindowEvent *) event MULLE_OBJC_THREADSAFE_METHOD
{
   assert( [NSThread mulleIsMainThread]);

   [event mulleGainAccess];
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
   case UIWindowEventTypeFocusGained       :
   case UIWindowEventTypeFocusLost         :
      MulleUILog( "UIApplication discards event %#@", event);
      return( nil);
   }

   MulleUILog( "UIApplication ignores event %#@", event);

   return( event);
}


- (void) receiveRetainedEvent:(UIWindowEvent *) NS_CONSUMED event
{
   [event mulleGainAccess];

#if DEBUG
   MulleUILog( "release retained event");
#endif
   [event release];
}

@end
