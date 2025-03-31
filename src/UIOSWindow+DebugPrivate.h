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


