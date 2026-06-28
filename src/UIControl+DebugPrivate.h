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


