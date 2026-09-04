//
//  UIOSWindow+DebugPrivate.h
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
// use generic OSWindow for this and SDLOSWindow
enum
{
   UIOSWindowDebug                 = 0x000001,
   UIOSWindowDebugBackend          = 0x000100,
   UIOSWindowDebugVerbose          = 0x001000,

   UIOSWindowDebugSwap             = 0x0400,

   UIOSWindowDebugEvent            = 0x000002,
   UIOSWindowDebugEventVerbose     = 0x002000,

   UIOSWindowDebugMouseMotionEvent = 0x1000000
};



//
// MEMO: In your format strings do NOT use %@. Do use %-#@ for no-color and
//       %#@ for color strings, because those are thread-safe
//
#if ! defined( UI_OS_WINDOW_LOG_DISABLED)

@interface NSObject ( UIOSWindow)

- (BOOL) __isUIOSWindow    MULLE_OBJC_THREADSAFE_METHOD;

@end


#define UIOSWindowLog( format, ...)                                         \
do                                                                          \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebug)                             \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIOSWindowLogVerbose( format, ...)                                  \
do                                                                          \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebugVerbose)                      \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIOSWindowSwapLog( format, ...)                                     \
do                                                                          \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebugSwap)                         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)



#define UIOSWindowEventLog( format, ...)                                    \
do                                                                          \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebugEvent)                        \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIOSWindowEventLogVerbose( format, ...)                             \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebugEventVerbose)                 \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIOSWindowMouseMotionEventLog( format, ...)                         \
do                                                                          \
{                                                                           \
   assert( [self __isUIOSWindow]);                                          \
   if( self->_debuggingFlags & UIOSWindowDebugMouseMotionEvent)             \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#else

#define UIOSWindowLog( format, ...)                  do {} while( 0)
#define UIOSWindowLogVerbose( format, ...)           do {} while( 0)
#define UIOSWindowSwapLog( format, ...)              do {} while( 0)
#define UIOSWindowEventLog( format, ...)             do {} while( 0)
#define UIOSWindowEventLogVerbose( format, ...)      do {} while( 0)
#define UIOSWindowMouseMotionEventLog( format, ...)  do {} while( 0)

#endif


