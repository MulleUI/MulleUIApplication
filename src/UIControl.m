#import "UIControl.h"

#import "import-private.h"

//#define LOG_EVENTS
//#define FIRST_RESPONDER_DEBUG
// #define LOG_MOUSE_MOVE_EVENTS
#import "UIControl+DebugPrivate.h"


NS_OPTIONS_TABLE( UIControlState, 6) =
{
   NS_OPTIONS_ITEM( UIControlStateNormal),
   NS_OPTIONS_ITEM( UIControlStateHighlighted),
   NS_OPTIONS_ITEM( UIControlStateDisabled),
   NS_OPTIONS_ITEM( UIControlStateSelecting),  // need this
   NS_OPTIONS_ITEM( UIControlStateSelected),
   NS_OPTIONS_ITEM( UIControlStateFirstResponder)
};


PROTOCOLCLASS_IMPLEMENTATION( UIControl)

//
// so the protocolclass can not provide implementations, as it doesn't
// know the layout of the class that inherits
//
@dynamic action;
@dynamic click;
@dynamic state;
@dynamic target;



- (BOOL) canBecomeFirstResponder
{
   UIControlState   state;

   state = [self state];
   return( (state & UIControlStateDisabled) ? NO : YES);
}


- (void) didBecomeFirstResponder
{
   UIControlEventLog( nil, "didBecomeFirstResponder");

   setStateBit( self, UIControlStateFirstResponder, YES);
}


//
// we need to reflect and setNeedsDisplay here
//
- (void) didResignFirstResponder
{
   UIControlEventLog( nil, "didResignFirstResponder");

   setStateBit( self, UIControlStateFirstResponder, NO);
}


static inline BOOL   getStateBit( UIControl *self, UIControlState bit)
{
   UIControlState   state;

   state = [self state];
   return( (state & bit) ? YES : NO);
}


- (void) mulleToggleSelectedState
{
   UIControlState   state;

   state = [self state];
   if( state & UIControlStateSelected)
      state &= ~UIControlStateSelected;
   else
      state |= UIControlStateSelected;
   [self setState:state];
}


- (void) mulleToggleHighlightedState
{
   UIControlState   state;

   state = [self state];
   if( state & UIControlStateHighlighted)
      state &= ~UIControlStateHighlighted;
   else
      state |= UIControlStateHighlighted;
   [self setState:state];
}


static void   setStateBit( UIControl *self, UIControlState bit, BOOL flag)
{
   UIControlState   state;
   UIControlState   newState;

   state = [self state];
   if( flag)
      newState = state | bit;
   else
      newState = state & ~bit;

   if( newState != state)
   {
      /*
       H | D | S | F |
      ---|---|---|---|--------------
       0 | 0 | 0 | 0 |
       1 | 0 | 0 | 0 |
       0 | 1 | 0 | 0 |
       1 | 1 | 0 | 0 | *impossible*
       0 | 0 | 1 | 0 |
       1 | 0 | 1 | 0 |
       0 | 1 | 1 | 0 |
       1 | 1 | 1 | 0 | *impossible*
       0 | 0 | 0 | 1 |
       1 | 0 | 0 | 1 |
       0 | 1 | 0 | 1 | *impossible*
       1 | 1 | 0 | 1 | *impossible*
       0 | 0 | 1 | 1 |
       1 | 0 | 1 | 1 |
       0 | 1 | 1 | 1 | *impossible*
       1 | 1 | 1 | 1 | *impossible*
      */
      assert( state != (UIControlStateHighlighted|UIControlStateDisabled));
      assert( state != (UIControlStateHighlighted|UIControlStateDisabled|UIControlStateSelected));
      assert( state != (UIControlStateDisabled|UIControlStateFirstResponder));
      assert( state != (UIControlStateHighlighted|UIControlStateDisabled|UIControlStateFirstResponder));
      assert( state != (UIControlStateDisabled|UIControlStateSelected|UIControlStateFirstResponder));
      assert( state != (UIControlStateHighlighted|UIControlStateDisabled|UIControlStateSelected|UIControlStateFirstResponder));

      [self setState:newState];
   }
}


- (BOOL) isHighlighted
{
   return( getStateBit( self, UIControlStateHighlighted));
}


