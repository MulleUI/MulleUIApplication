#import "UIResponder.h"

#import "import-private.h"

#import "UIEvent.h"


#ifdef DEBUG
//# define EVENT_DEBUG
#endif


PROTOCOLCLASS_IMPLEMENTATION( UIResponder)

- (id <UIResponder>) nextResponder
{
   return( nil);
}


- (BOOL) canBecomeFirstResponder
{
   return( NO);
}


- (BOOL) canResignFirstResponder
{
   return( YES);
}


//
// the default is permissive, allowing mouse motion events
// 
- (BOOL) isFirstResponderEvent:(UIEvent *) event
{
   return( [event isInputEvent]);
}


static id   performSelectorIfResponding( UIResponder *self,
                                         SEL sel,
                                         UIInputEvent *event)
{
   assert( event);

   if( sel && [self respondsToSelector:sel])
   {
      event = MulleObjCObjectPerformSelector( self, sel, event);
   }   
   return( event);
}


- (UIInputEvent *) acceptMouseButtonEvent:(UIMouseButtonEvent *) event
{
   SEL   sel;
   int   action;
   int   button;

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   sel    = 0;
   action = [event action];
   button = [event button];

   // for support of other buttons, subclass and override
   // acceptMouseButtonEvent:
   //
   switch( button)
   {
      case UIEventMouseButtonLeft :
         switch( action)
         {
         case UIEventButtonActionDown :
            sel = @selector( mouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( mouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonRight  :
         switch( action)
         {
         case UIEventButtonActionDown   :
            sel = @selector( rightMouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( rightMouseUp:);
            break;
         }
         break;

      case UIEventMouseButtonMiddle :
         switch( action)
         {
         case UIEventButtonActionDown   :
            sel = @selector( otherMouseDown:);
            break;
         case UIEventButtonActionUp :
            sel = @selector( otherMouseUp:);
            break;
         }
   }

   return( performSelectorIfResponding( self, sel, event));
}


// general idea: suppress mouseDragged events, until a certain amount of
//               time has passed.
//               Also... don't do this if the responder doesn't care ?
//
- (UIMouseMotionEvent *) acceptMouseMotionEvent:(UIMouseMotionEvent *) event
{
   uint64_t       state;
   SEL            sel;

   assert( [event isKindOfClass:[UIMouseMotionEvent class]]);

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   sel   = 0;
   state = [event buttonStates];
   if( state)
   {
      sel = @selector( mouseDragged:);
      if( ! (state & (1 << UIEventMouseButtonLeft)))
      {
         if( state & (1 << UIEventMouseButtonRight))
            sel = @selector( rightMouseDragged:);
         else
            sel = @selector( otherMouseDragged:);
      }
   }

   return( performSelectorIfResponding( self, sel, event));

#if 0
   //
   // classically, these events do not happen when there is no tracking
   // area set up. But I don't see the point, you just don't implement
   // mouseMoved: and then this should be fairly harmless ?
   //
   if( event && [self respondsToSelector:@selector( mouseMoved:)])
   {
      event = [self performSelector:sel
                         withObject:event];
   }
#endif
}


- (UIInputEvent *) acceptMouseScrollEvent:(UIMouseScrollEvent *) event
{
   assert( [event isKindOfClass:[UIMouseScrollEvent class]]);

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   // scrollWheel: taken from AppKit
   // https://developer.apple.com/documentation/appkit/nsscrollview/1403494-scrollwheel?language=objc
   //
   return( performSelectorIfResponding( self, @selector( scrollWheel:), event));
}


- (UIInputEvent *) acceptKeyboardEvent:(UIKeyboardEvent *) event
{
   SEL   sel;

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   sel   = 0;
   switch( [event action])
   {
   case UIEventButtonActionRepeat  :  // do keyUp: and keyDown:
      // keep UIEventKeyRepeat as action, don't create new event
      // event return value ignored,as to not accidentally prohibit keyDown:
      performSelectorIfResponding( self, @selector( keyUp:), event);
      // fall thru

   case UIEventButtonActionDown   :
      sel = @selector( keyDown:);
      break;

   case UIEventButtonActionUp :
      sel = @selector( keyUp:);
      break;
   }

   return( performSelectorIfResponding( self, sel, event));
}


- (UIInputEvent *) acceptUnicodeEvent:(UIUnicodeEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   return( performSelectorIfResponding( self, @selector( unicodeCharacterEvent:), event));
}


- (UIInputEvent *) acceptActionEvent:(UIActionEvent *) event
{
#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   return( performSelectorIfResponding( self, [event action], [event sender]));
}


- (UIInputEvent *) acceptInputEvent:(UIInputEvent *) event
{
   // Handle event myself

#ifdef EVENT_DEBUG
    MulleUILog( "Try to handle event %#@", event);
#endif
   switch( [event eventType])
   {
   case UIEventTypePresses :
      event = [self acceptKeyboardEvent:(UIKeyboardEvent *) event];
      break;

   case UIEventTypeUnicode :
      event = [self acceptUnicodeEvent:(UIUnicodeEvent *) event];
      break;

   case UIEventTypeTouches :
      event = [self acceptMouseButtonEvent:(UIMouseButtonEvent *) event];
      break;

   case UIEventTypeMotion :
      event = [self acceptMouseMotionEvent:(UIMouseMotionEvent *) event];
      break;

   case UIEventTypeScroll :
      event = [self acceptMouseScrollEvent:(UIMouseScrollEvent *) event];
      break;

   case UIEventTypeAction :
      event = [self acceptActionEvent:(UIActionEvent *) event];
      break;

   default :
      break;
   }

   return( event);
}


- (UIEvent *) acceptOtherEvent:(UIEvent *) event
{
   return( event);
}


- (BOOL) willAcceptEvent:(UIEvent *) event
{
   return( YES);
}


- (void) didAcceptEvent:(UIEvent *) event
{
}


- (UIEvent *) acceptEventWithCallbacks:(UIEvent *) event
{
   UIEvent   *result;

   //
   // when the event is changed by an event handler, we
   // reinterpret the event, otherwise done. For reinterpreted 
   // events it's nice, that willAcceptEvent:didAcceptEvent: aren't
   // nested I believe
   //
   for(;;)
   {
      if( ! [self willAcceptEvent:event])
         return( event);

      if( [event isInputEvent])
      {
//
// should not be needed as this is checked by the window/view
//         if( ! [self isUserInteractionEnabled])
//            return( event);

         result = [self acceptInputEvent:(UIInputEvent *) event];
      }
      else
         result = [self acceptOtherEvent:event];

      if( result != event)
         [self didAcceptEvent:event];
   
      // if done processing event or unchanged, we are done...
      if( ! result || result == event)
         return( result);

      event = result;
   }
}


//
// this method exists separately so you can easily break on handleEvent:
// and avoid the slew of mouse motion events. MouseMotionEvents are also
// more limited. You can't replace them with anything else than a
// mouseMotionEvent. Remember mouseMotionEvents hit a lot!
//
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) motionEvent
{
   UIMouseMotionEvent   *newEvent;
   id <UIResponder>     responder;

#if defined( EVENT_DEBUG) && defined( MOUSE_MOTION_CALLBACK_DEBUG)
   MulleUILog( "%#@", event);
#endif

   for( responder = self; responder; responder = [responder nextResponder])
   {
      // TODO: translate positions
      //       UIViewController could also be the responder here
//      if( responder != (id <UIResponder>) self)
//      {
         //
         // when the event is changed by an event handler, we
         // reinterpret the event, otherwise done. For reinterpreted
         // events it's nice, that willAcceptEvent:didAcceptEvent: aren't
         // nested I believe
         //
      for(;;)
      {
         if( ! [responder willAcceptEvent:motionEvent])
            return( motionEvent);

         newEvent = [responder acceptMouseMotionEvent:motionEvent];
         if( newEvent != motionEvent)
            [responder didAcceptEvent:motionEvent];

         // if done processing event or unchanged, we are done...
         if( ! newEvent || newEvent == motionEvent)
            break;

         motionEvent = newEvent;
      }

      if( ! newEvent)
      {
#if (defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)) && defined( MOUSE_MOTION_CALLBACK_DEBUG)
         MulleUILog( "Responder %#@ consumed event", responder);
#endif
         return( newEvent);
      }

#if (defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)) && defined( MOUSE_MOTION_CALLBACK_DEBUG)
      if( newEvent != motionEvent)
      {
         MulleUILog( "Responder %#@ changed event to %#@", responder, newEvent);
      }
#endif

#if (defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)) && defined( MOUSE_MOTION_CALLBACK_DEBUG)
      MulleUILog( "Responder %#@ did not consume event, try next", responder);
#endif
      motionEvent = newEvent;
   }
   return( motionEvent);
}


- (UIEvent *) handleEvent:(UIEvent *) event
{
   UIEvent             *newEvent;
   id <UIResponder>    responder;

#ifdef EVENT_DEBUG
   MulleUILog( "%#@", event);
#endif

   for( responder = self; responder; responder = [responder nextResponder])
   {
      // TODO: translate positions
      //       UIViewController could also be the responder here
//      if( responder != (id <UIResponder>) self)
//      {
         newEvent = [responder acceptEventWithCallbacks:event];
         if( ! newEvent)
         {
#if defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)
            MulleUILog( "Responder %#@ consumed event", responder);
#endif
            return( newEvent);
         }

#if defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)
         if( newEvent != event)
         {
            MulleUILog( "Responder %#@ changed event to %#@", responder, newEvent);
         }
#endif

#if defined( EVENT_DEBUG) || defined( FIRST_RESPONDER_DEBUG)
         MulleUILog( "Responder %#@ did not consume event, try next", responder);
#endif
         event = newEvent;
      }
//   }
   return( event);
}

PROTOCOLCLASS_END()

