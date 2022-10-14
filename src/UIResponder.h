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

- (UIEvent *) handleEvent:(UIEvent *) event;

@optional

- (id<UIResponder>) nextResponder;
- (BOOL) canBecomeFirstResponder;
- (BOOL) canResignFirstResponder;

- (BOOL) isUserInteractionEnabled;  // default YES

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

- (UIInputEvent *) mouseDragged:(UIMouseMotionEvent *) event;
- (UIInputEvent *) otherMouseDragged:(UIMouseMotionEvent *) event;
- (UIInputEvent *) rightMouseDragged:(UIMouseMotionEvent *) event;

@end

