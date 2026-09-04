//
//  UIResponder.h
//  MulleUIApplication
//
//  Copyright (c) 2019 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "import.h"

#import "UIEvent.h"





// https://developer.apple.com/library/archive/documentation/General/Conceptual/Devpedia-CocoaApp/Responder.html
// In addition to receiving event messages, a responder can receive action 
// messages that have no target specified. (Action messages are sent by 
// controls such as buttons and controls when users manipulate them.)

@mixin UIResponder < NSObject>

@optional
- (BOOL) becomeFirstResponder;         // default: NO
- (BOOL) resignFirstResponder;         // default: YES
- (BOOL) isFirstResponder;             // default: NO
- (BOOL) canBecomeFirstResponder;      // default: NO
- (BOOL) canResignFirstResponder;      // default: YES

- (BOOL) isFirstResponderEvent:(UIEvent *) event; // default NO

// handle methods walk the responder chain
- (UIEvent *) handleEvent:(UIEvent *) event;
- (UIInputEvent *) handleInputEvent:(UIInputEvent *) event;
- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event;


- (id <UIResponder>) nextResponder;

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

@end



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


