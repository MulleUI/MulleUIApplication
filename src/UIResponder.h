#import "import.h"

@class UIEvent;

PROTOCOLCLASS_INTERFACE0( UIResponder)

- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;

@optional

- (id<UIResponder>) nextResponder;
- (BOOL) canBecomeFirstResponder;
- (BOOL) canResignFirstResponder;

- (UIEvent *) handleEvent:(UIEvent *) event;

PROTOCOLCLASS_END()

