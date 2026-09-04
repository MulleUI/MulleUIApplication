//
//  UIKeyboardState.h
//  MulleUIApplication
//
//  Copyright (c) 2026 Nat! - Mulle kybernetiK.
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
