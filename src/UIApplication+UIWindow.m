//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
#import "UIApplication+UIWindow.h"

#import "import-private.h"

#import "UIWindow.h"


@implementation UIApplication ( UIWindow)

- (void) runWindowForDrawCallback:(CALayerDrawCallback_t) callback
                       canvasSize:(CGSize) canvasSize
                       windowSize:(CGSize) windowSize
                  titleUTF8String:(char *) title
                      frameRateHz:(CGFloat) hz
{
   CALayer    *layer;
   UIWindow   *window;

   if( windowSize.width == 0.0)
      windowSize = canvasSize;

   layer = [CALayer layerWithFrame:CGRectMake( 0, 0, windowSize.width, windowSize.height)];
   [layer setBounds:CGRectMake( 0, 0, canvasSize.width, canvasSize.height)];
   [layer setCanvas:CGRectMake( 0, 0, canvasSize.width, canvasSize.height)];
   [layer setDrawCallback:callback];
   window = [UIWindow windowWithLayer:layer
                      titleUTF8String:title];
   [window setFrameRateHz:hz];
   [self addWindow:window];
   [window renderLoop];
}


+ (void) runWindowForDrawCallback:(CALayerDrawCallback_t) callback
                       canvasSize:(CGSize) canvasSize
                       windowSize:(CGSize) windowSize
                  titleUTF8String:(char *) title
                      frameRateHz:(CGFloat) hz
{
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   @autoreleasepool
   {
      [app runWindowForDrawCallback:callback
                         canvasSize:canvasSize
                         windowSize:windowSize
                    titleUTF8String:title
                        frameRateHz:hz];
   }
   [app terminate];

@end
