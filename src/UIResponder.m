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

// does not handle event by default
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event
{
   return( event);
}


// does not handle event by default
- (UIEvent *) handleEvent:(UIEvent *) event
{
   if( [event isInputEvent])
      return( [self handleInputEvent:(UIInputEvent *) event]);

   // fall back to UIResponder
   return( event);
}

PROTOCOLCLASS_END()

