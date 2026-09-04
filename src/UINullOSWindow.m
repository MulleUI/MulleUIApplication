//
//  UINullOSWindow.m
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
// UINullOSWindow - A minimal UIOSWindow implementation for testing
//
#import "UINullOSWindow.h"
#import "UIOSWindow+DebugPrivate.h"


@implementation UINullOSWindow

- (BOOL) __isUIOSWindow
{
   return( YES);
}


+ (NSUInteger) effectiveWindowStyleMask:(NSUInteger) styleMask
                          graphicsHints:(UIOSWindowGraphicsHints) hints
{
   // null OS window draws nothing; honor the requested mask unchanged
   return( styleMask);
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
      // no OS graphics context is created (see -graphicsContext returning nil),
      // so there is no current GL/Metal context. Reporting None makes CGContext
      // skip drawing-backend creation and skip glGetError/glFinish, which would
      // otherwise crash on a NULL context (notably Apple libGL).
      _backend      = UIGraphicsBackendNone;
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
                 graphicsHints:(UIOSWindowGraphicsHints) hints
                 sharingWindow:(id <UIOSWindow>) sharingWindow
{
   MULLE_C_UNUSED( title);
   MULLE_C_UNUSED( hints);
   MULLE_C_UNUSED( sharingWindow);
   char   *s;

   if( self = [super init])
   {
      _frame = frame;
      _antiAliasing = (styleMask & UIWindowStyleAntiAlias) != 0;
      _rateLimiter  = YES;
      _frameRateValue   = 1.0 / 60.0;
      _frameRateHzValue = 60.0;
      // no OS graphics context is created, so there is no current GL/Metal
      // context; None makes CGContext skip drawing-backend creation and the
      // glGetError/glFinish calls that would crash on a NULL context.
      _backend = UIGraphicsBackendNone;
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
                  graphicsHints:(UIOSWindowGraphicsHints) { 0 }
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


- (NSUInteger) os_pressedKeys:(NSUInteger *) keys
                        count:(NSUInteger) count
{
   return( 0);
}


- (NSUInteger) pressedKeys:(NSUInteger *) keys
                     count:(NSUInteger) count
{
   return( 0);
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


- (void) os_setCursorCaptured:(BOOL) captured
{
}


- (void) os_setCursor:(void *) cursor
{
   _cursorPtr = cursor;
}


- (void *) os_createCursorWithBitmap:(struct CGBitmap) bitmap
                             hotSpot:(struct CGPixelPoint) hotSpot
{
   MULLE_C_UNUSED( bitmap);
   MULLE_C_UNUSED( hotSpot);
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