- (void) setHighlighted:(BOOL) flag
{
   setStateBit( self, UIControlStateHighlighted, flag);
}


- (BOOL) isEnabled
{
   return( ! getStateBit( self, UIControlStateDisabled));
}


- (void) setEnabled:(BOOL) flag;
{
   setStateBit( self, UIControlStateDisabled, ! flag);
}


- (BOOL) isSelected
{
   return( getStateBit( self, UIControlStateSelected));
}


- (void) setSelected:(BOOL) flag;
{
   setStateBit( self, UIControlStateSelected, flag);
}



- (BOOL) isSelecting
{
   return( getStateBit( self, UIControlStateSelected));
}


- (void) setSelecting:(BOOL) flag;
{
   setStateBit( self, UIControlStateSelecting, flag);
}


- (void) sendActionOn:(UIControlEvents) mask
{
   [self setEventMask:mask & (UIControlEventLeftMouseDown|UIControlEventLeftMouseUp|UIControlEventLeftMouseDragged)];
}


- (BOOL) reflectState
{
   NSUInteger   state;
   NSUInteger   reflectedState;

   state          = [self state];
   reflectedState = [self reflectedState];
   UIControlEventLog( nil, "%s", NS_OPTIONS_PRINT( UIControlState, state));

   if( state != reflectedState)
   {
      [self setReflectedState:state];
      return( YES);
   }
   return( NO);
}


- (BOOL) willAcceptEvent:(UIEvent *) event
{
   assert( [event isKindOfClass:[UIEvent class]]);

   UIControlEventLog( event, "%#@", event);
   UIControlMouseMotionEventLog( event, "%#@", event);

   if( [event isInputEvent] && ! [self isEnabled])
      return( NO);
   return( YES);
}


- (void) didAcceptEvent:(UIEvent *) event
{
   assert( [event isKindOfClass:[UIEvent class]]);

   UIControlEventLog( event, "%#@", event);
   UIControlMouseMotionEventLog( event, "%#@", event);

   if( ! [event isInputEvent])
      return;

   [self reflectState];
   [self setNeedsDisplay];
}


- (UIInputEvent *) performClickAndTargetActionCallbacks:(UIInputEvent *) event
                                          fallbackEvent:(UIInputEvent *) fallbackEvent
{
   UIControlClickHandler  *click;
   SEL                    sel;
   id                     target;
   struct UIInputState    inputState;

   assert( [self isEnabled]);

   // fire C callback if we have it
   click = [self click];
   if( click)
      event = (*click)( self, event);
   if( ! event)
      return( event);

   // do target/action mechanism
   sel = [self action];
   if( ! sel)
      return( fallbackEvent);
   
   target = [self target];
   if( target)
   {
      [target performSelector:sel
                   withObject:self];
      event = nil;
   }
   else
   {
      // make this an action event, if no target is specified
      // this becomes something like: - (IBAction) doStuff:(id) for the nil
      // receiver
      inputState = [event inputState];
      event      = [[[UIActionEvent alloc] initWithInputState:&inputState
                                                       action:sel 
                                                       sender:self] autorelease];
  }
  return( event);
}


- (UIInputEvent *) performClickAndTargetActionCallbacks:(UIInputEvent *) event
{
   [self mulleToggleSelectedState];
   return( [self performClickAndTargetActionCallbacks:event
                                        fallbackEvent:nil]);
}                                          


// @method_alias( mouseUp:, mouseDown:);

// if we are first responder, by keyboard event or programatically, then
// this mouseDown: event may not hit us really. So we check this and if
// its outside, we just return it. We keep firstResponder though in case
// nothing has been hit
//
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   UIInputEvent                  *inputEvent;
   UIControlSelectionBehaviour   behaviour;
   NSUInteger                    eventMask;

   UIControlEventLog( event, "%#@", event);

   // this should be a safe bet in all cases
   behaviour = [self selectionBehaviour];

   if( ! (behaviour & UIControlSelectionBehaviourBitFirstResponder))
      [self becomeFirstResponder];

   if( behaviour & UIControlSelectionBehaviourBitHighlight)
      [self setHighlighted:YES];

   if( ! (behaviour & UIControlSelectionBehaviourBitSelecting))
      [self setSelecting:YES];


   switch( behaviour & 0x3)
   {
   case UIControlSelectionBehaviourBitSelect   : [self setSelected:YES]; break;
   case UIControlSelectionBehaviourBitDeselect : [self setSelected:NO]; break;
   case UIControlSelectionBehaviourBitsToggle  : [self mulleToggleSelectedState]; break;
   }

   eventMask  = [self eventMask];
   inputEvent = (eventMask & UIControlEventLeftMouseDown)
                ? [self performClickAndTargetActionCallbacks:event]
                : nil;

