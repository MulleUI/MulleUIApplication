#import "UIResponder.h"

#import "import-private.h"

#import "import-project.h"


// enums compatible to UIView/UIWindow
enum
{
   UIResponderDebugEvent            = 0x000002,

   UIResponderDebugMouseMotionEvent = 0x001000000
};


#if ! defined( UI_RESPONDER_LOG_DISABLED)

#define UIResponderEventLog( format, ...)                                  \
do                                                                         \
{                                                                          \
   if( Self._debuggingFlags & UIResponderDebugEvent)                         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,       \
                                       (char *) format, ## __VA_ARGS__);   \
}                                                                          \
while( 0);

#define UIResponderMouseMotionEventLog( format, ...)                       \
do                                                                         \
{                                                                          \
   if( Self._debuggingFlags & UIResponderDebugMouseMotionEvent)              \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,       \
                                       (char *) format, ## __VA_ARGS__);   \
}                                                                          \
while( 0);


#else

#define UIResponderEventLog( format, ...)               do {} while( 0)
#define UIResponderMouseMotionEventLog( format, ...)    do {} while( 0)

#endif




PROTOCOLCLASS_IMPLEMENTATION( UIResponder)

static struct
{
   NSUInteger   _debuggingFlags;
} Self;


// have no initalize
+ (void) load
{
   char   *s;

   // don't run again for subclass
   if( MulleObjCClassGetID( self) != @selector( UIResponder))
      return;

   s = getenv( MULLE_C_STRINGIFY( UIResponder) "DebuggingFlags");
   if( ! s)
      s = getenv( "UIDebuggingFlags");
   if( s)
      Self._debuggingFlags = strtol( s, NULL, 0);
}


+ (void) setDebuggingFlags:(NSUInteger) flag    MULLE_OBJC_THREADSAFE_METHOD
{
   Self._debuggingFlags = flag;
}


- (id <UIResponder>) nextResponder
{
   return( nil);
}


- (BOOL) becomeFirstResponder
{
   return( NO);
}


- (BOOL) resignFirstResponder
{
   return( YES);
}


- (BOOL) isFirstResponder;
{
   return( NO);
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
// the default is permissive, allowing mouse motion events, but if we get
// a mouse down event, the default will resign responder
// 
- (BOOL) isFirstResponderEvent:(UIEvent *) event
{
   NSUInteger          eventType;
   UIMouseButtonEvent  *buttonEvent;

   eventType = [event eventType];

   UIResponderEventLog( "%#@", event);

   if( eventType == UIEventTypeTouches)
   {
      buttonEvent = (UIMouseButtonEvent *) event;
      if( [buttonEvent action] == UIEventButtonActionDown)
      {
         [self resignFirstResponder];
         return( NO);
      }
   }
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

   UIResponderEventLog( "%#@", event);

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

   UIResponderMouseMotionEventLog( "%#@", event);

   sel   = 0;
   state = [event buttonStates];
   if( state)
   {
      sel = @selector( mouseDragged:);
      if( ! (state & UIEventMouseButtonLeft))
      {
         if( state & UIEventMouseButtonRight)
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

   UIResponderEventLog( "%#@", event);

   // scrollWheel: taken from AppKit
   // https://developer.apple.com/documentation/appkit/nsscrollview/1403494-scrollwheel?language=objc
   //
   return( performSelectorIfResponding( self, @selector( scrollWheel:), event));
}


- (UIInputEvent *) acceptKeyboardEvent:(UIKeyboardEvent *) event
{
   SEL   sel;

   UIResponderEventLog( "%#@", event);

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
   UIResponderEventLog( "%#@", event);

   return( performSelectorIfResponding( self, @selector( unicodeCharacterEvent:), event));
}


- (UIInputEvent *) acceptActionEvent:(UIActionEvent *) event
{
   SEL   sel;
   id    sender;

   UIResponderEventLog( "%#@", event);

   sel = [event action];
   if( ! sel || ! [self respondsToSelector:sel])
      return( event);

   //
   // this calls: - (IBAction) doStuff:(id) sender
   // No way to change the event
   //
   sender = [event sender];
   MulleObjCObjectPerformSelector( self, sel, sender);
   return( nil);
}


- (UIInputEvent *) acceptInputEvent:(UIInputEvent *) event
{
   // Handle event myself

   UIResponderEventLog( "Try to handle event %#@", event);

   switch( [event eventType])
   {
   case UIEventTypePresses :
      event = [self acceptKeyboardEvent:(UIKeyboardEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
      break;

   case UIEventTypeUnicode :
      event = [self acceptUnicodeEvent:(UIUnicodeEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
      break;

   case UIEventTypeTouches :
      event = [self acceptMouseButtonEvent:(UIMouseButtonEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
      break;

   case UIEventTypeMotion :
      event = [self acceptMouseMotionEvent:(UIMouseMotionEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
      break;

   case UIEventTypeScroll :
      event = [self acceptMouseScrollEvent:(UIMouseScrollEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
      break;

   case UIEventTypeAction :
      event = [self acceptActionEvent:(UIActionEvent *) event];
      assert( ! event || [event isKindOfClass:[UIInputEvent class]]);
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


- (BOOL) isMouseMotionEnabled
{
   return( [self respondsToSelector:@selector( mouseDragged:)]
           || [self respondsToSelector:@selector( otherMouseDragged:)]
           || [self respondsToSelector:@selector( rightMouseDragged:)]);
}


- (UIEvent *) acceptEventWithCallbacks:(UIEvent *) event
{
   UIEvent   *result;

   assert( [event isKindOfClass:[UIEvent class]]);

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
         assert( ! result || [result isKindOfClass:[UIEvent class]]);
      }
      else
      {
         result = [self acceptOtherEvent:event];
         assert( ! result || [result isKindOfClass:[UIEvent class]]);
      }

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

   UIResponderMouseMotionEventLog( "%#@", motionEvent);

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
         UIResponderMouseMotionEventLog( "Responder %#@ consumed event", responder);
         return( newEvent);
      }

      if( newEvent != motionEvent)
      {
         UIResponderMouseMotionEventLog( "Responder %#@ changed event to %#@", responder, newEvent);
      }

      UIResponderMouseMotionEventLog( "Responder %#@ did not consume event, try next", responder);

      motionEvent = newEvent;
   }
   return( motionEvent);
}


- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
{
   return( nil);  // let it be handled by handleEvent: below
}


- (UIEvent *) handleEvent:(UIEvent *) event
{
   UIEvent             *newEvent;
   id <UIResponder>    responder;

   UIResponderEventLog( "%#@", event);

   for( responder = self; responder; responder = [responder nextResponder])
   {
      // TODO: translate positions
      //       UIViewController could also be the responder here
//      if( responder != (id <UIResponder>) self)
//      {
         newEvent = [responder acceptEventWithCallbacks:event];
         if( ! newEvent)
         {
            UIResponderEventLog( "Responder %#@ consumed event", responder);
            return( newEvent);
         }

         if( newEvent != event)
         {
            UIResponderEventLog( "Responder %#@ changed event to %#@", responder, newEvent);
         }

         UIResponderEventLog( "Responder %#@ did not consume event, try next", responder);
         event = newEvent;
      }
//   }
   return( event);
}

PROTOCOLCLASS_END()

