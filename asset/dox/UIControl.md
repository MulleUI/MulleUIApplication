# UIControl Mouse Handling in MulleUI

## Overview

UIControl is a **protocol/mixin** (`@mixin`), not a class. Views that want
target-action behaviour adopt `<UIControl>` and use the provided macros to
inject the required ivars and properties. This document describes how mouse
events flow through UIControl and how to configure a control so clicks actually
work.

---

## Adoption Boilerplate

```objc
@interface MyButton : UIView <UIControl>
{
   UIControlIvars;   // injects _state, _eventMask, _target, _action, etc.
}
UIControlProperties; // declares the corresponding @property statements
@end

@implementation MyButton

- (instancetype) initWithLayer:(id<UILayer>) layer frame:(CGRect) frame
{
   self = [super initWithLayer:layer frame:frame];
   if( self)
   {
      UIControlInit( self);
   }
   return( self);
}

@end
```

---

## UIControlInit – What It Actually Does

The `UIControlInit( self)` macro is tiny but critical:

```c
#define UIControlInit( self)                                      \
   do                                                             \
   {                                                              \
      if( self)                                                   \
         (self)->_eventMask = UIControlEventLeftMouseDown;        \
   }                                                              \
   while( 0)
```

After `UIControlInit( self)` the control:
- **has an `eventMask` of `UIControlEventLeftMouseDown`**
- `_selectionBehaviour` is **zero** (`UIControlStateNormal`)
- `_target`, `_action`, `_click` are all **nil / NULL**

This means:
- **`mouseDown:` will trigger `performClickAndTargetActionCallbacks:`** because `UIControlEventLeftMouseDown` is set.
- **`mouseUp:` will NOT trigger anything** because `UIControlEventLeftMouseUp` is **not** set.
- **No highlighting, selecting, or first-responder behaviour** is configured unless you set `_selectionBehaviour`.

---

## UIControlEvents Mask

The `eventMask` filters which events invoke `performClickAndTargetActionCallbacks:`.

```objc
typedef NS_ENUM( NSUInteger, UIControlEvents)
{
   UIControlEventLeftMouseDown      = 0x00001,
   UIControlEventMiddleMouseDown    = 0x00002,
   UIControlEventRightMouseDown     = 0x00004,
   UIControlEventOtherMouseDown     = 0x00008,

   UIControlEventLeftMouseUp        = 0x00010,
   UIControlEventMiddleMouseUp      = 0x00020,
   UIControlEventRightMouseUp       = 0x00040,
   UIControlEventOtherMouseUp       = 0x00080,

   UIControlEventLeftMouseDragged   = 0x00100,
   UIControlEventMiddleMouseDragged = 0x00200,
   UIControlEventRightMouseDragged  = 0x00400,
   UIControlEventOtherMouseDragged  = 0x00800,
   // ... more entered/exited/scroll/key variants
};
```

### Typical eventMask configurations

| Desired behaviour | eventMask |
|---|---|
| Fire on mouse-down only (tap) | `UIControlEventLeftMouseDown` |
| Fire on mouse-up only (button) | `UIControlEventLeftMouseUp` |
| Fire on both | `UIControlEventLeftMouseDown \| UIControlEventLeftMouseUp` |
| Drag support | add `UIControlEventLeftMouseDragged` |

Use `-sendActionOn:` or assign `_eventMask` directly.

---

## Selection Behaviour (The Secret to State Management)

`UIControl` packs two 8-bit configurations into one `NSUInteger`: the low byte
describes what happens on **mouseDown**, the high byte (shifted by 8) describes
what happens on **mouseUp**.

### Bit definitions

```c
#define UIControlSelectionBehaviourBitSelect         0x1   // set selected = YES
#define UIControlSelectionBehaviourBitDeselect       0x2   // set selected = NO
#define UIControlSelectionBehaviourBitsToggle        0x3   // toggle selected bit

#define UIControlSelectionBehaviourBitHighlight      0x10  // set highlighted
#define UIControlSelectionBehaviourBitSelecting      0x20  // set selecting state
#define UIControlSelectionBehaviourBitFirstResponder 0x40  // manage firstResponder
```

### Pack format

```
behaviour = (mouseDownBits) | ((mouseUpBits) << 8)
```

### Predefined enumerations

```objc
typedef NS_ENUM( NSUInteger, UIControlSelectionBehaviour)
{
   UIControlSelectionBehaviourPush =
      0x1 | ((0x2 | 0x10) << 8),   // select on down, deselect+highlight on up

   UIControlSelectionBehaviourRelease =
      0x0 | ((0x1 | 0x10) << 8),   // stays "selecting" until up, then select+dehighlight

   UIControlSelectionBehaviourPushSwitch =
      0x3 | ((0x0 | 0x10) << 8),   // toggle on down

   UIControlSelectionBehaviourReleaseSwitch =
      0x0 | ((0x3 | 0x10) << 8),   // toggle on up
};
```

### What each preset does

| Preset | mouseDown | mouseUp |
|---|---|---|
| **Push** | `selected = YES`, `highlighted = YES`, `selecting = YES` | `selecting = NO`, `highlighted = NO` (deselects) |
| **Release** | `highlighted = YES`, `selecting = YES` | `selected = YES`, `selecting = NO`, `highlighted = NO` |
| **PushSwitch** | `selected = toggle`, `highlighted = YES` | (nothing) |
| **ReleaseSwitch** | `highlighted = YES` | `selected = toggle`, `highlighted = NO` |