// MEMO: done in didAcceptEvent:

//   [self reflectState];
//   [self setNeedsDisplay];

   return( inputEvent);
}


- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event
{
   UIInputEvent   *inputEvent;

   UIControlMouseTrackingEventLog( event, "%#@", event);
   // remove previous mouseDown state change

   if( [self eventMask] & UIControlEventLeftMouseDragged)
   {
      inputEvent = [self performClickAndTargetActionCallbacks:event];
      // for mouseDragged you must return nil
      // also don't mind if event is returned though not type correct
      assert( inputEvent == nil || inputEvent == (UIInputEvent *) event);
      MULLE_C_UNUSED( inputEvent);
   }

   return( nil);
}


//
// as we are the firstResponder we must be getting the up event
//
- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   UIInputEvent                  *inputEvent;
   UIControlSelectionBehaviour   behaviour;
   NSUInteger                    eventMask;

   UIControlEventLog( event, "%#@", event);

   // this should be a safe bet in all cases
   behaviour = [self selectionBehaviour] >> 8;
   if( ! (behaviour & UIControlSelectionBehaviourBitSelecting))
      [self setSelecting:NO];
   if( behaviour & UIControlSelectionBehaviourBitHighlight)
      [self setHighlighted:NO];

   // do this first, so that event can keep firstResponder, if so desired
   // can we get a mouseUp: event without a previous mouseDown: ?
   // unlikely. but then we don't do anything
   if( ! getStateBit( self, UIControlStateFirstResponder))
      return( nil);

   if( ! (behaviour & UIControlSelectionBehaviourBitFirstResponder))
      [self resignFirstResponder];

   switch( behaviour & 0x3)
   {
   case UIControlSelectionBehaviourBitSelect    : [self setSelected:YES]; break;
   case UIControlSelectionBehaviourBitDeselect  : [self setSelected:NO]; break;
   case UIControlSelectionBehaviourBitsToggle   : [self mulleToggleSelectedState]; break;
   }

   eventMask  = [self eventMask];
   inputEvent = (eventMask & UIControlEventLeftMouseUp)
                ? [self performClickAndTargetActionCallbacks:event]
                : nil;


// MEMO: done in didAcceptEvent:
//   [self reflectState];
//   [self setNeedsDisplay];
   return( inputEvent);
}


- (void) mouseEntered:(UIMouseTrackingEvent *) event
{
   UIControlMouseTrackingEventLog( event, "%#@", event);

   [self setHighlighted:YES]; // what if already set ???
   [self reflectState];
}


- (void) mouseMoved:(UIMouseTrackingEvent *) event
{
   UIControlMouseTrackingEventLog( event, "%#@", event);
}


- (void) mouseExited:(UIMouseTrackingEvent *) event
{
   UIControlMouseTrackingEventLog( event, "%#@", event);

   [self setHighlighted:NO]; // what if already set ???
   [self reflectState];
}


/*
 * Keyboard
 */
// @method_alias( keyUp:, keyDown:);



// we swallow those I guess
- (UIInputEvent *) keyUp:(UIKeyboardEvent *) event
{
   UIControlEventLog( event, "%#@", event);

   return( nil);
}


- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   UIControlEventLog( event, "%#@", event);

   return( nil);
}


- (BOOL) __isUIControl
{
   return( YES);
}


PROTOCOLCLASS_END()



@implementation NSObject( UIControl)

- (BOOL) __isUIControl
{
   return( NO);
}

// hmm
- (NSUInteger) debuggingFlags
{
   return( 0);
}


@end

