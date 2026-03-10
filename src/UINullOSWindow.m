//
// UINullOSWindow - A minimal UIOSWindow implementation for testing
//
#import "UINullOSWindow.h"
#import "UIOSWindow+DebugPrivate.h"


@implementation UINullOSWindow

- (BOOL) __isUIOSWindow
{
   return( YES);
}


- (instancetype) init
{
   char   *s;

   if( self = [super init])
   {
      _antiAliasing = NO;
      _rateLimiter  = YES;
      _frameRateValue   = 1.0 / 60.0;
      _frameRateHzValue = 60.0;
      _backend      = UIGraphicsBackendDefault;
      _shareIdentifier = 1;
      _swapInterval = 1;
      _shouldClose  = NO;
      memset( &_inputState, 0, sizeof( _inputState));

      s = getenv( "UIOSWindowDebuggingFlags");
      if( s)
         _debuggingFlags = strtol( s, NULL, 0);
   }
   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
                 graphicsHints:(NSUInteger) hints
                 sharingWindow:(id <UIOSWindow>) sharingWindow
{
   char   *s;

   if( self = [super init])
   {
      _frame = frame;
      _antiAliasing = (styleMask & UIWindowStyleAntiAlias) != 0;
      _rateLimiter  = YES;
      _frameRateValue   = 1.0 / 60.0;
      _frameRateHzValue = 60.0;
      _backend = UIGraphicsBackendDefault;
      _shareIdentifier = 1;
      _swapInterval = 1;
      _shouldClose = NO;
      memset( &_inputState, 0, sizeof( _inputState));

      s = getenv( "UIOSWindowDebuggingFlags");
      if( s)
         _debuggingFlags = strtol( s, NULL, 0);
   }
   return( self);
}

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask
{
   return( [self initWithFrame:frame
                titleUTF8String:title
                      styleMask:styleMask
                  graphicsHints:0
                  sharingWindow:nil]);
}


#pragma mark - Receivers

- (void) setEventsReceiver:(id <UIEventReceiver>) receiver
{
   _eventsReceiver = receiver;
}

- (id <UIEventReceiver>) eventsReceiver
{
   return( _eventsReceiver);
}

- (void) setWindowEventsReceiver:(id <UIEventReceiver>) receiver
{
   _windowEventsReceiver = receiver;
}

- (id <UIEventReceiver>) windowEventsReceiver
{
   return( _windowEventsReceiver);
}

#pragma mark - UIOSWindow Protocol (Main Thread Methods)

- (void) os_initEvents
{
}


- (void) os_finalizeEvents
{
}


- (void) os_pollInputState:(struct UIInputState *) state
{
   memset( state, 0, sizeof( struct UIInputState));
}


- (void) os_setTitleUTF8String:(char *) s
{
}


- (void) os_show
{
}


- (void) os_hide
{
}


- (BOOL) os_windowShouldClose
{
   return( _shouldClose);
}


- (void) os_requestClose
{
   _shouldClose = YES;
}


- (void) os_requestRefresh
{
}


- (void) os_swapBuffers
{
   _lastSwapTime = mulle_absolutetime_now();
   UIOSWindowSwapLog( "swap");
}


- (void) os_waitEvents
{
}


- (void) os_pollEvents
{
}


- (CGPixelSize) os_framebufferSize
{
   return( CGPixelSizeMake( _frame.size.width, _frame.size.height));
}


- (void) os_setCursor:(void *) cursor
{
   _cursorPtr = cursor;
}


- (void *) os_createCursorWithBitmap:(struct CGBitmap) bitmap
                             hotSpot:(struct CGPixelPoint) hotSpot
{
   return( NULL);
}


- (void) os_destroyCursor:(void *) cursor
{
}


- (void *) os_window
{
   return( _windowPtr);
}


#pragma mark - Graphics Context

- (id <UIGraphicsContext>) graphicsContext
{
   return( nil);  // No graphics by default, can be set externally
}


- (void) os_activateGraphicsContext
{
}


- (void) os_deactivateGraphicsContext
{
}


#pragma mark - Frame Rate

- (void) setFrameRateLimiter:(BOOL) flag
{
   _rateLimiter = flag;
}


- (BOOL) frameRateLimiter
{
   return( _rateLimiter);
}


- (void) setFrameRate:(mulle_relativetime_t) frameRate
{
   _frameRateValue = frameRate;
   _frameRateHzValue = frameRate > 0 ? 1.0 / frameRate : 0;
}


- (mulle_relativetime_t) frameRate
{
   return( _frameRateValue);
}


- (void) setFrameRateHz:(CGFloat) frameRateHz
{
   _frameRateHzValue = frameRateHz;
   _frameRateValue = frameRateHz > 0 ? 1.0 / frameRateHz : 0;
}


- (CGFloat) frameRateHz
{
   return( _frameRateHzValue);
}


#pragma mark - Share ID

- (NSInteger) shareID
{
   return( _shareIdentifier);
}


#pragma mark - Active Thread

- (NSThread *) activeThread
{
   return( [NSThread currentThread]);
}


#pragma mark - Timestamp

- (mulle_absolutetime_t) lastSwapBuffersTimestamp
{
   return( _lastSwapTime);
}


// UIOSWindow protocol stubs
- (id <UIOSWindow>) OSWindow
{
   return( (id <UIOSWindow>) self);
}

- (id <UIScreen>) screenOrPrimaryScreen:(BOOL) flag
{
   return( nil);
}

- (id <UIScreen>) screen
{
   return( nil);
}

- (id <UIGamepad>) gamepadAtIndex:(NSUInteger) index
{
   return( nil);
}

- (void) getOSWindowInfo:(struct UIOSWindowInfo *) info
{
   struct CGWindowInfo   *base;

   if( ! info)
      return;

   memset( info, 0, sizeof( *info));

   base                 = &info->base;
   base->frame          = _frame;
   base->framebufferSize= [self os_framebufferSize];
   base->UIScale        = CGVectorMake( 1.0, 1.0);
   base->pixelRatio     = 1.0;

   info->frameRate        = _frameRateValue;
   info->refreshRate      = _frameRateValue;
   info->frameRateLimiter = _rateLimiter;
}

- (void) os_setSwapInterval:(NSUInteger) value
{
   _swapInterval = value;
}

- (BOOL) os_tryActivateGraphicsContext
{
   return( YES);
}

- (CGPoint) os_windowPosition
{
   return( _frame.origin);
}

- (void) os_setWindowPosition:(CGPoint) position
{
   _frame.origin = position;
}

- (CGSize) os_windowSize
{
   return( _frame.size);
}

- (void) os_setWindowSize:(CGSize) size
{
   _frame.size = size;
}

- (CGRect) os_windowFrame
{
   return( _frame);
}

- (void) os_setWindowFrame:(CGRect) rect
{
   _frame = rect;
}

@end
