//
//  UINullOSWindow.h
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
// This class implements the UIOSWindow protocol but does not create
// any actual OS window or graphics context. It's suitable for:
//
// - Testing event handling and application logic
// - Headless testing environments
// - CI/CD pipelines without displays
//
// For testing with rendering, this can be augmented with a CGContext
// using NVG_NO_DRAWING at the integration layer (MulleUIOS).
//
#import "import.h"

#import "UIWindowTypes.h"


@interface UINullOSWindow : NSObject <UIOSWindow>
{
   struct UIInputState      _inputState;
   id <UIEventReceiver>     _eventsReceiver;
   id <UIEventReceiver>     _windowEventsReceiver;
   NSUInteger               _debuggingFlags;
}

@property( assign) id <UIEventReceiver>                 windowEventsReceiver;
@property( assign) id <UIEventReceiver>                 eventsReceiver;
@property( assign) NSUInteger                           discardEventsMask;
@property( assign) id <UIWindow>                        parentWindow;
@property( readonly, getter=isAntiAliasing) BOOL        antiAliasing;
@property( assign) UIOSWindowEventCallback_t            windowEventsCallback;
@property( assign) UIOSWindowRetainedEventCallback_t    otherRetainedEventsCallback;
@property( assign) UIOSWindowFrameCallback_t            frameCallback;

// Window properties
@property( assign) CGRect                               frame;
@property( assign) NSInteger                            shareIdentifier;
@property( assign) BOOL                                 rateLimiter;
@property( assign) mulle_relativetime_t                 frameRateValue;
@property( assign) CGFloat                              frameRateHzValue;
@property( assign) UIGraphicsBackend                    backend;
@property( assign) mulle_absolutetime_t                 lastSwapTime;
@property( assign) NSUInteger                           swapInterval;
@property( assign) BOOL                                 shouldClose;
@property( assign) void                                 *cursorPtr;
@property( assign) void                                 *windowPtr;

- (instancetype) initWithFrame:(CGRect) frame
               titleUTF8String:(char *) title
                     styleMask:(NSUInteger) styleMask;

@end


@interface UINullOSWindow( Future) <MulleObjCFuture>

- (Class) osGraphicsContextClass;

@end