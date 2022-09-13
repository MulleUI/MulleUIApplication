#import "UIResponder.h"

#import "import-private.h"

#import "UIEvent.h"


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

- (BOOL) canBecomeModalResponder
{
   return( NO);
}

- (BOOL) canResignModalResponder
{
   return( YES);
}


static UIInputEvent   *performSelectorIfResponding( UIResponder *self, 
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


- (UIInputEvent *) handleMouseButtonEvent:(UIMouseButtonEvent *) event
{
   SEL   sel;
   int   action;
   int   button;

   sel    = 0;
   action = [event action];
   button = [event button];

   // for support of other buttons, subclass and override
   // handleMouseButtonEvent:
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
- (UIInputEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
{
   uint64_t   state;
   SEL        sel;

   assert( [event isKindOfClass:[UIMouseMotionEvent class]]);

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


- (UIInputEvent *) handleMouseScrollEvent:(UIMouseScrollEvent *) event
{
   assert( [event isKindOfClass:[UIMouseScrollEvent class]]);

   // scrollWheel: taken from AppKit
   // https://developer.apple.com/documentation/appkit/nsscrollview/1403494-scrollwheel?language=objc
   //
   event = performSelectorIfResponding( self, @selector( scrollWheel:), event);

   return( event);
}


- (UIInputEvent *) handleKeyboardEvent:(UIKeyboardEvent *) event
{
   uint64_t   state;
   SEL        sel;

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


- (UIInputEvent *) handleUnicodeEvent:(UIUnicodeEvent *) event
{
   return( performSelectorIfResponding( self, @selector( unicodeCharacterEvent:), event));
}


- (UIInputEvent *) handleActionEvent:(UIActionEvent *) event
{
   return( performSelectorIfResponding( self, [event action], [event sender]));
}


- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
{
   // Handle event myself

#ifdef EVENT_DEBUG
    MulleUILog( "Try to handle event %#@", event);
#endif
   switch( [event eventType])
   {
   case UIEventTypePresses :
      event = [self handleKeyboardEvent:(UIKeyboardEvent *) event];
      break;

   case UIEventTypeUnicode :
      event = [self handleUnicodeEvent:(UIUnicodeEvent *) event];
      break;

   case UIEventTypeTouches :
      event = [self handleMouseButtonEvent:(UIMouseButtonEvent *) event];
      break;

   case UIEventTypeMotion :
      event = [self handleMouseMotionEvent:(UIMouseMotionEvent *) event];
      break;

   case UIEventTypeScroll :
      event = [self handleMouseScrollEvent:(UIMouseScrollEvent *) event];
      break;

   case UIEventTypeAction :
      event = [self handleActionEvent:(UIActionEvent *) event];
      break;

   default :
      break;
   }

   return( event);
}


- (UIEvent *) handleOtherEvent:(UIEvent *) event
{
   return( event);
}


- (BOOL) willHandleEvent:(UIEvent *) event
{
   return( YES);
}


- (void) didHandleEvent:(UIEvent *) event
{
}


- (BOOL) isUserInteractionEnabled
{
   return( YES);
}


- (UIEvent *) handleEvent:(UIEvent *) event
{
   UIEvent   *result;

   //
   // when the event is changed by an event handler, we
   // reinterpret the event, otherwise done. For reinterpreted 
   // events it's nice, that willHandleEvent:didHandleEvent: aren't
   // nested I believe
   //
   for(;;)
   {
      if( [event isInputEvent])
      {
         if( ! [self isUserInteractionEnabled])
            return( event);

         if( ! [self willHandleEvent:event])
            return( event);

         result = [self handleInputEvent:(UIInputEvent *) event];
      }
      else
      {
         if( ! [self willHandleEvent:event])
            return( event);

         result = [self handleOtherEvent:event];
      }

      if( result != event)
         [self didHandleEvent:event];
   
      if( ! result || result == event)
         return( result);

      event = result;
   }
}

PROTOCOLCLASS_END()

