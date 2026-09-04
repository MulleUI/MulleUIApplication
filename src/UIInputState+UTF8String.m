//
//  UIInputState+UTF8String.m
//  MulleUIApplication
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
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
#import "UIInputState+UTF8String.h"

#import "import-private.h"

#import "UIEvent.h"


static void   mulle_buffer_add_converted_bits( struct mulle_buffer *buffer,
                                               NSUInteger bits,
                                               char *(*conversion)( NSUInteger bit))
{
   NSUInteger   bit;
   char         *hein;
   char         *text;

   bit  = 0x1;
   hein = "";

   while( bits)
   {
      if( bits & bit)
      {
         text = (*conversion)( bit);
         if( ! text)
            hein = " ???";
         else
         {
            mulle_buffer_add_char( buffer, ' ');
            mulle_buffer_add_string( buffer, text);
         }
      }
      bits &= ~bit;
      bit <<= 1;
   }
   mulle_buffer_add_string( buffer, hein);
}


char   *UIInputStateUTF8String( struct UIInputState *state)
{
   auto char   *s;

   if( ! state)
      return( "NULL");

   mulle_buffer_do_autoreleased_string( buffer, NULL, s)
   {
      mulle_buffer_sprintf( buffer, "%.2f %.2f",
                                    state->locationInWindow.x,
                                    state->locationInWindow.y);

      // add buttons
      mulle_buffer_add_converted_bits( buffer,
                                       state->buttonStates,
                                       _UIEventMouseButtonUTF8String);

      // add modifiers
      mulle_buffer_add_converted_bits( buffer,
                                       state->keyModifiers,
                                       _UIEventKeyModifierUTF8String);
   }

   return( s);
}

