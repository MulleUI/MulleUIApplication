//
//  UIKeyboardState.h
//  MulleUIApplication
//
//  Higher-level UIKeyStates helpers that depend on UIEvent / UIOSWindow.
//  The core struct and data functions live in MulleUIBase.h.
//
#ifndef UI_KEYBOARD_STATE_H
#define UI_KEYBOARD_STATE_H

#import "import.h"

#import "UIEvent.h"
#import "UIWindowTypes.h"


static inline void
   UIKeyStatesHandleEvent( struct UIKeyStates *state,
                           UIKeyboardEvent *event)
{
   NSUInteger   key;

   key = [event key];
   switch( [event action])
   {
   case UIEventButtonActionDown   :
   case UIEventButtonActionRepeat :
      UIKeyStatesHandleKeyDown( state, key);
      break;

   case UIEventButtonActionUp :
      UIKeyStatesHandleKeyUp( state, key);
      break;
   }
}


// call this on focus regain to resync with actual hardware state
static inline void
   UIKeyStatesResync( struct UIKeyStates *state,
                      id <UIOSWindow> osWindow)
{
   state->_count = [osWindow os_pressedKeys:state->_keys
                                      count:UIKeyStatesMaxKeys];
}


#endif
