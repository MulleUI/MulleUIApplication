#import "import.h"

@class UIEvent;
@class UIInputEvent;


PROTOCOLCLASS_INTERFACE0( UIResponder)

- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;

@optional

- (id<UIResponder>) nextResponder;
- (BOOL) canBecomeFirstResponder;
- (BOOL) canResignFirstResponder;

// default implementations returns event unchanged
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;

// calls -handleInputEvent for UIInputEvents
- (UIEvent *) handleEvent:(UIEvent *) event;

PROTOCOLCLASS_END()

