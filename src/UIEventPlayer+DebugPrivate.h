enum
{
   UIEventPlayerDebug        = 0x00000001,
   UIEventPlayerDebugEvent   = 0x00000002,
   UIEventPlayerDebugVerbose = 0x00001000
};


//
// MEMO: In your format strings do NOT use %@. Do use %-#@ for no-color and
//       %#@ for color strings, because those are thread-safe
//
#if ! defined( UI_EVENT_PLAYER_LOG_DISABLED)

#define UIEventPlayerLog( format, ...)                                      \
do                                                                          \
{                                                                           \
   if( self->_debuggingFlags & UIEventPlayerDebug)                          \
      mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,        \
                                       (char *) format, ## __VA_ARGS__);    \
}                                                                           \
while( 0)

#define UIEventPlayerEventLog( event, format, ...)                                   \
do                                                                                   \
{                                                                                    \
   if( self->_debuggingFlags & UIEventPlayerDebugEvent)                              \
      if( ! event || ([event eventType] & ~(UIEventTypeMotion|UIEventTypeTracking))) \
         mulleui_log_object_method( self, (char *) __PRETTY_FUNCTION__,              \
                                          (char *) format, ## __VA_ARGS__);          \
}                                                                                    \
while( 0)

#else

#define UIEventPlayerLog( format, ...)                do {} while( 0)
#define UIEventPlayerEventLog( event, format, ...)    do {} while( 0)

#endif
