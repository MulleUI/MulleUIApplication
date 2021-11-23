//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//
// prefer a local UIApplication over one in import.h
#ifdef __has_include
# if __has_include( "UIApplication.h")
#  import "UIApplication.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@class UIView;
@class CALayer;

@interface UIApplication( UIWindow)

//
// This method  creates a window to display what "callback" draws and runs
// the window until it is closed.
//
// The canvasSize is the unscaled size of your drawing, let say
// 320x200. If the windowSize is left to zero, then the window will
// be this size too. Otherwise the drawing will be scaled to fit
// the windowSize
//
- (void) runWindowForDrawCallback:(CALayerDrawCallback_t) callback
                       canvasSize:(CGSize) canvasSize
                       windowSize:(CGSize) windowSize
                  titleUTF8String:(char *) title
                      frameRateHz:(CGFloat) hz;

// even more convenient...
+ (void) runWindowForDrawCallback:(CALayerDrawCallback_t) callback
                       canvasSize:(CGSize) canvasSize
                       windowSize:(CGSize) windowSize
                  titleUTF8String:(char *) title
                      frameRateHz:(CGFloat) hz;
@end
