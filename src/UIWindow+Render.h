//
// Copyright (c) 2021 Nat!, Mulle kybernetiK
//

#import "UIWindow.h"


@interface UIWindow( Render)

- (void) renderLoop;
- (BOOL) renderUpToNumberOfFrames:(NSUInteger) maxFrames;
- (void) renderFrame:(struct CGFrameInfo *) info;
- (BOOL) renderFrameWaitForNeedsDisplay;

- (void) addToDelegateViews:(UIView *) view;
- (void) removeFromDelegateViews:(UIView *) view;

- (void) getFrameInfo:(struct CGFrameInfo *) info;

- (CGContext *) activateWindowContext;
- (void) deactivateWindowContext:(CGContext *) context;
- (CGContext *) activateRenderContext;
- (void) deactivateRenderContext:(CGContext *) context;

- (void) swapBuffers;

// this will activate the window context!
- (struct CGFramebufferBitmap)
   lastRenderedFramebufferBitmapType:(enum CGFramebufferBitmapType) type
                            inFlight:(BOOL) inFlight
                           allocator:(struct mulle_allocator *) allocator;
@end

