enum
{
   UIApplicationDebug                        = 0x00000001,
   UIApplicationDebugEvent                   = 0x00000002,
   UIApplicationDebugVerbose                 = 0x00001000,
   UIApplicationDebugEventVerbose            = 0x00002000,
   UIApplicationDebugMouseTrackingEvent      = 0x01000000,
   UIApplicationDebugMouseMotionEvent        = 0x02000000

   // memo don't use more than 0x0400000 to not get in conflict with UIWindow
};


@interface NSObject ( UIApplication)

- (BOOL) __isUIApplication;

@end



#if ! defined( UI_WINDOW_DEBUG_DISABLED)

#define UIApplicationLog( format, ...)                                      \
do                                                                          \
{                                                                           \
   assert( [self __isUIApplication]);                                       \
   if( self->_debugEnabled & UIApplicationDebug)                            \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIApplicationLogVerbose( format, ...)                               \
do                                                                          \
{                                                                           \
   assert( [self __isUIApplication]);                                       \
   if( self->_debugEnabled & UIApplicationDebugVerbose)                     \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIApplicationLayoutLog( format, ...)                                \
do                                                                          \
{                                                                           \
   assert( [self __isUIApplication]);                                       \
   if( self->_debugEnabled & UIApplicationDebugLayout)                      \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)


#define UIApplicationEventLog( event, format, ...)                                   \
do                                                                                   \
{                                                                                    \
   assert( [self __isUIApplication]);                                                \
   if( self->_debugEnabled & UIApplicationDebugEvent)                                \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking))) \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,              \
                                          (char *) format, ## __VA_ARGS__);          \
}                                                                                    \
while( 0)


#define UIApplicationEventLogVerbose( event, format, ...)                            \
do                                                                                   \
{                                                                                    \
   assert( [self __isUIApplication]);                                                \
   if( self->_debugEnabled & UIApplicationDebugEventVerbose)                         \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking))) \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,              \
                                          (char *) format, ## __VA_ARGS__);          \
}                                                                                    \
while( 0)

#define UIApplicationMouseTrackingEventLog( event, format, ...)                      \
do                                                                                   \
{                                                                                    \
   assert( [self __isUIApplication]);                                                \
   if( self->_debugEnabled & UIApplicationDebugMouseTrackingEvent)                   \
      if( ! event || [event eventType] == UIEventTypeTracking)                       \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,              \
                                          (char *) format, ## __VA_ARGS__);          \
}                                                                                    \
while( 0)

#define UIApplicationMouseMotionEventLog( event, format, ...)               \
do                                                                          \
{                                                                           \
   assert( [self __isUIApplication]);                                       \
   if( self->_debugEnabled & UIApplicationDebugMouseMotionEvent)            \
      if( ! event || [event eventType] == UIEventTypeMotion)                \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,     \
                                          (char *) format, ## __VA_ARGS__); \
}                                                                           \
while( 0)


#else

#define UIApplicationLog( format, ...)                            do {} while( 0)
#define UIApplicationLogVerbose( format, ...)                     do {} while( 0)
#define UIApplicationEventLog( event, format, ...)                do {} while( 0)
#define UIApplicationEventLogVerbose( event, format, ...)         do {} while( 0)
#define UIApplicationMouseMotionEventLog( event, format, ...)     do {} while( 0)
#define UIApplicationMouseTrackingEventLog( event, format, ...)   do {} while( 0)

#endif


