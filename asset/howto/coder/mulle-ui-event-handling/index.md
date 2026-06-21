<!-- keywords: mulle-ui-event-handling, events, mouse, keyboard, scroll, mouseDown, keyDown, responder, UIResponder, UIControl, UIEvent, first-responder -->
# mulle-ui-event-handling

Use this topic when you need to handle mouse, keyboard, or scroll input. Covers the responder pattern, control callbacks, and first-responder mechanics.

## Understand first

```bash
mulle-sde api apropos UIResponder
mulle-sde api apropos UIControl
mulle-sde api apropos UIEvent
mulle-sde code search mouseDown:
mulle-sde code search becomeFirstResponder
```

## Local references (MulleUIApplication)

- `src/UIEvent.h`
- `src/UIResponder.h`
- `src/UIControl.h`
- `src/UIApplication+UIEvent.m`

## Handler cheatsheet

### Mouse handlers

| Method | When it fires |
|--------|--------------|
| `mouseDown:(UIMouseButtonEvent *)event` | Mouse button pressed |
| `mouseUp:(UIMouseButtonEvent *)event` | Mouse button released |
| `mouseDragged:(UIMouseButtonEvent *)event` | Mouse moved with button held |
| `scrollWheel:(UIMouseScrollEvent *)event` | Scroll wheel or trackpad |

### Keyboard handlers

| Method | When it fires |
|--------|--------------|
| `keyDown:(UIKeyboardEvent *)event` | Key pressed |
| `keyUp:(UIKeyboardEvent *)event` | Key released |

### Return value contract

Return `nil` to **consume** the event. Return the event to **pass it up** the responder chain.

```objc
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   CGPoint   point;

   point = [event locationInView:self];
   [self setNeedsDisplay];
   return( nil);   // consumed
}
```

## First responder (required for keyboard)

Keyboard events only arrive at the first responder. Three steps:

```objc
// 1. Allow it
- (BOOL) canBecomeFirstResponder
{
   return( YES);
}

// 2. Claim it (e.g. on click)
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   [self becomeFirstResponder];
   return( nil);
}

// 3. Handle keys
- (UIInputEvent *) keyDown:(UIKeyboardEvent *) event
{
   // process key...
   return( nil);
}
```

## UIControl pattern

For control-like objects (buttons, toggles), use the mixin:

```objc
@interface MyControl : NSObject <UIControl>
{
   UIControlIvars;
}
UIControlProperties;
@end

- (instancetype) init
{
   if( self = [super init])
      UIControlInit( self);
   return( self);
}
```

- Default event mask is `UIControlEventLeftMouseDown` only. Widen it for mouse-up, key, or scroll events.
- Callback slot is `UIControlClickHandler *click` (C function pointer) or target/action.
- Keep selection behavior in `UIControlSelectionBehaviour`.

## Getting event coordinates

```objc
CGPoint   point;

point = [event locationInView:self];   // local coordinates
```

## Scroll modifiers

`UIMouseScrollEvent` applies local modifier semantics:
- Alt swaps axes
- Control enables fine scroll
- Shift enables coarse scroll
