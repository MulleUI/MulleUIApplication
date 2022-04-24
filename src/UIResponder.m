#import "UIResponder.h"

#import "import-private.h"


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
- (UIEvent *) handleEvent:(UIEvent *) event
{
   return( event);
}

PROTOCOLCLASS_END()

