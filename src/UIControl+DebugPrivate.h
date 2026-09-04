//
//  UIControl+DebugPrivate.h
//  MulleUIApplication
//
//  Copyright (c) 2024 Nat! - Mulle kybernetiK.
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
enum
{
   UIControlDebug                   = 0x00000001,
   UIControlDebugVerbose            = 0x00000004,
 
   UIControlDebugEvent              = 0x00000002,
   UIControlDebugEventVerbose       = 0x00002000,
   
   UIControlDebugMouseTrackingEvent = 0x01000000,
   UIControlDebugMouseMotionEvent   = 0x02000000
};



#if ! defined( UI_CONTROL_LOG_DISABLED)

@interface NSObject ( UIControl)

- (BOOL) __isUIControl           MULLE_OBJC_THREADSAFE_METHOD;
- (NSUInteger) debuggingFlags    MULLE_OBJC_THREADSAFE_METHOD;

@end


//
// MEMO: In your format strings do NOT use %@. Do use %-#@ for no-color and
//       %#@ for color strings, because those are thread-safe
//
#define UIControlLog( format, ...)                                          \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debuggingFlags] & UIControlDebug)                 \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIControlLogVerbose( format, ...)                                   \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debuggingFlags]  & UIControlDebugVerbose)         \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIControlEventLog( event, format, ...)                                           \
do                                                                                       \
{                                                                                        \
   assert( [(NSObject *) self __isUIControl]);                                           \
   if( [(NSObject *) self debuggingFlags]  & UIControlDebugEvent)                        \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,                  \
                                          (char *) format, ## __VA_ARGS__);              \
}                                                                                        \
while( 0)


#define UIControlEventLogVerbose( event, format, ...)                                    \
do                                                                                       \
{                                                                                        \
   assert( [(NSObject *) self __isUIControl]);                                           \
   if( [(NSObject *) self debuggingFlags] & UIControlDebugEventVerbose)                  \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,                  \
                                          (char *) format, ## __VA_ARGS__);              \
}                                                                                        \
while( 0)

#define UIControlMouseTrackingEventLog( event, format, ...)                    \
do                                                                             \
{                                                                              \
   assert( [(NSObject *) self __isUIControl]);                                 \
   if( [(NSObject *) self debuggingFlags]  & UIControlDebugMouseTrackingEvent) \
      if( [event eventType] == UIEventTypeTracking)                            \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                          (char *) format, ## __VA_ARGS__);    \
}                                                                              \
while( 0)

#define UIControlMouseMotionEventLog( event, format, ...)                     \
do                                                                            \
{                                                                             \
   assert( [(NSObject *) self __isUIControl]);                                \
   if( [(NSObject *) self debuggingFlags]  & UIControlDebugMouseMotionEvent)  \
      if( [event eventType] == UIEventTypeMotion)                             \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,       \
                                          (char *) format, ## __VA_ARGS__);   \
}                                                                             \
while( 0)   

#else

#define UIControlLog( format, ...)                           do {} while( 0)
#define UIControlLogVerbose( format, ...)                    do {} while( 0)
#define UIControlEventLog( event, format, ...)               do {} while( 0)
#define UIControlEventLogVerbose( event, format, ...)        do {} while( 0)
#define UIControlMouseTrackingEventLog( event, format, ...)  do {} while( 0)
#define UIControlMouseMotionEventLog( event, format, ...)    do {} while( 0)

#endif


