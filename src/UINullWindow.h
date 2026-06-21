//
// UINullWindow - A minimal UIWindow implementation for testing
//
// Wraps a UINullOSWindow and forwards UIEventReceiver protocol methods to it.
// Suitable for testing event dispatch without actual OS windows or graphics.
//
#import "import.h"

#import "UIWindowTypes.h"


@class UINullOSWindow;


@interface UINullWindow : NSObject < UIWindow, UIEventReceiver>
{
   UINullOSWindow           *_OSWindow;
   id <UIGraphicsContext>   _renderGraphicsContext;
}

+ (Class) osGraphicsContextClass;

@property( assign) UIWindowDisplayBits  (*rawFrameCallback)( UINullWindow *window,
                                                         id <UIGraphicsContext> context,
                                                         struct CGFrameInfo *frameInfo,
                                                         UIWindowDisplayBits displayBits);

@property( assign, readonly) id <UIOSWindow>         OSWindow;
@property( assign, readonly) id <UIGraphicsContext>  renderGraphicsContext;

- (instancetype) initWithOSWindow:(UINullOSWindow *) osWindow;
- (instancetype) initWithOSWindow:(UINullOSWindow *) osWindow
                         styleMask:(NSUInteger) styleMask;

@end
