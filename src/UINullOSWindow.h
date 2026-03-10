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
