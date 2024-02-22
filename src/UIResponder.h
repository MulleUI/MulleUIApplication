#import "import.h"

#import "UIEvent.h"
;


// https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Responder.html
// In addition to receiving event messages, a responder can receive action 
// messages that have no target specified. (Action messages are sent by 
// controls such as buttons and controls when users manipulate them.)

PROTOCOLCLASS_INTERFACE0( UIResponder)


- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;
- (BOOL) isFirstResponder;

- (BOOL) isFirstResponderEvent:(UIEvent *) event; // default NO

// handle methods walk the responder chain
- (UIEvent *) handleEvent:(UIEvent *) event;
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event;

@optional

- (id<UIResponder>) nextResponder;
- (BOOL) canBecomeFirstResponder;
- (BOOL) canResignFirstResponder;

// default will query for implementations of one of the mouseDragged:
// methods
- (BOOL) isMouseMotionEnabled;

// - (BOOL) isUserInteractionEnabled;  // default YES

// accept methods only consider the receiver
- (BOOL) willAcceptEvent:(UIEvent *) event;
- (UIEvent *) acceptEventWithCallbacks:(UIEvent *) event;
- (UIInputEvent *) acceptInputEvent:(UIInputEvent *) event;
- (UIMouseMotionEvent *) acceptMouseMotionEvent:(UIMouseMotionEvent *) event;
- (UIInputEvent *) acceptMouseButtonEvent:(UIMouseButtonEvent *) event;
- (UIInputEvent *) acceptMouseScrollEvent:(UIMouseScrollEvent *) event;
- (UIInputEvent *) acceptKeyboardEvent:(UIKeyboardEvent *) event;
- (UIInputEvent *) acceptUnicodeEvent:(UIUnicodeEvent *) event;
- (UIInputEvent *) acceptActionEvent:(UIActionEvent *) event;
- (UIEvent *) acceptOtherEvent:(UIEvent *) event;
- (void) didAcceptEvent:(UIEvent *) event;

PROTOCOLCLASS_END()



//
// methods *optionally* implemented by UIResponder subclasses
//
@interface NSObject ( UIFutureEvents)

- (UIInputEvent *) keyUp:(UIKeyboardEvent *) event;
- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event;

- (UIInputEvent *) scrollWheel:(UIMouseScrollEvent *) event;

- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event;
- (UIInputEvent *) otherMouseDown:(UIMouseButtonEvent *) event;
- (UIInputEvent *) rightMouseDown:(UIMouseButtonEvent *) event;

- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event;
- (UIInputEvent *) otherMouseUp:(UIMouseButtonEvent *) event;
- (UIInputEvent *) rightMouseUp:(UIMouseButtonEvent *) event;

- (UIMouseMotionEvent *) mouseDragged:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) otherMouseDragged:(UIMouseMotionEvent *) event;
- (UIMouseMotionEvent *) rightMouseDragged:(UIMouseMotionEvent *) event;

@end

