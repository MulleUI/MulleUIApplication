enum
{
   UIControlDebug                   = 0x00000001,
   UIControlDebugVerbose            = 0x00000004,
 
   UIControlDebugEvent              = 0x00000002,
   UIControlDebugEventVerbose       = 0x00002000,
   
   UIControlDebugMouseTrackingEvent = 0x01000000,
   UIControlDebugMouseMotionEvent   = 0x02000000
};



#if ! defined( UI_CONTROL_DEBUG_DISABLED)

@interface NSObject ( UIControl)

- (BOOL) __isUIControl;
- (NSUInteger) debugEnabled;

@end


#define UIControlLog( format, ...)                                          \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debugEnabled] & UIControlDebug)                   \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIControlLogVerbose( format, ...)                                   \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debugEnabled]  & UIControlDebugVerbose)           \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIControlEventLog( event, format, ...)                              \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debugEnabled]  & UIControlDebugEvent)             \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#define UIControlEventLogVerbose( event, format, ...)                       \
do                                                                          \
{                                                                           \
   assert( [(NSObject *) self __isUIControl]);                              \
   if( [(NSObject *) self debugEnabled] & UIControlDebugEventVerbose)       \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking)))     \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)

#define UIControlMouseTrackingEventLog( event, format, ...)                   \
do                                                                            \
{                                                                             \
   assert( [(NSObject *) self __isUIControl]);                                \
   if( [(NSObject *) self debugEnabled]  & UIControlDebugMouseTrackingEvent)  \
      if( [event eventType] == UIEventTypeTracking)                           \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,       \
                                          (char *) format, ## __VA_ARGS__);   \
}                                                                             \
while( 0)

#define UIControlMouseMotionEventLog( event, format, ...)                     \
do                                                                            \
{                                                                             \
   assert( [(NSObject *) self __isUIControl]);                                \
   if( [(NSObject *) self debugEnabled]  & UIControlDebugMouseMotionEvent)    \
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


