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

PROTOCOLCLASS_END()