If the bit `UIControlSelectionBehaviourBitFirstResponder` is set in a phase, that
phase **skips** `becomeFirstResponder` / `resignFirstResponder`.

---

## Exact mouseDown: Flow

```objc
- (UIInputEvent *) mouseDown:(UIMouseButtonEvent *) event
{
   UIControlSelectionBehaviour   behaviour;
   NSUInteger                    eventMask;
   UIInputEvent                  *inputEvent;

   behaviour  = [self selectionBehaviour];        // low byte = down phase

   if( ! (behaviour & UIControlSelectionBehaviourBitFirstResponder))
      [self becomeFirstResponder];

   if( behaviour & UIControlSelectionBehaviourBitHighlight)
      [self setHighlighted:YES];

   if( ! (behaviour & UIControlSelectionBehaviourBitSelecting))
      [self setSelecting:YES];

   switch( behaviour & 0x3)
   {
   case UIControlSelectionBehaviourBitSelect   : [self setSelected:YES]; break;
   case UIControlSelectionBehaviourBitDeselect : [self setSelected:NO];  break;
   case UIControlSelectionBehaviourBitsToggle  : [self mulleToggleSelectedState]; break;
   }

   eventMask  = [self eventMask];
   inputEvent = (eventMask & UIControlEventLeftMouseDown)
                ? [self performClickAndTargetActionCallbacks:event]
                : nil;

   // reflectState + setNeedsDisplay are handled by didAcceptEvent:
   return( inputEvent);
}
```

---

## Exact mouseUp: Flow

```objc
- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event
{
   UIControlSelectionBehaviour   behaviour;
   NSUInteger                    eventMask;
   UIInputEvent                  *inputEvent;

   behaviour = [self selectionBehaviour] >> 8;     // high byte = up phase

   if( ! (behaviour & UIControlSelectionBehaviourBitSelecting))
      [self setSelecting:NO];

   if( behaviour & UIControlSelectionBehaviourBitHighlight)
      [self setHighlighted:NO];

   // --- CRITICAL GUARD ---
   // If the control is NOT firstResponder, mouseUp is ignored entirely.
   // This happens when the mouse left the view between down and up, or
   // when firstResponder was stolen.
   if( ! getStateBit( self, UIControlStateFirstResponder))
      return( nil);

   if( ! (behaviour & UIControlSelectionBehaviourBitFirstResponder))
      [self resignFirstResponder];

   switch( behaviour & 0x3)
   {
   case UIControlSelectionBehaviourBitSelect   : [self setSelected:YES]; break;
   case UIControlSelectionBehaviourBitDeselect : [self setSelected:NO];  break;
   case UIControlSelectionBehaviourBitsToggle  : [self mulleToggleSelectedState]; break;
   }

   eventMask  = [self eventMask];
   inputEvent = (eventMask & UIControlEventLeftMouseUp)
                ? [self performClickAndTargetActionCallbacks:event]
                : nil;

   return( inputEvent);
}
```

---

## Debugging

Enable UIControl event logging at runtime:

```objc
[[UIApplication sharedInstance] setDebuggingFlags:UIApplicationDebugEvent];
```

Or via environment:

```bash
export UIApplicationDebuggingFlags=<value>
```

This emits `UIControlEventLog()` and `UIControlMouseTrackingEventLog()` traces
showing exactly which events hit which controls and whether they were consumed.

---

## Common Misconfigurations

### 1. No action on mouseUp

**Symptom:** Click feels like it fires on press, not release.  
**Cause:** `eventMask` only contains `UIControlEventLeftMouseDown`.  
**Fix:**

```objc
UIControlInit( self);
_eventMask = UIControlEventLeftMouseDown | UIControlEventLeftMouseUp;
```

### 2. No action at all

**Symptom:** Control is completely unresponsive.  
**Causes:**
- `userInteractionEnabled == NO` on the control or an ancestor.
- `eventMask == 0` (wiped out after `UIControlInit`).
- `mouseUp:` never called because the control lost `firstResponder` before
  release (e.g. another view intercepted it).
- Control's view frame is zero or off-screen.

### 3. Highlight stuck on

**Symptom:** Control stays highlighted after release.  
**Cause:** `selectionBehaviour` lacks the `UIControlSelectionBehaviourBitHighlight`
bit in the mouseUp phase, or `mouseUp:` was never delivered.

### 4. Selection toggles on every click

**Symptom:** Button acts like a switch.  
**Cause:** Accidentally used `UIControlSelectionBehaviourPushSwitch` or
`UIControlSelectionBehaviourBitsToggle` instead of plain `UIControlSelectionBehaviourBitSelect`.

---

## Summary Checklist for a Working Clickable Control

1. Adopt `<UIControl>` and add `UIControlIvars` / `UIControlProperties`.
2. Call `UIControlInit( self)` during init.
3. Set `_selectionBehaviour` if you want automatic highlight/select state.
4. Set `_eventMask` to the events that should fire your action.
5. Set target + action (or `click` callback):
   ```objc
   [control setTarget:controller];
   [control setAction:@selector( buttonClicked:)];
   ```
6. Ensure `userInteractionEnabled` is `YES` (default is YES for UIView).
7. Ensure the view has a non-zero frame.

---

## See Also

- `MulleUIApplication/src/UIControl.h` — definition of ivars, properties, macros
- `MulleUIApplication/src/UIControl.m` — actual `mouseDown:`, `mouseUp:` implementation
- `MulleUIPureWindow/dox/uievent-chain.svg` — full event-dispatch diagram
- Event-handling skill: `.opencode/skills/mulle-event/`
