#import "import.h"

#import "UIResponder.h"


@class UIInputEvent;
@class UIMouseButtonEvent;
@class UIMouseTrackingEvent;


// used by UIControl
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
   UIControlEventRightMouseDragged  = 0x00200,
   UIControlEventMiddleMouseDragged = 0x00400,
   UIControlEventOtherMouseDragged  = 0x00800,

   UIControlEventMouseEntered       = 0x01000,
   UIControlEventMouseExited        = 0x02000,
   UIControlEventKeyDown            = 0x04000,
   UIControlEventKeyUp              = 0x08000,

   UIControlEventScrollWheel        = 0x10000,
   UIControlEventAnyEvent           = ~0UL
};



typedef NS_OPTIONS( NSUInteger, UIControlState)
{
	UIControlStateNormal      = 0x0,

   // these 16 combinations are handled by MulleControlBackgroundPaint
	UIControlStateHighlighted = 0x1,
	UIControlStateDisabled    = 0x2,
	UIControlStateSelected    = 0x4,
   UIControlStateSelecting   = 0x8,

   UIControlStateFocused     = 0x10
};


extern NS_OPTIONS_TABLE( UIControlState, 6);

static inline char   *UIControlStateUTF8String( NSUInteger state)
{
   return( NS_OPTIONS_PRINT( UIControlState, state));
}

/*
Possible state combinations.
Disable and highlight can't coexist.
Disable and focus can't coexist.
Assume focus is painted.
Highlight, will show normal image when selected and
selected image when deselected.

Focus==FirstResponder
 Highlight |  Disable  |   Select  |   Focus   | Image Choice
-----------|-----------|-----------|-----------|--------
     0     |     0     |     0     |     0     | Normal
     1     |     0     |     0     |     0     | Select
     0     |     1     |     0     |     0     | DisableNormal
     1     |     1     |     0     |     0     | *impossible*
     0     |     0     |     1     |     0     | Select
     1     |     0     |     1     |     0     | Normal
     0     |     1     |     1     |     0     | DisableSelect
     1     |     1     |     1     |     0     | *impossible*
     0     |     0     |     0     |     1     | Normal
     1     |     0     |     0     |     1     | Select
     0     |     1     |     0     |     1     | *impossible*
     1     |     1     |     0     |     1     | *impossible*
     0     |     0     |     1     |     1     | Select
     1     |     0     |     1     |     1     | Normal
     0     |     1     |     1     |     1     | *impossible*
     1     |     1     |     1     |     1     | *impossible*
*/


// put these into your UIControl adopting class interface ivars
//
// UISwitch is event handling-wise is almost a pure UIControl subclass.
//So use this as a reference to get the behaviour right.
// _reflectedState is private and used by -reflectState
#define UIControlIvars                       \
   UIControlState          _state;           \
   UIControlState          _reflectedState;  \
   UIControlEvents         _eventMask;       \
   id                      _target;          \
   SEL                     _action;          \
   UIControlClickHandler   *_click

// put these into your UIControl adopting class property block

#define UIControlProperties                                   \
   @property( assign) UIControlState          state;          \
   @property( assign) UIControlState          reflectedState; \
   @property( assign) NSUInteger              eventMask;      \
   @property( assign) id                      target;         \
   @property( assign) SEL                     action;         \
   @property( assign) UIControlClickHandler   *click

//
// A UIControl translates event into target/Action or click Events. Though
// it provides states for selection and highlighting. It does not change them
// on events by itself (well highlighting it does currently, but should it ?)
//
// For keyboard and mouse button events, the control will be set to
// setNeedsDisplay
//
PROTOCOLCLASS_INTERFACE( UIControl, UIResponder)

// TODO: put a userinfo into this ?
typedef UIInputEvent   *UIControlClickHandler( id <UIControl> control,
                                               UIInputEvent *event);

UIControlProperties;

- (void) setNeedsDisplay;

@optional


- (BOOL) shouldConsumeMouseEvent:(UIInputEvent *) event;

- (UIInputEvent *) mouseUp:(UIMouseButtonEvent *) event;

// returns fallbackEvent, if there is no target/action 
- (UIInputEvent *) performClickAndTargetActionCallbacks:(UIInputEvent *) event
                                          fallbackEvent:(UIInputEvent *) fallbackEvent;
// this returns nil, if there is no target/action
- (UIInputEvent *) performClickAndTargetActionCallbacks:(UIInputEvent *) event;


// these are convenience for state, don't override these
// overide -state if needed

- (BOOL) isHighlighted;
- (void) setHighlighted:(BOOL) flag;
- (BOOL) isEnabled;
- (void) setEnabled:(BOOL) flag;
- (BOOL) isSelected;
- (void) setSelected:(BOOL) flag;

- (char *) UTF8String;

/* utilities for implementors */
- (void) mulleToggleSelectedState;
- (void) mulleToggleHighlightedState;

// NO means that there has been no state change observed
- (BOOL) reflectState;

- (void) sendActionOn:(UIControlEvents) mask;

- (BOOL) __isUIControl;

PROTOCOLCLASS_END()


